// lib/apis/productos/productos_api.dart

import 'dart:io';

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para productos del catálogo
class ProductosApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final ProductosApi _instance = ProductosApi._internal();
  factory ProductosApi() => _instance;
  ProductosApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // PRODUCTOS
  // ---------------------------------------------------------------------------

  /// Obtiene lista de productos con filtros opcionales
  Future<dynamic> getProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
    int? page,
    int? pageSize,
  }) async {
    String url = ApiConfig.productosLista;

    final List<String> params = [];
    if (categoriaId != null) params.add('categoria_id=$categoriaId');
    if (proveedorId != null) params.add('proveedor_id=$proveedorId');
    if (soloOfertas) params.add('solo_ofertas=true');
    if (busqueda != null && busqueda.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(busqueda)}');
    }
    if (page != null) params.add('page=$page');
    if (pageSize != null) params.add('page_size=$pageSize');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return await _client.get(url);
  }

  /// Obtiene un producto por ID
  Future<Map<String, dynamic>> getProducto(int productoId) async {
    return await _client.get(ApiConfig.productoDetalle(productoId));
  }

  /// Obtiene productos en oferta
  Future<dynamic> getProductosEnOferta({bool random = false}) async {
    String url = '${ApiConfig.productosLista}ofertas/';
    if (random) url += '?random=true';
    return await _client.get(url);
  }

  /// Obtiene productos destacados
  Future<dynamic> getProductosDestacados() async {
    return await _client.get(ApiConfig.productosDestacados);
  }

  /// Obtiene productos novedades
  Future<dynamic> getProductosNovedades({bool random = false}) async {
    String url = '${ApiConfig.productosLista}novedades/';
    if (random) url += '?random=true';
    return await _client.get(url);
  }

  /// Obtiene productos más populares
  Future<dynamic> getProductosMasPopulares({bool random = false}) async {
    String url = '${ApiConfig.productosLista}mas-populares/';
    if (random) url += '?random=true';
    return await _client.get(url);
  }

  /// Crea un producto (cliente/usuario)
  Future<Map<String, dynamic>> createProducto(
    Map<String, String> data, {
    File? imagen,
  }) async {
    return await _client.multipart(
      'POST',
      ApiConfig.productosLista,
      data,
      imagen != null ? {'imagen': imagen} : {},
    );
  }

  /// Actualiza un producto (cliente/usuario)
  Future<Map<String, dynamic>> updateProducto(
    int id,
    Map<String, String> data, {
    File? imagen,
  }) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.productoDetalle(id),
      data,
      imagen != null ? {'imagen': imagen} : {},
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCTOS PROVEEDOR (Panel de proveedor)
  // ---------------------------------------------------------------------------

  /// Obtiene productos del proveedor autenticado
  Future<dynamic> getProductosProveedor() async {
    return await _client.get(ApiConfig.providerProducts);
  }

  /// Obtiene detalle de producto para proveedor
  Future<Map<String, dynamic>> getDetalleProductoProveedor(int id) async {
    return await _client.get(ApiConfig.providerProductDetail(id));
  }

  /// Crea un producto desde el panel de proveedor
  Future<Map<String, dynamic>> createProductoProveedor(
    Map<String, String> data, {
    File? imagen,
  }) async {
    return await _client.multipart(
      'POST',
      ApiConfig.providerProducts,
      data,
      imagen != null ? {'imagen': imagen} : {},
    );
  }

  /// Actualiza un producto desde el panel de proveedor
  Future<Map<String, dynamic>> updateProductoProveedor(
    int id,
    Map<String, String> data, {
    File? imagen,
  }) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.providerProductDetail(id),
      data,
      imagen != null ? {'imagen': imagen} : {},
    );
  }

  /// Obtiene ratings de un producto del proveedor
  Future<dynamic> getRatingsProductoProveedor(int id) async {
    return await _client.get(ApiConfig.providerProductRatings(id));
  }

  /// Elimina un producto del proveedor
  Future<void> deleteProductoProveedor(int id) async {
    await _client.delete(ApiConfig.providerProductDetail(id));
  }
}
