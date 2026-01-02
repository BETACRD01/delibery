// lib/apis/productos/categorias_api.dart

import 'dart:io';

import '../../config/network/api_config.dart';
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

  /// Crea una nueva categoría
  Future<dynamic> crearCategoria({
    required String nombre,
    File? imagen,
    String? imagenUrl,
  }) async {
    final fields = {'nombre': nombre};
    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      fields['imagen_url'] = imagenUrl;
    }

    if (imagen != null) {
      return await _client.multipart(
        'POST',
        ApiConfig.productosCategorias,
        fields,
        {'imagen': imagen},
      );
    } else {
      return await _client.post(ApiConfig.productosCategorias, fields);
    }
  }

  /// Elimina una categoría
  Future<void> eliminarCategoria(String id) async {
    final url = '${ApiConfig.productosCategorias}$id/';
    await _client.delete(url);
  }

  /// Actualiza una categoría existente
  Future<dynamic> actualizarCategoria({
    required String id,
    String? nombre,
    File? imagen,
    String? imagenUrl,
  }) async {
    final url = '${ApiConfig.productosCategorias}$id/';
    final fields = <String, String>{};

    if (nombre != null) fields['nombre'] = nombre;
    if (imagenUrl != null) fields['imagen_url'] = imagenUrl;

    if (imagen != null) {
      return await _client.multipart(
        'PATCH', // Usamos PATCH para actualización parcial
        url,
        fields,
        {'imagen': imagen},
      );
    } else {
      return await _client.patch(url, fields);
    }
  }
}
