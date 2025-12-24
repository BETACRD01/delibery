// lib/apis/super/super_api.dart

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión del Super (categorías, proveedores, productos)
class SuperApi {
  static final SuperApi _instance = SuperApi._internal();
  factory SuperApi() => _instance;
  SuperApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // CATEGORÍAS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getCategorias() async {
    return await _client.get(ApiConfig.superCategorias);
  }

  Future<Map<String, dynamic>> getCategoriaDetalle(String id) async {
    return await _client.get(ApiConfig.superCategoriaDetalle(id));
  }

  Future<Map<String, dynamic>> getCategoriaProductos(String id) async {
    return await _client.get(ApiConfig.superCategoriaProductos(id));
  }

  Future<Map<String, dynamic>> postCategoria(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.superCategorias, data);
  }

  Future<Map<String, dynamic>> putCategoria(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _client.put(ApiConfig.superCategoriaDetalle(id), data);
  }

  Future<void> deleteCategoria(String id) async {
    await _client.delete(ApiConfig.superCategoriaDetalle(id));
  }

  // ---------------------------------------------------------------------------
  // PROVEEDORES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getProveedores() async {
    return await _client.get(ApiConfig.superProveedores);
  }

  Future<Map<String, dynamic>> getProveedoresAbiertos() async {
    return await _client.get(ApiConfig.superProveedoresAbiertos);
  }

  Future<Map<String, dynamic>> getProveedoresPorCategoria(
    String categoriaId,
  ) async {
    return await _client.get(
      ApiConfig.superProveedoresPorCategoria(categoriaId),
    );
  }

  Future<Map<String, dynamic>> getProveedorDetalle(int id) async {
    return await _client.get(ApiConfig.superProveedorDetalle(id));
  }

  Future<Map<String, dynamic>> getProveedorProductos(int id) async {
    return await _client.get(ApiConfig.superProveedorProductos(id));
  }

  // ---------------------------------------------------------------------------
  // PRODUCTOS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getProductos() async {
    return await _client.get(ApiConfig.superProductos);
  }

  Future<Map<String, dynamic>> getProductosOfertas() async {
    return await _client.get(ApiConfig.superProductosOfertas);
  }

  Future<Map<String, dynamic>> getProductosDestacados() async {
    return await _client.get(ApiConfig.superProductosDestacados);
  }

  Future<Map<String, dynamic>> getProductoDetalle(int id) async {
    return await _client.get(ApiConfig.superProductoDetalle(id));
  }
}
