// lib/services/usuarios/super_service.dart

import '../../config/network/api_config.dart';
import 'package:mobile/services/core/api/http_client.dart';
import '../../models/products/categoria_super_model.dart';

/// Servicio para gestionar las categorías del Super
class SuperService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------
  static final SuperService _instance = SuperService._internal();
  factory SuperService() => _instance;
  SuperService._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // CATEGORÍAS SUPER
  // ---------------------------------------------------------------------------

  /// Obtiene todas las categorías del Super desde el backend
  Future<List<CategoriaSuperModel>> obtenerCategoriasSuper() async {
    try {
      final response = await _client.get(ApiConfig.superCategorias);

      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => CategoriaSuperModel.fromJson(json)).toList();
    } catch (e) {
      // Si falla la conexión, usar categorías predefinidas como fallback
      return CategoriaSuperModel.categoriasPredefinidas;
    }
  }

  /// Obtiene una categoría específica por ID
  Future<CategoriaSuperModel?> obtenerCategoriaSuper(String categoriaId) async {
    try {
      final response = await _client.get(ApiConfig.superCategoriaDetalle(categoriaId));
      return CategoriaSuperModel.fromJson(response);
    } catch (e) {
      // Buscar en categorías predefinidas
      try {
        return CategoriaSuperModel.categoriasPredefinidas.firstWhere(
          (cat) => cat.id == categoriaId,
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Obtiene productos/servicios de una categoría Super específica
  Future<List<dynamic>> obtenerProductosCategoriaSuper(String categoriaId) async {
    try {
      final response = await _client.get(
        ApiConfig.superCategoriaProductos(categoriaId),
      );

      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PROVEEDORES SUPER
  // ---------------------------------------------------------------------------

  /// Obtiene todos los proveedores de una categoría
  Future<List<dynamic>> obtenerProveedoresPorCategoria(String categoriaId) async {
    try {
      final response = await _client.get(
        ApiConfig.superProveedoresPorCategoria(categoriaId),
      );

      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un proveedor específico por ID
  Future<Map<String, dynamic>> obtenerProveedor(int proveedorId) async {
    try {
      final response = await _client.get(
        ApiConfig.superProveedorDetalle(proveedorId),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene todos los proveedores activos
  Future<List<dynamic>> obtenerProveedores() async {
    try {
      final response = await _client.get(ApiConfig.superProveedores);
      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene solo los proveedores abiertos
  Future<List<dynamic>> obtenerProveedoresAbiertos() async {
    try {
      final response = await _client.get(ApiConfig.superProveedoresAbiertos);
      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PRODUCTOS SUPER
  // ---------------------------------------------------------------------------

  /// Obtiene los productos de un proveedor específico
  Future<List<dynamic>> obtenerProductosProveedor(int proveedorId) async {
    try {
      final response = await _client.get(
        ApiConfig.superProveedorProductos(proveedorId),
      );

      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene todos los productos disponibles
  Future<List<dynamic>> obtenerProductos() async {
    try {
      final response = await _client.get(ApiConfig.superProductos);
      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene productos en oferta
  Future<List<dynamic>> obtenerProductosOfertas() async {
    try {
      final response = await _client.get(ApiConfig.superProductosOfertas);
      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene productos destacados
  Future<List<dynamic>> obtenerProductosDestacados() async {
    try {
      final response = await _client.get(ApiConfig.superProductosDestacados);
      return _extraerLista(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un producto específico
  Future<Map<String, dynamic>> obtenerProducto(int productoId) async {
    try {
      final response = await _client.get(
        ApiConfig.superProductoDetalle(productoId),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Crear o actualizar una categoría Super (Admin)
  Future<CategoriaSuperModel> crearCategoriaSuper(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConfig.superCategorias,
        data,
      );
      return CategoriaSuperModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar una categoría Super (Admin)
  Future<CategoriaSuperModel> actualizarCategoriaSuper(
    String categoriaId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put(
        ApiConfig.superCategoriaDetalle(categoriaId),
        data,
      );
      return CategoriaSuperModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una categoría Super (Admin)
  Future<void> eliminarCategoriaSuper(String categoriaId) async {
    try {
      await _client.delete(ApiConfig.superCategoriaDetalle(categoriaId));
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  List<dynamic> _extraerLista(dynamic response) {
    if (response is List) return response;
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List;
    }
    return [];
  }
}