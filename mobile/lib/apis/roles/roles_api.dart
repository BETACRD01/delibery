// lib/apis/roles/roles_api.dart

import '../../config/network/api_config.dart';
import 'package:mobile/services/core/api/http_client.dart';

/// API para gestión de roles de usuario
class RolesApi {
  static final RolesApi _instance = RolesApi._internal();
  factory RolesApi() => _instance;
  RolesApi._internal();

  final _client = ApiClient();

  ApiClient get client => _client;

  /// Obtiene los roles del usuario
  Future<Map<String, dynamic>> getMisRoles() async {
    return await _client.get(ApiConfig.usuariosMisRoles);
  }

  /// Cambia el rol activo
  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    return await _client.post(ApiConfig.usuariosCambiarRolActivo, {
      'nuevo_rol': nuevoRol.toUpperCase(),
    });
  }

  /// Guarda tokens después de cambiar rol
  Future<void> guardarTokens(
    String access,
    String refresh,
    String rol,
    int? userId,
  ) async {
    await _client.saveTokens(access, refresh, role: rol, userId: userId);
  }

  /// Cachea el rol del usuario
  Future<void> cacheRol(String rol) async {
    await _client.cacheUserRole(rol);
  }
}
