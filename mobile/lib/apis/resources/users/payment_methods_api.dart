// lib/apis/resources/users/payment_methods_api.dart

import 'package:mobile/services/core/api/http_client.dart';
import '../../client/base_api.dart';
import '../../../models/dto/user/responses/payment_method_response.dart';
import '../../../models/dto/user/requests/create_payment_method_request.dart';
import '../../../models/dto/user/requests/update_payment_method_request.dart';
import '../../../config/network/api_config.dart';

/// API para gestionar métodos de pago de usuario.
///
/// Responsabilidades:
/// - Solo comunicación HTTP
/// - Serialización/deserialización de DTOs
/// - NO lógica de negocio
/// - NO cache
/// - NO validaciones de negocio
class PaymentMethodsApi extends BaseApi {
  // ========================================================================
  // SINGLETON MEJORADO CON DI OPCIONAL
  // ========================================================================

  static PaymentMethodsApi? _instance;

  factory PaymentMethodsApi({ApiClient? client}) {
    return _instance ??= PaymentMethodsApi._(client ?? ApiClient());
  }

  PaymentMethodsApi._(super.client);

  static void resetInstance() => _instance = null;

  // ========================================================================
  // ENDPOINTS
  // ========================================================================

  /// Lista todos los métodos de pago del usuario.
  ///
  /// Endpoint: GET /usuarios/metodos-pago/
  Future<List<PaymentMethodResponse>> listPaymentMethods() async {
    log('GET: Listar métodos de pago');

    try {
      final response = await client.get(ApiConfig.usuariosMetodosPago);

      // El backend puede retornar {results: [...]} o {metodos_pago: [...]}
      final List<dynamic> data =
          (response['results'] as List?) ??
          (response['metodos_pago'] as List?) ??
          [];

      return data
          .map((json) => PaymentMethodResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      log('Error listando métodos de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene un método de pago específico por ID.
  ///
  /// Endpoint: GET /usuarios/metodos-pago/{id}/
  Future<PaymentMethodResponse> getPaymentMethod(String id) async {
    log('GET: Obtener método de pago $id');

    try {
      final endpoint = ApiConfig.usuariosMetodoPago(id);
      final response = await client.get(endpoint);

      // El backend puede retornar {metodo_pago: {...}} o {...} directamente
      if (response.containsKey('metodo_pago')) {
        return PaymentMethodResponse.fromJson(
            response['metodo_pago'] as Map<String, dynamic>);
      }

      return PaymentMethodResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error obteniendo método de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Crea un nuevo método de pago.
  ///
  /// Endpoint: POST /usuarios/metodos-pago/
  Future<PaymentMethodResponse> createPaymentMethod(
      CreatePaymentMethodRequest request) async {
    log('POST: Crear método de pago');

    try {
      final response = await client.post(
        ApiConfig.usuariosMetodosPago,
        request.toJson(),
      );

      // El backend retorna {metodo_pago: {...}}
      if (response.containsKey('metodo_pago')) {
        return PaymentMethodResponse.fromJson(
            response['metodo_pago'] as Map<String, dynamic>);
      }

      return PaymentMethodResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error creando método de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualiza un método de pago existente.
  ///
  /// Endpoint: PATCH /usuarios/metodos-pago/{id}/
  Future<PaymentMethodResponse> updatePaymentMethod(
    String id,
    UpdatePaymentMethodRequest request,
  ) async {
    log('PATCH: Actualizar método de pago $id');

    try {
      final endpoint = ApiConfig.usuariosMetodoPago(id);
      final response = await client.patch(endpoint, request.toJson());

      if (response.containsKey('metodo_pago')) {
        return PaymentMethodResponse.fromJson(
            response['metodo_pago'] as Map<String, dynamic>);
      }

      return PaymentMethodResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error actualizando método de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Elimina un método de pago.
  ///
  /// Endpoint: DELETE /usuarios/metodos-pago/{id}/
  Future<void> deletePaymentMethod(String id) async {
    log('DELETE: Eliminar método de pago $id');

    try {
      final endpoint = ApiConfig.usuariosMetodoPago(id);
      await client.delete(endpoint);
    } catch (e, stackTrace) {
      log('Error eliminando método de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene el método de pago predeterminado del usuario.
  ///
  /// Endpoint: GET /usuarios/metodos-pago/predeterminado/
  Future<PaymentMethodResponse?> getDefaultPaymentMethod() async {
    log('GET: Obtener método de pago predeterminado');

    try {
      final response = await client.get(ApiConfig.usuariosMetodoPagoPredeterminado);

      if (response.isEmpty || response['metodo_pago'] == null) {
        return null;
      }

      if (response.containsKey('metodo_pago')) {
        return PaymentMethodResponse.fromJson(
            response['metodo_pago'] as Map<String, dynamic>);
      }

      return PaymentMethodResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error obteniendo método de pago predeterminado',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
