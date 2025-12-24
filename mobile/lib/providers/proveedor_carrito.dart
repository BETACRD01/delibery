// lib/providers/proveedor_carrito.dart

import 'package:flutter/material.dart';
import '../models/producto_model.dart';
import '../models/promocion_model.dart';
import '../services/carrito/carrito_service.dart';
import '../apis/helpers/api_exception.dart';

/// Item del carrito
class ItemCarrito {
  final String id;
  final ProductoModel? producto;
  final PromocionModel? promocion;
  final List<ProductoModel>? productosIncluidos;
  int cantidad;
  final double precioUnitario;

  ItemCarrito({
    required this.id,
    this.producto,
    this.promocion,
    this.productosIncluidos,
    required this.cantidad,
    required this.precioUnitario,
  });

  bool get esPromocion => promocion != null;
  String get nombre => esPromocion ? promocion!.titulo : producto!.nombre;
  String? get imagenUrl => esPromocion ? promocion!.imagenUrl : producto!.imagenUrl;

  double get subtotal => precioUnitario * cantidad;

  factory ItemCarrito.fromJson(Map<String, dynamic> json) {
    return ItemCarrito(
      id: json['id'].toString(),
      producto: ProductoModel(
        id: json['producto_id'].toString(),
        nombre: json['producto_nombre'] ?? '',
        descripcion: '',
        precio: double.parse(json['precio_unitario'].toString()),
        imagenUrl: json['producto_imagen'],
        disponible: json['producto_disponible'] ?? true,
        categoriaId: '',
        rating: 0,
        totalResenas: 0,
        proveedorLatitud: json['proveedor_latitud'] != null ? double.tryParse(json['proveedor_latitud'].toString()) : null,
        proveedorLongitud: json['proveedor_longitud'] != null ? double.tryParse(json['proveedor_longitud'].toString()) : null,
      ),
      cantidad: json['cantidad'] ?? 1,
      precioUnitario: double.parse(json['precio_unitario'].toString()),
    );
  }
}

/// Provider del carrito de compras con integración API
class ProveedorCarrito extends ChangeNotifier {
  // ════════════════════════════════════════════════════════════════
  // SERVICIOS
  // ════════════════════════════════════════════════════════════════
  final _carritoService = CarritoService();

  // ════════════════════════════════════════════════════════════════
  // ESTADO
  // ════════════════════════════════════════════════════════════════
  List<ItemCarrito> _items = [];
  List<ItemCarrito> _promocionesLocales = []; // Promociones solo en memoria
  bool _loading = false;
  String? _error;

  // ════════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════════

  List<ItemCarrito> get items {
    // Combinar productos del backend con promociones locales
    return [..._items, ..._promocionesLocales];
  }
  bool get loading => _loading;
  String? get error => _error;

  /// Obtiene la cantidad total de productos en el carrito
  int get cantidadTotal {
    final itemsCount = _items.fold(0, (sum, item) => sum + item.cantidad);
    final promosCount = _promocionesLocales.fold(0, (sum, item) => sum + item.cantidad);
    return itemsCount + promosCount;
  }

  /// Calcula el total del carrito
  double get total {
    final itemsTotal = _items.fold(0.0, (sum, item) => sum + item.subtotal);
    final promosTotal = _promocionesLocales.fold(0.0, (sum, item) => sum + item.subtotal);
    return itemsTotal + promosTotal;
  }

  /// Verifica si el carrito está vacío
  bool get estaVacio => _items.isEmpty && _promocionesLocales.isEmpty;

  /// Obtiene la cantidad de items únicos
  int get cantidadItems => _items.length;

