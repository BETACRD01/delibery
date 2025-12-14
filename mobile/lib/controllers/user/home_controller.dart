// lib/controllers/user/home_controller.dart

import 'package:flutter/material.dart';
import '../../models/categoria_model.dart';
import '../../models/promocion_model.dart';
import '../../models/producto_model.dart';
import '../../services/productos_service.dart';
import '../../services/usuarios_service.dart';

/// Controller para la pantalla Home
/// Maneja el estado y la lógica de negocio
class HomeController extends ChangeNotifier {
  // ════════════════════════════════════════════════════════════════
  // SERVICIOS
  // ════════════════════════════════════════════════════════════════
  final _productosService = ProductosService();
  final _usuarioService = UsuarioService();

  // ════════════════════════════════════════════════════════════════
  // ESTADO
  // ════════════════════════════════════════════════════════════════

  bool _loading = false;
  String? _error;

  List<CategoriaModel> _categorias = [];
  List<PromocionModel> _promociones = [];
  List<ProductoModel> _productosDestacados = [];
  List<ProductoModel> _productosEnOferta = [];
  List<ProductoModel> _productosNovedades = [];
  List<ProductoModel> _productosMasPopulares = [];

  // Estadísticas del usuario
  int _totalPedidos = 0;
  int _puntosAcumulados = 0;
  int _cuponesDisponibles = 0;
  int _rifasParticipadas = 0;
  int _rifasGanadas = 0;

  // ════════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════════

  bool get loading => _loading;
  String? get error => _error;

  List<CategoriaModel> get categorias => _categorias;
  List<PromocionModel> get promociones => _promociones;
  List<ProductoModel> get productosDestacados => _productosDestacados;
  List<ProductoModel> get productosEnOferta => _productosEnOferta;
  List<ProductoModel> get productosNovedades => _productosNovedades;
  List<ProductoModel> get productosMasPopulares => _productosMasPopulares;

  int get totalPedidos => _totalPedidos;
  int get puntosAcumulados => _puntosAcumulados;
  int get cuponesDisponibles => _cuponesDisponibles;
  int get rifasParticipadas => _rifasParticipadas;
  int get rifasGanadas => _rifasGanadas;

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS - CARGA DE DATOS
  // ════════════════════════════════════════════════════════════════

  /// Carga todos los datos de la pantalla home
  Future<void> cargarDatos() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _cargarCategorias(),
        _cargarPromociones(),
        _cargarProductosDestacados(),
        _cargarProductosEnOferta(),
        _cargarProductosNovedades(),
        _cargarProductosMasPopulares(),
        _cargarEstadisticas(),
      ], eagerError: false);

      _loading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = 'Error al cargar datos: $e';
      notifyListeners();
    }
  }

  /// Refresca todos los datos con productos aleatorios
  Future<void> refrescar() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _cargarCategorias(),
        _cargarPromociones(),
        _cargarProductosDestacados(),
        _cargarProductosEnOfertaRandom(),
        _cargarProductosNovedadesRandom(),
        _cargarProductosMasPopularesRandom(),
        _cargarEstadisticas(),
      ], eagerError: false);

      _loading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = 'Error al refrescar datos: $e';
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS - CARGA DE DATOS
  // ════════════════════════════════════════════════════════════════

  Future<void> _cargarCategorias() async {
    try {
      _categorias = await _productosService.obtenerCategorias();
    } catch (e) {
      _categorias = [];
    }
  }

  Future<void> _cargarPromociones() async {
    try {
      _promociones = await _productosService.obtenerPromociones();
    } catch (e) {
      _promociones = [];
    }
  }

  Future<void> _cargarProductosDestacados() async {
    try {
      _productosDestacados = await _productosService.obtenerProductosDestacados();
    } catch (e) {
      _productosDestacados = [];
    }
  }

  Future<void> _cargarProductosEnOferta() async {
    try {
      _productosEnOferta = await _productosService.obtenerProductosEnOferta();
    } catch (e) {
      _productosEnOferta = [];
    }
  }

  Future<void> _cargarProductosEnOfertaRandom() async {
    try {
      _productosEnOferta = await _productosService.obtenerProductosEnOferta(random: true);
    } catch (e) {
      _productosEnOferta = [];
    }
  }

  Future<void> _cargarProductosNovedades() async {
    try {
      _productosNovedades = await _productosService.obtenerProductosNovedades();
    } catch (e) {
      _productosNovedades = [];
    }
  }

  Future<void> _cargarProductosNovedadesRandom() async {
    try {
      _productosNovedades = await _productosService.obtenerProductosNovedades(random: true);
    } catch (e) {
      _productosNovedades = [];
    }
  }

  Future<void> _cargarProductosMasPopulares() async {
    try {
      _productosMasPopulares = await _productosService.obtenerProductosMasPopulares();
    } catch (e) {
      _productosMasPopulares = [];
    }
  }

  Future<void> _cargarProductosMasPopularesRandom() async {
    try {
      _productosMasPopulares = await _productosService.obtenerProductosMasPopulares(random: true);
    } catch (e) {
      _productosMasPopulares = [];
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final stats = await _usuarioService.obtenerEstadisticas(forzarRecarga: true);
      _totalPedidos = stats.totalPedidos;
      _puntosAcumulados = stats.totalResenas;
      _cuponesDisponibles = stats.totalMetodosPago;

      final rifas = await _usuarioService.obtenerRifasParticipaciones(forzarRecarga: true);
      _rifasParticipadas = (rifas['total'] as num?)?.toInt() ?? 0;
      _rifasGanadas = (rifas['victorias'] as num?)?.toInt() ?? 0;
    } catch (e) {
      _totalPedidos = 0;
      _puntosAcumulados = 0;
      _cuponesDisponibles = 0;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS - ACCIONES
  // ════════════════════════════════════════════════════════════════

  void verCategoria(CategoriaModel categoria) {
    // TODO: Navegar a pantalla de categoría
  }

  void verPromocion(PromocionModel promocion) {
    // TODO: Navegar a detalle de promoción
  }

  void verProducto(ProductoModel producto) {
    // TODO: Navegar a detalle de producto
  }

  void agregarAlCarrito(ProductoModel producto) {
    // Nota: Esto se manejará desde el widget con Provider
  }

  void verMenuCompleto() {
    // TODO: Navegar a menú completo
  }

  void verTodasCategorias() {
    // TODO: Navegar a listado de categorías
  }

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS DE UTILIDAD
  // ════════════════════════════════════════════════════════════════

  /// Limpia el error actual
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  /// Formatea los puntos acumulados
  String get puntosFormateados {
    if (_puntosAcumulados >= 1000) {
      return '${(_puntosAcumulados / 1000).toStringAsFixed(1)}K';
    }
    return _puntosAcumulados.toString();
  }
}
