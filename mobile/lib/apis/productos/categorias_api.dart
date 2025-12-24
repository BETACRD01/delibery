// lib/apis/productos/categorias_api.dart

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

/// API para categorías de productos
class CategoriasApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final CategoriasApi _instance = CategoriasApi._internal();
  factory CategoriasApi() => _instance;
  CategoriasApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // CATEGORÍAS
  // ---------------------------------------------------------------------------

  /// Obtiene todas las categorías
  Future<dynamic> getCategorias() async {
    return await _client.get(ApiConfig.productosCategorias);
  }

  /// Obtiene una categoría por ID
  Future<Map<String, dynamic>> getCategoria(String categoriaId) async {
    final url = '${ApiConfig.productosCategorias}$categoriaId/';
    return await _client.get(url);
  }
}
