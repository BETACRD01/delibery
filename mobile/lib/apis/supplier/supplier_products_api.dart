// lib/apis/supplier/supplier_products_api.dart

import 'dart:io';

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de productos del proveedor autenticado
class SupplierProductsApi {
  static final SupplierProductsApi _instance = SupplierProductsApi._internal();
  factory SupplierProductsApi() => _instance;
  SupplierProductsApi._internal();

  final _client = ApiClient();

  /// Obtiene productos del proveedor actual
  Future<Map<String, dynamic>> getProductos() async {
    return await _client.get(ApiConfig.providerProducts);
  }

  /// Obtiene detalle de un producto
  Future<Map<String, dynamic>> getProductoDetalle(int id) async {
    return await _client.get(ApiConfig.providerProductDetail(id));
  }

  /// Crea un nuevo producto
  Future<Map<String, dynamic>> postProducto(
    Map<String, String> fields,
    Map<String, File> files,
  ) async {
    return await _client.multipart(
      'POST',
      ApiConfig.providerProducts,
      fields,
      files,
    );
  }

  /// Actualiza un producto
  Future<Map<String, dynamic>> patchProducto(
    int id,
    Map<String, String> fields,
    Map<String, File> files,
  ) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.providerProductDetail(id),
      fields,
      files,
    );
  }

  /// Obtiene ratings de un producto
  Future<Map<String, dynamic>> getProductoRatings(int id) async {
    return await _client.get(ApiConfig.providerProductRatings(id));
  }

  /// Obtiene categorías
  Future<Map<String, dynamic>> getCategorias() async {
    return await _client.get(ApiConfig.productosCategorias);
  }
}
