// lib/controllers/user/busqueda_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/producto_model.dart';
import '../../models/categoria_model.dart';
import '../../services/productos/productos_service.dart';

class BusquedaController extends ChangeNotifier {
  final TextEditingController _controladorBusqueda = TextEditingController();
  final _service = ProductosService();

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADO
  // ══════════════════════════════════════════════════════════════════════════

  List<ProductoModel> _resultados = [];
  List<CategoriaModel> _categorias = [];
  List<String> _historialBusqueda = [];
  bool _buscando = false;
  String? _error;

  // Filtros
  String? _categoriaSeleccionada;
  double _precioMin = 0;
  double _precioMax = 1000;
  double _ratingMin = 0;
  String _ordenamiento = 'relevancia'; // relevancia, precio_asc, precio_desc, rating

  // Debouncing
  Timer? _debounceTimer;

  // ══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════════════════════

  TextEditingController get controladorBusqueda => _controladorBusqueda;
  List<ProductoModel> get resultados => _resultadosFiltrados;
  List<CategoriaModel> get categorias => _categorias;
  List<String> get historialBusqueda => _historialBusqueda;
  bool get buscando => _buscando;
  String? get error => _error;

  String? get categoriaSeleccionada => _categoriaSeleccionada;
  double get precioMin => _precioMin;
  double get precioMax => _precioMax;
  double get ratingMin => _ratingMin;
  String get ordenamiento => _ordenamiento;

  bool get tieneFiltrosActivos =>
    _categoriaSeleccionada != null ||
    _precioMin > 0 ||
    _precioMax < 1000 ||
    _ratingMin > 0;

  // ══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  BusquedaController() {
    _cargarHistorial();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      _categorias = await _service.obtenerCategorias();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BÚSQUEDA CON DEBOUNCING
  // ══════════════════════════════════════════════════════════════════════════

  void buscarProductos(String query) {
    // Cancelar búsqueda anterior
    _debounceTimer?.cancel();

    // Si la búsqueda está vacía, limpiar resultados
    if (query.isEmpty) {
      _resultados = [];
      _error = null;
      notifyListeners();
      return;
    }

    // Si la búsqueda es muy corta, no disparar API
    if (query.length < 2) {
      return;
    }

    // Debouncing: esperar 500ms antes de buscar
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _ejecutarBusqueda(query);
    });
  }

  Future<void> _ejecutarBusqueda(String query) async {
    _buscando = true;
    _error = null;
    notifyListeners();

    try {
      _resultados = await _service.obtenerProductos(
        busqueda: query,
        categoriaId: _categoriaSeleccionada,
      );

      // Guardar en historial si hay resultados
      if (_resultados.isNotEmpty) {
        await _agregarAlHistorial(query);
      }

    } catch (e) {
      _error = 'Error al buscar productos. Intenta de nuevo.';
      debugPrint('Error en búsqueda: $e');
      _resultados = [];
    }

    _buscando = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTROS Y ORDENAMIENTO
  // ══════════════════════════════════════════════════════════════════════════

  List<ProductoModel> get _resultadosFiltrados {
    var filtrados = List<ProductoModel>.from(_resultados);

    // Filtrar por precio
    if (_precioMin > 0 || _precioMax < 1000) {
      filtrados = filtrados.where((p) =>
        p.precio >= _precioMin && p.precio <= _precioMax
      ).toList();
    }

    // Filtrar por rating
    if (_ratingMin > 0) {
      filtrados = filtrados.where((p) => p.rating >= _ratingMin).toList();
    }

    // Ordenar
    switch (_ordenamiento) {
      case 'precio_asc':
        filtrados.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case 'precio_desc':
        filtrados.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case 'rating':
        filtrados.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'relevancia':
      default:
        // Ya viene ordenado por relevancia desde el backend
        break;
    }

    return filtrados;
  }

  void setCategoria(String? categoriaId) {
    _categoriaSeleccionada = categoriaId;
    notifyListeners();

    // Re-ejecutar búsqueda si hay texto
    if (_controladorBusqueda.text.isNotEmpty) {
      _ejecutarBusqueda(_controladorBusqueda.text);
    }
  }

  void setRangoPrecio(double min, double max) {
    _precioMin = min;
    _precioMax = max;
    notifyListeners();
  }

  void setRatingMinimo(double rating) {
    _ratingMin = rating;
    notifyListeners();
  }

  void setOrdenamiento(String orden) {
    _ordenamiento = orden;
    notifyListeners();
  }

  void limpiarFiltros() {
    _categoriaSeleccionada = null;
    _precioMin = 0;
    _precioMax = 1000;
    _ratingMin = 0;
    _ordenamiento = 'relevancia';
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HISTORIAL DE BÚSQUEDA
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _cargarHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _historialBusqueda = prefs.getStringList('historial_busqueda') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar historial: $e');
    }
  }

  Future<void> _agregarAlHistorial(String query) async {
    try {
      // Evitar duplicados
      _historialBusqueda.remove(query);

      // Agregar al inicio
      _historialBusqueda.insert(0, query);

      // Limitar a 20 búsquedas
      if (_historialBusqueda.length > 20) {
        _historialBusqueda = _historialBusqueda.sublist(0, 20);
      }

      // Guardar
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('historial_busqueda', _historialBusqueda);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar historial: $e');
    }
  }

  Future<void> eliminarDelHistorial(String query) async {
    try {
      _historialBusqueda.remove(query);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('historial_busqueda', _historialBusqueda);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar del historial: $e');
    }
  }

  Future<void> limpiarHistorial() async {
    try {
      _historialBusqueda.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('historial_busqueda');
      notifyListeners();
    } catch (e) {
      debugPrint('Error al limpiar historial: $e');
    }
  }

  void buscarDesdeHistorial(String query) {
    _controladorBusqueda.text = query;
    _ejecutarBusqueda(query);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ══════════════════════════════════════════════════════════════════════════

  void limpiarBusqueda() {
    _controladorBusqueda.clear();
    _resultados = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controladorBusqueda.dispose();
    super.dispose();
  }
}