// lib/services/roles/roles_service.dart
import 'dart:developer' as developer;
import '../../apis/subapis/http_client.dart';
import '../../config/network/api_config.dart';

// ============================================================================
// ROL USUARIO MODEL
// ============================================================================

class RolUsuario {
  final String nombre;
  final String estado;
  final bool activo;

  RolUsuario({
    required this.nombre,
    required this.estado,
    required this.activo,
  });

  factory RolUsuario.fromJson(Map<String, dynamic> json) => RolUsuario(
    nombre: json['nombre'] ?? '',
    estado: json['estado'] ?? 'PENDIENTE',
    activo: json['activo'] ?? false,
  );

  bool get esAceptado => estado == 'ACEPTADO';
  bool get esPendiente => estado == 'PENDIENTE';
  bool get esRechazado => estado == 'RECHAZADA';
}

// ============================================================================
// ROLES SERVICE
// ============================================================================

class RolesService {
  RolesService._();
  static final RolesService _instance = RolesService._();
  factory RolesService() => _instance;

  final _client = ApiClient();

  void _log(String msg, {Object? error, StackTrace? stack}) =>
      developer.log(msg, name: 'RolesService', error: error, stackTrace: stack);

  // --------------------------------------------------------------------------
  // Métodos Principales
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> obtenerRolesDisponibles() async {
    try {
      final response = await _client.get(ApiConfig.usuariosMisRoles);

      final rolActivoApi = (response['rol_activo'] as String?)?.toUpperCase();

      final roles = (response['roles'] as List<dynamic>? ?? [])
          .map((json) => RolUsuario.fromJson(json as Map<String, dynamic>))
          .toList();

      final disponibles = roles
          .where((r) => r.esAceptado)
          .map((r) => r.nombre)
          .toList();

      final activo =
          rolActivoApi ??
          roles
              .where((r) => r.activo && r.esAceptado)
              .map((r) => r.nombre)
              .firstOrNull;

      final result = {
        'roles': roles,
        'roles_disponibles': disponibles,
        'rol_activo': activo,
      };

      if (activo != null && activo.isNotEmpty) {
        await _client.cacheUserRole(activo);
      }

      return result;
    } catch (e, stack) {
      _log('Error obteniendo roles', error: e, stack: stack);
      rethrow;
    }
  }

  Future<List<RolUsuario>> obtenerRoles() async {
    try {
      final response = await obtenerRolesDisponibles();
      return response['roles'] as List<RolUsuario>? ?? [];
    } catch (e) {
      _log('Error obteniendo roles', error: e);
      return [];
    }
  }

  Future<List<String>> obtenerNombresRolesDisponibles() async {
    try {
      final response = await obtenerRolesDisponibles();
      return response['roles_disponibles'] as List<String>? ?? ['CLIENTE'];
    } catch (e) {
      _log('Error obteniendo nombres roles', error: e);
      return ['CLIENTE'];
    }
  }

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    try {
      _log('Cambiando rol a: $nuevoRol');

      final response = await _client.post(ApiConfig.usuariosCambiarRolActivo, {
        'nuevo_rol': nuevoRol.toUpperCase(),
      });

      if (response.containsKey('tokens')) {
        final tokens = response['tokens'];
        final rolFinal = (tokens['rol'] as String? ?? nuevoRol)
            .toString()
            .toUpperCase();

        // CORREGIDO: Eliminado el parámetro 'lifetime'
        await _client.saveTokens(
          tokens['access'],
          tokens['refresh'],
          role: rolFinal,
          userId: _client.userId,
        );
        _log('Rol cambiado, tokens actualizados. Rol final: $rolFinal');
      } else {
        await _client.cacheUserRole(nuevoRol);
        _log('Rol cambiado sin tokens, cache actualizado');
      }

      return response;
    } catch (e, stack) {
      _log('Error cambiando rol', error: e, stack: stack);
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Validaciones y Helpers
  // --------------------------------------------------------------------------

  static const _rolesValidos = [
    ApiConfig.rolUsuario,
    ApiConfig.rolProveedor,
    ApiConfig.rolRepartidor,
    ApiConfig.rolAdministrador,
  ];

  bool esRolValido(String rol) => _rolesValidos.contains(rol.toUpperCase());

  String obtenerNombreRol(String rol) => switch (rol.toUpperCase()) {
    'USUARIO' || 'CLIENTE' => 'Cliente',
    'PROVEEDOR' => 'Proveedor',
    'REPARTIDOR' => 'Repartidor',
    'ADMINISTRADOR' => 'Administrador',
    _ => rol,
  };

  Future<bool> tieneRol(String rol) async {
    try {
      final roles = await obtenerNombresRolesDisponibles();
      return roles.contains(rol.toUpperCase());
    } catch (_) {
      return false;
    }
  }

  Future<bool> puedeCambiarA(String rol) => tieneRol(rol);

  void imprimirDebugRoles() =>
      _log('Rol=${_client.userRole}, UserID=${_client.userId}');
}
