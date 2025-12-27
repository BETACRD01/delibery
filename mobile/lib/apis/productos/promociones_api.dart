// lib/apis/productos/promociones_api.dart

import 'dart:io';

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

/// API para promociones/banners
class PromocionesApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final PromocionesApi _instance = PromocionesApi._internal();
  factory PromocionesApi() => _instance;
  PromocionesApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // PROMOCIONES (PÚBLICO - Solo lectura)
  // ---------------------------------------------------------------------------

  /// Obtiene todas las promociones activas
  Future<dynamic> getPromociones() async {
    return await _client.get(ApiConfig.productosPromociones);
  }

  /// Obtiene promociones por proveedor
  Future<dynamic> getPromocionesPorProveedor(String proveedorId) async {
    final url = '${ApiConfig.productosPromociones}?proveedor_id=$proveedorId';
    return await _client.get(url);
  }

  // ---------------------------------------------------------------------------
  // PROMOCIONES PROVEEDOR (CRUD completo)
  // ---------------------------------------------------------------------------

  /// Obtiene promociones del proveedor autenticado
  Future<dynamic> getMisPromociones() async {
    return await _client.get(ApiConfig.providerPromociones);
  }

  /// Crea una promoción (usando endpoint de proveedor)
  Future<Map<String, dynamic>> createPromocion(
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    return await _client.multipart(
      'POST',
      ApiConfig.providerPromociones,
      data,
      imagen != null ? {'imagen': imagen} : {},
    );
  }

  /// Actualiza una promoción (usando endpoint de proveedor)
  Future<Map<String, dynamic>> updatePromocion(
    int id,
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.providerPromocionDetalle(id),
      data,
      imagen != null ? {'imagen': imagen} : {},
    );
  }

  /// Elimina una promoción (usando endpoint de proveedor)
  Future<void> deletePromocion(int id) async {
    await _client.delete(ApiConfig.providerPromocionDetalle(id));
  }
}
