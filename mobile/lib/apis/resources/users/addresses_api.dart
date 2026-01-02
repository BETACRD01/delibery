// lib/apis/resources/users/addresses_api.dart

import '../../subapis/http_client.dart';
import '../../client/base_api.dart';
import '../../dtos/user/responses/address_response.dart';
import '../../dtos/user/requests/create_address_request.dart';
import '../../dtos/user/requests/update_address_request.dart';
import '../../../config/network/api_config.dart';

/// API para gestionar direcciones de usuario.
///
/// Responsabilidades:
/// - Solo comunicación HTTP
/// - Serialización/deserialización de DTOs
/// - NO lógica de negocio
/// - NO cache
/// - NO validaciones de negocio
class AddressesApi extends BaseApi {
  // ========================================================================
  // SINGLETON MEJORADO CON DI OPCIONAL
  // ========================================================================

  static AddressesApi? _instance;

  factory AddressesApi({ApiClient? client}) {
    return _instance ??= AddressesApi._(client ?? ApiClient());
  }

  AddressesApi._(super.client);

  static void resetInstance() => _instance = null;

  // ========================================================================
  // ENDPOINTS
  // ========================================================================

  /// Lista todas las direcciones del usuario.
  ///
  /// Endpoint: GET /usuarios/direcciones/
  Future<List<AddressResponse>> listAddresses() async {
    log('GET: Listar direcciones');

    try {
      final response = await client.get(ApiConfig.usuariosDirecciones);

      // El backend puede retornar {results: [...]} o {direcciones: [...]}
      final List<dynamic> data =
          (response['results'] as List?) ??
          (response['direcciones'] as List?) ??
          [];

      return data
          .map((json) => AddressResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      log('Error listando direcciones', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene una dirección específica por ID.
  ///
  /// Endpoint: GET /usuarios/direcciones/{id}/
  Future<AddressResponse> getAddress(String id) async {
    log('GET: Obtener dirección $id');

    try {
      final endpoint = ApiConfig.usuariosDireccion(id);
      final response = await client.get(endpoint);

      // El backend puede retornar {direccion: {...}} o {...} directamente
      if (response.containsKey('direccion')) {
        return AddressResponse.fromJson(response['direccion'] as Map<String, dynamic>);
      }

      return AddressResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error obteniendo dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Crea una nueva dirección.
  ///
  /// Endpoint: POST /usuarios/direcciones/
  Future<AddressResponse> createAddress(CreateAddressRequest request) async {
    log('POST: Crear dirección');

    try {
      final response = await client.post(
        ApiConfig.usuariosDirecciones,
        request.toJson(),
      );

      // El backend retorna {direccion: {...}}
      if (response.containsKey('direccion')) {
        return AddressResponse.fromJson(response['direccion'] as Map<String, dynamic>);
      }

      return AddressResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error creando dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualiza una dirección existente.
  ///
  /// Endpoint: PATCH /usuarios/direcciones/{id}/
  Future<AddressResponse> updateAddress(
    String id,
    UpdateAddressRequest request,
  ) async {
    log('PATCH: Actualizar dirección $id');

    try {
      final endpoint = ApiConfig.usuariosDireccion(id);
      final response = await client.patch(endpoint, request.toJson());

      if (response.containsKey('direccion')) {
        return AddressResponse.fromJson(response['direccion'] as Map<String, dynamic>);
      }

      return AddressResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error actualizando dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Elimina una dirección.
  ///
  /// Endpoint: DELETE /usuarios/direcciones/{id}/
  Future<void> deleteAddress(String id) async {
    log('DELETE: Eliminar dirección $id');

    try {
      final endpoint = ApiConfig.usuariosDireccion(id);
      await client.delete(endpoint);
    } catch (e, stackTrace) {
      log('Error eliminando dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene la dirección predeterminada del usuario.
  ///
  /// Endpoint: GET /usuarios/direcciones/predeterminada/
  Future<AddressResponse?> getDefaultAddress() async {
    log('GET: Obtener dirección predeterminada');

    try {
      final response = await client.get(ApiConfig.usuariosDireccionPredeterminada);

      if (response.isEmpty || response['direccion'] == null) {
        return null;
      }

      if (response.containsKey('direccion')) {
        return AddressResponse.fromJson(response['direccion'] as Map<String, dynamic>);
      }

      return AddressResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error obteniendo dirección predeterminada', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
