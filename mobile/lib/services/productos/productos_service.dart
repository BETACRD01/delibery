// lib/services/productos/productos_service.dart

import 'dart:convert';
import 'dart:io';

import '../../apis/productos/categorias_api.dart';
import '../../apis/productos/productos_api.dart';
import '../../apis/productos/promociones_api.dart';
import '../../models/categoria_model.dart';
import '../../models/producto_model.dart';
import '../../models/promocion_model.dart';

/// Servicio para gestionar productos, categorías y promociones
/// Delegación: Usa ProductosApi, CategoriasApi y PromocionesApi para llamadas HTTP
class ProductosService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------
  static final ProductosService _instance = ProductosService._internal();
  factory ProductosService() => _instance;
  ProductosService._internal();

  // ---------------------------------------------------------------------------
  // APIS
  // ---------------------------------------------------------------------------

  final _productosApi = ProductosApi();
  final _categoriasApi = CategoriasApi();
  final _promocionesApi = PromocionesApi();

  // ---------------------------------------------------------------------------
  // CATEGORÍAS
  // ---------------------------------------------------------------------------

  Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final response = await _categoriasApi.getCategorias();
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => CategoriaModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<CategoriaModel> obtenerCategoria(String categoriaId) async {
    try {
      final response = await _categoriasApi.getCategoria(categoriaId);
      return CategoriaModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PRODUCTOS (Lógica Principal)
  // ---------------------------------------------------------------------------

  /// Obtiene todos los productos disponibles con filtros
  Future<List<ProductoModel>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
  }) async {
    try {
      final response = await _productosApi.getProductos(
        categoriaId: categoriaId,
        proveedorId: proveedorId,
        busqueda: busqueda,
        soloOfertas: soloOfertas,
      );
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // MÉTODOS DE CONVENIENCIA
  // ---------------------------------------------------------------------------

  Future<List<ProductoModel>> obtenerProductosPorCategoria(
    String categoriaId,
  ) async {
    return obtenerProductos(categoriaId: categoriaId);
  }

  Future<List<ProductoModel>> obtenerProductosPorProveedor(
    String proveedorId,
  ) async {
    return obtenerProductos(proveedorId: proveedorId);
  }

  /// Obtiene solo productos en oferta
  Future<List<ProductoModel>> obtenerProductosEnOferta({
    bool random = false,
  }) async {
    try {
      final response = await _productosApi.getProductosEnOferta(random: random);
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ProductoModel>> obtenerProductosDestacados() async {
    try {
      final response = await _productosApi.getProductosDestacados();
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ProductoModel> obtenerProducto(String productoId) async {
    try {
      final response = await _productosApi.getProducto(int.parse(productoId));
      return ProductoModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductoModel> crearProducto(
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _productosApi.createProducto(
        _mapearCampos(data),
        imagen: imagen,
      );
      final payload = response['producto'] ?? response;
      return ProductoModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductoModel> actualizarProducto(
    int id,
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _productosApi.updateProducto(
        id,
        _mapearCampos(data),
        imagen: imagen,
      );
      final payload = response['producto'] ?? response;
      return ProductoModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PROMOCIONES / BANNERS
  // ---------------------------------------------------------------------------

  Future<List<PromocionModel>> obtenerPromociones() async {
    try {
      final response = await _promocionesApi.getPromociones();
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => PromocionModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Promociones filtradas por proveedor
  Future<List<PromocionModel>> obtenerPromocionesPorProveedor(
    String proveedorId,
  ) async {
    try {
      final response = await _promocionesApi.getPromocionesPorProveedor(
        proveedorId,
      );
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => PromocionModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<PromocionModel> crearPromocion(
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _promocionesApi.createPromocion(
        _mapearCampos(data),
        imagen: imagen,
      );
      final payload = response['promocion'] ?? response;
      return PromocionModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<PromocionModel> actualizarPromocion(
    int id,
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _promocionesApi.updatePromocion(
        id,
        _mapearCampos(data),
        imagen: imagen,
      );
      final payload = response['promocion'] ?? response;
      return PromocionModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> eliminarPromocion(int id) async {
    try {
      await _promocionesApi.deletePromocion(id);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _mapearCampos(Map<String, dynamic> data) {
    final Map<String, String> campos = {};
    data.forEach((key, value) {
      if (value == null) return;
      campos[key] = value is String ? value : value.toString();
    });
    return campos;
  }

  // ---------------------------------------------------------------------------
  /// Obtiene productos novedades (recién agregados)
  Future<List<ProductoModel>> obtenerProductosNovedades({
    bool random = false,
  }) async {
    try {
      final response = await _productosApi.getProductosNovedades(
        random: random,
      );
      final lista = _extraerLista(response);
      return lista.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene productos más populares (más vendidos o mejor rating)
  Future<List<ProductoModel>> obtenerProductosMasPopulares({
    bool random = false,
  }) async {
    try {
      final response = await _productosApi.getProductosMasPopulares(
        random: random,
      );
      final lista = _extraerLista(response);
      final productos = lista
          .map((json) => ProductoModel.fromJson(json))
          .toList();
      return productos;
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN PANEL PROVEEDOR
  // ---------------------------------------------------------------------------

  /// Obtiene los productos del proveedor actual (autenticado) con métricas
  Future<List<ProductoModel>> obtenerProductosDelProveedorActual() async {
    try {
      final response = await _productosApi.getProductosProveedor();
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene detalle completo para edición (con breakdown de ratings, etc.)
  Future<ProductoModel> obtenerDetalleProductoProveedor(String id) async {
    try {
      final response = await _productosApi.getDetalleProductoProveedor(
        int.parse(id),
      );
      return ProductoModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un nuevo producto para el proveedor
  Future<ProductoModel> crearProductoProveedor(
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _productosApi.createProductoProveedor(
        _mapearCampos(data),
        imagen: imagen,
      );
      return ProductoModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el listado de categorías para el selector
  Future<List<CategoriaModel>> getCategorias() async {
    try {
      final response = await _categoriasApi.getCategorias();
      final lista = _extraerLista(response);
      return lista.map((e) => CategoriaModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Actualiza producto desde el panel de proveedor
  Future<ProductoModel> actualizarProductoProveedor(
    String id,
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _productosApi.updateProductoProveedor(
        int.parse(id),
        _mapearCampos(data),
        imagen: imagen,
      );
      final payload = response['producto'] ?? response;
      return ProductoModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene las reseñas paginadas (por ahora devuelve lista completa)
  Future<List<ResenaPreview>> obtenerRatingsProductoProveedor(String id) async {
    try {
      final response = await _productosApi.getRatingsProductoProveedor(
        int.parse(id),
      );
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => ResenaPreview.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER PRIVADO (Excelente práctica para DRF)
  // ---------------------------------------------------------------------------

  List<dynamic> _extraerLista(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map) {
      // 1. Estructura custom del ApiClient: { success: true, raw_data: [...] }
      if (response.containsKey('raw_data')) {
        var rawData = response['raw_data'];

        // Si raw_data es String (JSON sin parsear), parsearlo
        if (rawData is String) {
          try {
            rawData = jsonDecode(rawData);
          } catch (e) {
            return [];
          }
        }

        if (rawData is List) {
          return rawData;
        }

        if (rawData is Map && rawData.containsKey('results')) {
          final results = rawData['results'] as List<dynamic>;
          return results;
        }
      }

      // 1b. Respuesta del ApiClient cuando decodifica listas como {data: [...]}
      if (response.containsKey('data') && response['data'] is List) {
        return response['data'] as List<dynamic>;
      }

      // 2. Paginación estándar de Django Rest Framework: { results: [...] }
      if (response.containsKey('results')) {
        final results = response['results'] as List<dynamic>;
        return results;
      }
    }

    return [];
  }
}
