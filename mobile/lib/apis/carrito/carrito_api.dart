// lib/apis/carrito/carrito_api.dart

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión del carrito de compras
class CarritoApi {
  static final CarritoApi _instance = CarritoApi._internal();
  factory CarritoApi() => _instance;
  CarritoApi._internal();

  final _client = ApiClient();

  /// Obtiene el carrito del usuario
  Future<Map<String, dynamic>> getCarrito() async {
    return await _client.get('${ApiConfig.apiUrl}/productos/carrito/');
  }

  /// Agrega un producto al carrito
  Future<Map<String, dynamic>> agregarProducto(
    int productoId,
    int cantidad,
  ) async {
    return await _client.post(
      '${ApiConfig.apiUrl}/productos/carrito/agregar/',
      {'producto_id': productoId, 'cantidad': cantidad},
    );
  }

  /// Actualiza la cantidad de un item
  Future<Map<String, dynamic>> actualizarCantidad(
    String itemId,
    int cantidad,
  ) async {
    return await _client.put(
      '${ApiConfig.apiUrl}/productos/carrito/item/$itemId/cantidad/',
      {'cantidad': cantidad},
    );
  }

  /// Remueve un item del carrito
  Future<Map<String, dynamic>> removerItem(String itemId) async {
    return await _client.delete(
      '${ApiConfig.apiUrl}/productos/carrito/item/$itemId/',
    );
  }

  /// Limpia todo el carrito
  Future<Map<String, dynamic>> limpiarCarrito() async {
    return await _client.delete(
      '${ApiConfig.apiUrl}/productos/carrito/limpiar/',
    );
  }

  /// Realiza el checkout
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.carritoCheckout, data);
  }
}
