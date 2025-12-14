// lib/controllers/user/super_controller.dart

import 'package:flutter/material.dart';
import '../../models/categoria_super_model.dart';
import '../../services/super_service.dart';

/// Controlador para la pantalla Super
class SuperController extends ChangeNotifier {
  final SuperService _superService = SuperService();

  // Estado de carga
  bool _loading = false;
  bool get loading => _loading;

  // Error
  String? _error;
  String? get error => _error;

  // Categorías disponibles
  List<CategoriaSuperModel> _categorias = [];
  List<CategoriaSuperModel> get categorias => _categorias;

  // Categoría seleccionada
  CategoriaSuperModel? _categoriaSeleccionada;
  CategoriaSuperModel? get categoriaSeleccionada => _categoriaSeleccionada;

  SuperController() {
    cargarCategorias();
  }

  /// Carga las categorías del Super desde el backend
  Future<void> cargarCategorias() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Intenta cargar desde el backend, si falla usa las predefinidas
      _categorias = await _superService.obtenerCategoriasSuper();
      _loading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      // Si hay error, usar categorías predefinidas como fallback
      _categorias = CategoriaSuperModel.categoriasPredefinidas;
      _error = null; // No mostrar error si tenemos fallback
      _loading = false;
      notifyListeners();
    }
  }

  /// Selecciona una categoría
  void seleccionarCategoria(CategoriaSuperModel categoria) {
    _categoriaSeleccionada = categoria;
    notifyListeners();
  }

  /// Limpia la selección de categoría
  void limpiarSeleccion() {
    _categoriaSeleccionada = null;
    notifyListeners();
  }

  /// Refresca los datos
  Future<void> refrescar() async {
    await cargarCategorias();
  }
}