  void limpiar() {
    _items = [];
    _promocionesLocales = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS - CARGA DE DATOS
  // ════════════════════════════════════════════════════════════════

  void _setLoadingState({bool loading = false, String? error}) {
    _loading = loading;
    _error = error;
    notifyListeners();
  }

  /// Carga el carrito desde la API
  Future<void> cargarCarrito() async {
    _setLoadingState(loading: true);

    try {
      final response = await _carritoService.obtenerCarrito();
      
      _items = (response['items'] as List<dynamic>)
          .map((json) => ItemCarrito.fromJson(json))
          .toList();
      
      _setLoadingState(error: null);
      debugPrint('Carrito cargado: ${_items.length} items');
    } on ApiException catch (e) {
      _setLoadingState(error: e.message);
      debugPrint('Error al cargar carrito: ${e.message}');
    } catch (e) {
      _setLoadingState(error: 'Error inesperado al cargar carrito');
      debugPrint('Error inesperado: $e');
    }
  }

  /// Agrega un producto al carrito
  Future<bool> agregarProducto(
    ProductoModel producto, {
    int cantidad = 1,
  }) async {
    if (!producto.disponible) {
      _setLoadingState(error: 'Producto no disponible');
      return false;
    }

    _setLoadingState(loading: true);

    try {
      final response = await _carritoService.agregarAlCarrito(
        productoId: producto.id,
        cantidad: cantidad,
      );

      // Actualizar items desde la respuesta
      _items = (response['items'] as List<dynamic>)
          .map((json) => ItemCarrito.fromJson(json))
          .toList();

      _setLoadingState(error: null);
      debugPrint('Producto agregado: ${producto.nombre}');
      return true;
    } on ApiException catch (e) {
      _setLoadingState(error: e.message);
      debugPrint('Error al agregar producto: ${e.message}');
      return false;
    } catch (e) {
      _setLoadingState(error: 'Error al agregar producto');
      debugPrint('Error inesperado: $e');
      return false;
    }
  }

  /// Incrementa la cantidad de un producto
  Future<bool> incrementarCantidad(String itemId) async {
    // Verificar si es una promoción local
    final indexPromo = _promocionesLocales.indexWhere((i) => i.id == itemId);
    if (indexPromo != -1) {
      _promocionesLocales[indexPromo].cantidad++;
      notifyListeners();
      return true;
    }

    // Si no, es un producto del backend
    final item = _items.firstWhere((i) => i.id == itemId);
    return await actualizarCantidad(itemId, item.cantidad + 1);
  }

  /// Decrementa la cantidad de un producto
  Future<bool> decrementarCantidad(String itemId) async {
    // Verificar si es una promoción local
    final indexPromo = _promocionesLocales.indexWhere((i) => i.id == itemId);
    if (indexPromo != -1) {
      // No permitir decrementar si ya está en 1
      if (_promocionesLocales[indexPromo].cantidad <= 1) {
        return true; // Retornar true pero no hacer nada
      }
      _promocionesLocales[indexPromo].cantidad--;
      notifyListeners();
      return true;
    }

    // Si no, es un producto del backend
    final item = _items.firstWhere((i) => i.id == itemId);

    // No permitir decrementar si ya está en 1
    if (item.cantidad <= 1) {
      return true; // Retornar true pero no hacer nada
    }

    return await actualizarCantidad(itemId, item.cantidad - 1);
  }

  /// Actualiza la cantidad de un producto
  Future<bool> actualizarCantidad(String itemId, int nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      return await removerProducto(itemId);
    }

    _setLoadingState(loading: true);

    try {
      final response = await _carritoService.actualizarCantidad(
        itemId: itemId,
        cantidad: nuevaCantidad,
      );

      // Actualizar items desde la respuesta
      _items = (response['items'] as List<dynamic>)
          .map((json) => ItemCarrito.fromJson(json))
          .toList();

      _setLoadingState(error: null);
      debugPrint('Cantidad actualizada');
      return true;
    } on ApiException catch (e) {
      _setLoadingState(error: e.message);
      debugPrint('Error al actualizar cantidad: ${e.message}');
      return false;
    } catch (e) {
      _setLoadingState(error: 'Error al actualizar cantidad');
      return false;
    }
  }

