// lib/services/carrito/carrito_service.dart

import '../../config/api_config.dart';
import '../../apis/subapis/http_client.dart';
import '../../apis/helpers/api_exception.dart';

/// Servicio para gestionar el carrito de compras
class CarritoService {
  // ════════════════════════════════════════════════════════════════
  // SINGLETON
  // ════════════════════════════════════════════════════════════════
  static final CarritoService _instance = CarritoService._internal();
  factory CarritoService() => _instance;
  CarritoService._internal();

  // ════════════════════════════════════════════════════════════════
  // CLIENTE HTTP
  // ════════════════════════════════════════════════════════════════
  final _client = ApiClient();

  // ════════════════════════════════════════════════════════════════
  // MÉTODOS DEL CARRITO
  // ════════════════════════════════════════════════════════════════

  /// Obtiene el carrito del usuario autenticado
  Future<Map<String, dynamic>> obtenerCarrito() async {
    try {
      final response = await _client.get(
        '${ApiConfig.apiUrl}/productos/carrito/',
      );
      
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener carrito',
        errors: {'error': e.toString()},
      );
    }
  }

  /// Agrega un producto al carrito
  Future<Map<String, dynamic>> agregarAlCarrito({
    required String productoId,
    int cantidad = 1,
  }) async {
    try {
      final response = await _client.post(
        '${ApiConfig.apiUrl}/productos/carrito/agregar/',
        {
          'producto_id': int.parse(productoId),
          'cantidad': cantidad,
        },
      );
      
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error al agregar producto al carrito',
        errors: {'error': e.toString()},
      );
    }
  }

  /// Actualiza la cantidad de un item en el carrito
  Future<Map<String, dynamic>> actualizarCantidad({
    required String itemId,
    required int cantidad,
  }) async {
    try {
      final response = await _client.put(
        '${ApiConfig.apiUrl}/productos/carrito/item/$itemId/cantidad/',
        {
          'cantidad': cantidad,
        },
      );
      
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error al actualizar cantidad',
        errors: {'error': e.toString()},
      );
    }
  }

  /// Remueve un item del carrito
  Future<Map<String, dynamic>> removerDelCarrito(String itemId) async {
    try {
      final response = await _client.delete(
        '${ApiConfig.apiUrl}/productos/carrito/item/$itemId/',
      );
      
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error al remover item del carrito',
        errors: {'error': e.toString()},
      );
    }
  }

  /// Limpia todo el carrito
  Future<Map<String, dynamic>> limpiarCarrito() async {
    try {
      final response = await _client.delete(
        '${ApiConfig.apiUrl}/productos/carrito/limpiar/',
      );
      
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error al limpiar carrito',
        errors: {'error': e.toString()},
      );
    }
  }

  /// Realiza el checkout del carrito
  Future<Map<String, dynamic>> checkout({
    required String direccionEntrega,
    double? latitudDestino,
    double? longitudDestino,
    String metodoPago = 'efectivo',
    Map<String, dynamic>? datosEnvio,
    String? direccionId,
    String? instruccionesEntrega,
  }) async {
    try {
      final body = <String, dynamic>{
        'direccion_entrega': direccionEntrega,
        'metodo_pago': metodoPago,
      };
      if (latitudDestino != null) body['latitud_destino'] = latitudDestino;
      if (longitudDestino != null) body['longitud_destino'] = longitudDestino;
      if (datosEnvio != null) body['datos_envio'] = datosEnvio;
      if (direccionId != null) body['direccion_id'] = direccionId;
      if (instruccionesEntrega != null && instruccionesEntrega.isNotEmpty) {
        body['instrucciones_entrega'] = instruccionesEntrega;
      }

      final response = await _client.post(ApiConfig.carritoCheckout, body);

      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error al procesar checkout',
        errors: {'error': e.toString()},
      );
    }
  }
}
