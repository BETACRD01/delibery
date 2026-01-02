import '../../apis/productos/productos_api.dart';
import '../../domain/repositories/producto_repository.dart';
import '../../models/core/paginated_response.dart';
import '../../models/products/producto_model.dart';
import 'dart:convert';

class ProductoRepositoryImpl implements ProductoRepository {
  final ProductosApi _api;

  ProductoRepositoryImpl({ProductosApi? api}) : _api = api ?? ProductosApi();

  @override
  Future<PaginatedResponse<ProductoModel>> getProductos({
    int page = 1,
    int limit = 20,
    String? busqueda,
    String? categoriaId,
  }) async {
    final response = await _api.getProductos(
      busqueda: busqueda,
      categoriaId: categoriaId,
      page: page,
      pageSize: limit,
    );

    // Parse DRF pagination format
    // { "count": 100, "next": "...", "previous": "...", "results": [...] }

    // Check if response is map (Pagination) or list (Old API)
    if (response is Map) {
      // Handle "raw_data" wrapper if present (custom ApiClient stuff)
      dynamic paginatedData = response;
      if (response.containsKey('raw_data')) {
        final raw = response['raw_data'];
        if (raw is String) {
          paginatedData = jsonDecode(raw);
        } else {
          paginatedData = raw;
        }
      }

      // Look for standard DRF keys
      if (paginatedData is Map && paginatedData.containsKey('results')) {
        final List<dynamic> results = paginatedData['results'];
        final List<ProductoModel> productos = results
            .map((e) => ProductoModel.fromJson(e))
            .toList();

        return PaginatedResponse(
          data: productos,
          total: paginatedData['count'] ?? 0,
          next: paginatedData['next'],
          previous: paginatedData['previous'],
        );
      }
    }

    // Fallback if API returns plain list (shouldn't happen with pagination enabled but safe to have)
    if (response is List) {
      final List<ProductoModel> productos = response
          .map((e) => ProductoModel.fromJson(e))
          .toList();
      return PaginatedResponse(data: productos, total: productos.length);
    }

    // Another fallback for parsed 'data' key
    if (response is Map &&
        response.containsKey('data') &&
        response['data'] is List) {
      final List<dynamic> list = response['data'];
      final List<ProductoModel> productos = list
          .map((e) => ProductoModel.fromJson(e))
          .toList();
      return PaginatedResponse(data: productos, total: productos.length);
    }

    return PaginatedResponse(data: [], total: 0);
  }
}