  /// Remueve un producto del carrito
  Future<bool> removerProducto(String itemId) async {
    // Verificar si es una promoción local
    final indexPromo = _promocionesLocales.indexWhere((i) => i.id == itemId);
    if (indexPromo != -1) {
      _promocionesLocales.removeAt(indexPromo);
      notifyListeners();
      debugPrint('Promoción removida localmente');
      return true;
    }

    // Si no, es un producto del backend
    _setLoadingState(loading: true);

    try {
      final response = await _carritoService.removerDelCarrito(itemId);

      // Actualizar items desde la respuesta
      _items = (response['items'] as List<dynamic>)
          .map((json) => ItemCarrito.fromJson(json))
          .toList();

      _setLoadingState(error: null);
      debugPrint('Producto removido');
      return true;
    } on ApiException catch (e) {
      _setLoadingState(error: e.message);
      debugPrint('Error al remover producto: ${e.message}');
      return false;
    } catch (e) {
      _setLoadingState(error: 'Error al remover producto');
      return false;
    }
  }

  /// Limpia todos los items del carrito
  Future<bool> limpiarCarrito() async {
    _setLoadingState(loading: true);

    try {
      await _carritoService.limpiarCarrito();

      _items = [];
      _promocionesLocales = []; // También limpiar promociones locales
      _setLoadingState(error: null);
      debugPrint('Carrito limpiado');
      return true;
    } on ApiException catch (e) {
      _setLoadingState(error: e.message);
      debugPrint('Error al limpiar carrito: ${e.message}');
      return false;
    } catch (e) {
      _setLoadingState(error: 'Error al limpiar carrito');
      return false;
    }
  }

  /// Realiza el checkout
  Future<Map<String, dynamic>?> checkout({
    required String direccionEntrega,
    double? latitudDestino,
    double? longitudDestino,
    String metodoPago = 'efectivo',
    Map<String, dynamic>? datosEnvio,
    String? direccionId,
    String? instruccionesEntrega,
  }) async {
    if (_items.isEmpty && _promocionesLocales.isEmpty) {
      _setLoadingState(error: 'El carrito está vacío');
      return null;
    }

    _setLoadingState(loading: true);

    try {
      final response = await _carritoService.checkout(
        direccionEntrega: direccionEntrega,
        latitudDestino: latitudDestino,
        longitudDestino: longitudDestino,
        metodoPago: metodoPago,
        datosEnvio: datosEnvio,
        direccionId: direccionId,
        instruccionesEntrega: instruccionesEntrega,
      );

      // Limpiar carrito local después del checkout exitoso
      _items = [];
      _promocionesLocales = [];
      _setLoadingState(error: null);
      debugPrint('Checkout exitoso');
      return response;
    } on ApiException catch (e) {
      _setLoadingState(error: e.message);
      debugPrint('Error en checkout: ${e.message}');
      return null;
    } catch (e) {
      _setLoadingState(error: 'Error al procesar checkout');
      debugPrint('Error inesperado: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS DE UTILIDAD
  // ════════════════════════════════════════════════════════════════

  /// Limpia el error actual
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  /// Agrega una promoción completa al carrito
  Future<bool> agregarPromocion(
    PromocionModel promocion,
    List<ProductoModel> productosIncluidos, {
    int cantidad = 1,
  }) async {
    // Calcular el precio total de la promoción
    final precioTotal = productosIncluidos.fold<double>(
      0,
      (sum, p) => sum + p.precio,
    );

    // Crear un item temporal de promoción
    final nuevoItem = ItemCarrito(
      id: 'promo_${promocion.id}_${DateTime.now().millisecondsSinceEpoch}',
      promocion: promocion,
      productosIncluidos: productosIncluidos,
      cantidad: cantidad,
      precioUnitario: precioTotal,
    );

    // Agregar a promociones locales (no al backend)
    _promocionesLocales.add(nuevoItem);
    notifyListeners();

    debugPrint('Promoción agregada localmente: ${promocion.titulo} con ${productosIncluidos.length} productos');
    return true;
  }

  /// Verifica si un producto está en el carrito
  bool tieneProducto(String productoId) {
    return _items.any((item) => item.producto?.id == productoId);
  }

  /// Obtiene la cantidad de un producto en el carrito
  int cantidadProducto(String productoId) {
    try {
      final item = _items.firstWhere((i) => i.producto?.id == productoId);
      return item.cantidad;
    } catch (e) {
      return 0;
    }
  }

  /// Formatea el total como moneda
  String get totalFormateado {
    return '\$${total.toStringAsFixed(2)}';
  }
}
