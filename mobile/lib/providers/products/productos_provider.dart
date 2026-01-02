import 'package:flutter/material.dart';
import '../../domain/repositories/producto_repository.dart';
import '../../infrastructure/repositories/producto_repository_impl.dart';
import '../../models/products/producto_model.dart';

class ProductosProvider extends ChangeNotifier {
  final ProductoRepository _repository;

  ProductosProvider({ProductoRepository? repository})
    : _repository = repository ?? ProductoRepositoryImpl();

  // State
  List<ProductoModel> _productos = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _limit = 20;

  // Filters
  String? _currentSearch;
  String? _currentCategoriaId;

  // Getters
  List<ProductoModel> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Reinicia la lista y carga la primera página
  Future<void> recargar({String? busqueda, String? categoriaId}) async {
    _productos = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _currentSearch = busqueda;
    _currentCategoriaId = categoriaId;
    notifyListeners();
    await cargarSiguientePagina();
  }

  /// Carga la siguiente página de productos
  Future<void> cargarSiguientePagina() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.getProductos(
        page: _currentPage,
        limit: _limit,
        busqueda: _currentSearch,
        categoriaId: _currentCategoriaId,
      );

      final newItems = response.data;

      _productos.addAll(newItems);

      // Determine if there are more pages
      // Logic: If we got fewer items than limit, or if API says no next page
      if (newItems.length < _limit || response.next == null) {
        _hasMore = false;
      } else {
        _currentPage++;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
