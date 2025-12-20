// lib/apis/resources/users/profile_api.dart

import '../../subapis/http_client.dart';
import '../../client/base_api.dart';
import '../../dtos/user/responses/profile_response.dart';
import '../../dtos/user/requests/update_profile_request.dart';
import '../../../config/api_config.dart';

/// API para gestionar el perfil de usuario.
///
/// Responsabilidades:
/// - Solo comunicación HTTP
/// - Serialización/deserialización de DTOs
/// - NO lógica de negocio
/// - NO cache
/// - NO validaciones de negocio
class ProfileApi extends BaseApi {
  // ========================================================================
  // SINGLETON MEJORADO CON DI OPCIONAL
  // ========================================================================

  static ProfileApi? _instance;

  factory ProfileApi({ApiClient? client}) {
    return _instance ??= ProfileApi._(client ?? ApiClient());
  }

  ProfileApi._(super.client);

  /// Reset para testing
  static void resetInstance() => _instance = null;

  // ========================================================================
  // ENDPOINTS
  // ========================================================================

  /// Obtiene el perfil del usuario autenticado.
  ///
  /// Endpoint: GET /usuarios/perfil/
  ///
  /// Returns: [ProfileResponse] con los datos del perfil
  ///
  /// Throws:
  /// - [ApiException] si hay error HTTP
  Future<ProfileResponse> getProfile() async {
    log('GET: Obtener perfil');

    try {
      final response = await client.get(ApiConfig.usuariosPerfil);

      // El backend retorna {perfil: {...}} en lugar de {...} directamente
      if (response.containsKey('perfil')) {
        return ProfileResponse.fromJson(response['perfil'] as Map<String, dynamic>);
      }

      // Fallback por si cambia la estructura
      return ProfileResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error obteniendo perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualiza el perfil del usuario.
  ///
  /// Endpoint: PATCH /usuarios/perfil/actualizar/
  ///
  /// Parámetros:
  /// - [request]: DTO con los campos a actualizar (PATCH parcial)
  ///
  /// Returns: [ProfileResponse] con el perfil actualizado
  ///
  /// Throws:
  /// - [ApiException] si hay error HTTP o validación
  Future<ProfileResponse> updateProfile(UpdateProfileRequest request) async {
    log('PATCH: Actualizar perfil');

    try {
      final response = await client.patch(
        ApiConfig.usuariosActualizarPerfil,
        request.toJson(),
      );

      // El backend retorna {perfil: {...}}
      if (response.containsKey('perfil')) {
        return ProfileResponse.fromJson(response['perfil'] as Map<String, dynamic>);
      }

      return ProfileResponse.fromJson(response);
    } catch (e, stackTrace) {
      log('Error actualizando perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene las estadísticas del usuario.
  ///
  /// Endpoint: GET /usuarios/estadisticas/
  ///
  /// Returns: Map con estadísticas (TODO: crear DTO cuando se implemente el service)
  ///
  /// Throws:
  /// - [ApiException] si hay error HTTP
  Future<Map<String, dynamic>> getStats() async {
    log('GET: Obtener estadísticas');

    try {
      return await client.get(ApiConfig.usuariosEstadisticas);
    } catch (e, stackTrace) {
      log('Error obteniendo estadísticas', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
