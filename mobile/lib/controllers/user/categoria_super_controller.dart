// lib/controllers/user/categoria_super_controller.dart

import 'package:flutter/material.dart';
import '../../services/super_service.dart';

/// Controller para gestionar los datos de una categoría Super específica
class CategoriaSuperController extends ChangeNotifier {
  final String categoriaId;
  final SuperService _service = SuperService();

  List<dynamic> _proveedores = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get proveedores => _proveedores;
  bool get loading => _loading;
  String? get error => _error;

  CategoriaSuperController(this.categoriaId) {
    cargarProveedores();
  }

  /// Carga los proveedores de la categoría
  Future<void> cargarProveedores() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _proveedores = await _service.obtenerProveedoresPorCategoria(categoriaId);

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresca los datos
  Future<void> refrescar() async {
    await cargarProveedores();
  }

  /// Obtiene los productos de un proveedor
  Future<List<dynamic>> obtenerProductosProveedor(int proveedorId) async {
    try {
      return await _service.obtenerProductosProveedor(proveedorId);
    } catch (e) {
      return [];
    }
  }
}
