// lib/apis/auth/roles_api.dart

import 'dart:developer' as developer;
import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';

/// API para gestión de roles del usuario
class RolesApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final RolesApi _instance = RolesApi._internal();
  factory RolesApi() => _instance;
  RolesApi._internal();

  final _client = ApiClient();

  void _log(String msg, {Object? error, StackTrace? stack}) {
    developer.log(msg, name: 'RolesApi', error: error, stackTrace: stack);
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN DE ROLES
  // ---------------------------------------------------------------------------

  /// Obtiene los roles disponibles para el usuario
  Future<Map<String, dynamic>> obtenerRolesDisponibles() async {
    try {
      _log('Obteniendo roles disponibles');
      return await _client.get(ApiConfig.usuariosMisRoles);
    } catch (e, stack) {
      _log('Error obteniendo roles', error: e, stack: stack);
      rethrow;
    }
  }

  /// Cambia el rol activo del usuario
  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    try {
      _log('Cambiando rol a: $nuevoRol');
      return await _client.post(ApiConfig.usuariosCambiarRolActivo, {
        'nuevo_rol': nuevoRol.toUpperCase(),
      });
    } catch (e, stack) {
      _log('Error cambiando rol', error: e, stack: stack);
      rethrow;
    }
  }
}
