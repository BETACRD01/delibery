// lib/services/productos_service.dart

import 'dart:convert';
import '../config/api_config.dart';
import '../apis/subapis/http_client.dart';
import '../models/producto_model.dart';
import '../models/categoria_model.dart';
import '../models/promocion_model.dart';

/// Servicio para gestionar productos, categorías y promociones
class ProductosService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------
  static final ProductosService _instance = ProductosService._internal();
  factory ProductosService() => _instance;
  ProductosService._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // CATEGORÍAS
  // ---------------------------------------------------------------------------

  Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final response = await _client.get(ApiConfig.productosCategorias);
      final List<dynamic> data = _extraerLista(response);

      return data.map((json) => CategoriaModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<CategoriaModel> obtenerCategoria(String categoriaId) async {
    try {
      final url = '${ApiConfig.productosCategorias}$categoriaId/';
      final response = await _client.get(url);
      return CategoriaModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PRODUCTOS (Lógica Principal)
  // ---------------------------------------------------------------------------

  /// Obtiene todos los productos disponibles con filtros
  Future<List<ProductoModel>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
  }) async {
    try {
      String url = ApiConfig.productosLista;

      final List<String> params = [];

      if (categoriaId != null) params.add('categoria_id=$categoriaId');
      if (proveedorId != null) params.add('proveedor_id=$proveedorId');
      if (soloOfertas) params.add('solo_ofertas=true');

      if (busqueda != null && busqueda.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(busqueda)}');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await _client.get(url);
      final List<dynamic> data = _extraerLista(response);

      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // MÉTODOS DE CONVENIENCIA
  // ---------------------------------------------------------------------------

  Future<List<ProductoModel>> obtenerProductosPorCategoria(String categoriaId) async {
    return obtenerProductos(categoriaId: categoriaId);
  }

  Future<List<ProductoModel>> obtenerProductosPorProveedor(String proveedorId) async {
    return obtenerProductos(proveedorId: proveedorId);
  }

  /// Obtiene solo productos en oferta
  Future<List<ProductoModel>> obtenerProductosEnOferta({bool random = false}) async {
    try {
      String url = '${ApiConfig.productosLista}ofertas/';
      if (random) {
        url += '?random=true';
      }
      final response = await _client.get(url);
      final List<dynamic> data = _extraerLista(response);

      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ProductoModel>> obtenerProductosDestacados() async {
    try {
      final response = await _client.get(ApiConfig.productosDestacados);
      final List<dynamic> data = _extraerLista(response);

      return data.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ProductoModel> obtenerProducto(String productoId) async {
    try {
      final response = await _client.get(ApiConfig.productoDetalle(int.parse(productoId)));

      return ProductoModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PROMOCIONES / BANNERS
  // ---------------------------------------------------------------------------

  Future<List<PromocionModel>> obtenerPromociones() async {
    try {
      final url = ApiConfig.productosPromociones;
      final response = await _client.get(url);
      final List<dynamic> data = _extraerLista(response);

      return data.map((json) => PromocionModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Promociones filtradas por proveedor
  Future<List<PromocionModel>> obtenerPromocionesPorProveedor(String proveedorId) async {
    try {
      final url = '${ApiConfig.productosPromociones}?proveedor_id=$proveedorId';
      final response = await _client.get(url);
      final List<dynamic> data = _extraerLista(response);
      return data.map((json) => PromocionModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  /// Obtiene productos novedades (recién agregados)
  /// GET /api/productos/productos/novedades/
  Future<List<ProductoModel>> obtenerProductosNovedades({bool random = false}) async {
    try {
      String url = '${ApiConfig.productosLista}novedades/';
      if (random) {
        url += '?random=true';
      }
      final response = await _client.get(url);
      final lista = _extraerLista(response);
      return lista.map((json) => ProductoModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene productos más populares (más vendidos o mejor rating)
  /// GET /api/productos/productos/mas-populares/
  Future<List<ProductoModel>> obtenerProductosMasPopulares({bool random = false}) async {
    try {
      String url = '${ApiConfig.productosLista}mas-populares/';
      if (random) {
        url += '?random=true';
      }
      final response = await _client.get(url);
      final lista = _extraerLista(response);
      final productos = lista.map((json) => ProductoModel.fromJson(json)).toList();
      return productos;
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER PRIVADO (Excelente práctica para DRF)
  // ---------------------------------------------------------------------------

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
            rawData = jsonDecode(rawData);
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
