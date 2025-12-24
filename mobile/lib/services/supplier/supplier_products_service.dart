// lib/services/supplier/supplier_products_service.dart

import 'dart:io';
import '../../apis/subapis/http_client.dart';
import '../../config/api_config.dart';
import '../../models/categoria_model.dart';
import '../../models/producto_model.dart';

/// Servicio dedicado para gestión de productos del proveedor autenticado
/// Separado de ProductosService que maneja productos globales
class SupplierProductsService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final SupplierProductsService _instance =
      SupplierProductsService._internal();
  factory SupplierProductsService() => _instance;
  SupplierProductsService._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // GESTIÓN DE PRODUCTOS DEL PROVEEDOR
  // ---------------------------------------------------------------------------

  /// Obtiene los productos del proveedor actual (autenticado) con métricas
  Future<List<ProductoModel>> obtenerProductosDelProveedorActual() async {
    try {
      final response = await _client.get(ApiConfig.providerProducts);
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene detalle completo para edición (con breakdown de ratings, etc.)
  Future<ProductoModel> obtenerDetalleProductoProveedor(String id) async {
    try {
      final response = await _client.get(
        ApiConfig.providerProductDetail(int.parse(id)),
      );
      return ProductoModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un nuevo producto para el proveedor
  Future<ProductoModel> crearProductoProveedor(
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _client.multipart(
        'POST',
        ApiConfig.providerProducts,
        _mapearCampos(data),
        imagen != null ? {'imagen': imagen} : {},
      );
      // El backend devuelve el objeto creado
      return ProductoModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza producto desde el panel de proveedor
  Future<ProductoModel> actualizarProductoProveedor(
    String id,
    Map<String, dynamic> data, {
    File? imagen,
  }) async {
    try {
      final response = await _client.multipart(
        'PATCH',
        ApiConfig.providerProductDetail(int.parse(id)),
        _mapearCampos(data),
        imagen != null ? {'imagen': imagen} : {},
      );
      // El backend puede devolver el objeto directo o dentro de 'producto'
      final payload = response['producto'] ?? response;
      return ProductoModel.fromJson(payload as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene las reseñas paginadas del producto
  Future<List<ResenaPreview>> obtenerRatingsProductoProveedor(String id) async {
    try {
      final response = await _client.get(
        ApiConfig.providerProductRatings(int.parse(id)),
      );
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => ResenaPreview.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene el listado de categorías para el selector
  Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final response = await _client.get(ApiConfig.productosCategorias);
      // Asumiendo que el backend retorna una lista directa o paginada en 'results'
      final lista =
          ((response is List) ? response : response['results'] as List)
              as List<dynamic>;
      return lista.map((e) => CategoriaModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Map<String, String> _mapearCampos(Map<String, dynamic> data) {
    final Map<String, String> campos = {};
    data.forEach((key, value) {
      if (value == null) return;
      campos[key] = value is String ? value : value.toString();
    });
    return campos;
  }

  List<dynamic> _extraerLista(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map) {
      // 1. Estructura custom del ApiClient: { success: true, raw_data: [...] }
      if (response.containsKey('raw_data')) {
        var rawData = response['raw_data'];

        // Si raw_data es String (JSON sin parsear), parsearlo
        if (rawData is String) {
          try {
            rawData = Map.from(rawData as Map);
          } catch (e) {
            return [];
          }
        }

        if (rawData is List) {
          return rawData;
        }

        if (rawData is Map && rawData.containsKey('results')) {
          final results = rawData['results'] as List<dynamic>;
          return results;
        }
      }

      // 1b. Respuesta del ApiClient cuando decodifica listas como {data: [...]}
      if (response.containsKey('data') && response['data'] is List) {
        return response['data'] as List<dynamic>;
      }

      // 2. Paginación estándar de Django Rest Framework: { results: [...] }
      if (response.containsKey('results')) {
        final results = response['results'] as List<dynamic>;
        return results;
      }
    }

    return [];
  }
}
