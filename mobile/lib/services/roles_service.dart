// lib/services/roles_service.dart

import '../apis/subapis/http_client.dart';
import '../config/api_config.dart';
import 'dart:developer' as developer;

/// Modelo para representar un rol del usuario
class RolUsuario {
  final String nombre;
  final String estado;
  final bool activo;

  RolUsuario({
    required this.nombre,
    required this.estado,
    required this.activo,
  });

  factory RolUsuario.fromJson(Map<String, dynamic> json) {
    return RolUsuario(
      nombre: json['nombre'] ?? '',
      estado: json['estado'] ?? 'PENDIENTE',
      activo: json['activo'] ?? false,
    );
  }

  bool get esAceptado => estado == 'ACEPTADO';
  bool get esPendiente => estado == 'PENDIENTE';
  bool get esRechazado => estado == 'RECHAZADA';
}

/// Servicio para la gestión de roles múltiples del usuario.
/// Permite consultar roles disponibles y cambiar el rol activo.
class RolesService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------
  
  static final RolesService _instance = RolesService._internal();
  factory RolesService() => _instance;
  RolesService._internal();

  final _client = ApiClient();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message, 
      name: 'RolesService', 
      error: error, 
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // MÉTODOS PRINCIPALES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> obtenerRolesDisponibles() async {
    try {
      final response = await _client.get(ApiConfig.usuariosMisRoles);
      
      // Parsear la lista de roles
      final List<dynamic> rolesJson = response['roles'] ?? [];
      final List<RolUsuario> roles = rolesJson
          .map((json) => RolUsuario.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Extraer roles disponibles (los que están ACEPTADOS)
      final List<String> rolesDisponibles = roles
          .where((r) => r.esAceptado)
          .map((r) => r.nombre)
          .toList();
      
      // Determinar el rol activo (el que tiene activo=true y está ACEPTADO)
      final rolActivo = roles
          .where((r) => r.activo && r.esAceptado)
          .map((r) => r.nombre)
          .firstOrNull;
      
      return {
        'roles': roles,
        'roles_disponibles': rolesDisponibles,
        'rol_activo': rolActivo,
      };
    } catch (e, stackTrace) {
      _log('Error obteniendo roles', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene solo la lista de roles como objetos RolUsuario
  Future<List<RolUsuario>> obtenerRoles() async {
    try {
      final response = await obtenerRolesDisponibles();
      return response['roles'] as List<RolUsuario>? ?? [];
    } catch (e) {
      _log('Error obteniendo lista de roles (silencioso)', error: e);
      return [];
    }
  }

  /// Obtiene los nombres de los roles aceptados/disponibles
  Future<List<String>> obtenerNombresRolesDisponibles() async {
    try {
      final response = await obtenerRolesDisponibles();
      return response['roles_disponibles'] as List<String>? ?? ['CLIENTE'];
    } catch (e) {
      _log('Error obteniendo nombres de roles (silencioso)', error: e);
      // Fallback seguro: el usuario siempre es al menos Cliente
      return ['CLIENTE'];
    }
  }

  /// Cambia el rol activo del usuario.
  /// Actualiza automáticamente los tokens de sesión.
  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    try {
      _log('Solicitando cambio de rol a: $nuevoRol');

      final response = await _client.post(ApiConfig.usuariosCambiarRolActivo, {
        'nuevo_rol': nuevoRol.toUpperCase(),
      });

      // Si la respuesta incluye nuevos tokens, actualizarlos
      if (response.containsKey('tokens')) {
        final tokens = response['tokens'];
        
        await _client.saveTokens(
          tokens['access'],
          tokens['refresh'],
          role: tokens['rol'] as String?,
          userId: _client.userId,
          tokenLifetime: const Duration(hours: 12),
        );

        _log('Rol cambiado exitosamente. Nuevos tokens guardados.');
      }

      return response;
    } catch (e, stackTrace) {
      _log('Error cambiando rol', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES Y HELPERS
  // ---------------------------------------------------------------------------

  /// Verifica si un string corresponde a un rol válido del sistema.
  bool esRolValido(String rol) {
    final rolesValidos = [
      ApiConfig.rolUsuario,
      ApiConfig.rolProveedor,
      ApiConfig.rolRepartidor,
      ApiConfig.rolAdministrador,
    ];
    return rolesValidos.contains(rol.toUpperCase());
  }

  /// Obtiene el nombre legible para mostrar en UI.
  String obtenerNombreRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'USUARIO':
      case 'CLIENTE':
        return 'Cliente';
      case 'PROVEEDOR':
        return 'Proveedor';
      case 'REPARTIDOR':
        return 'Repartidor';
      case 'ADMINISTRADOR':
        return 'Administrador';
      default:
        return rol;
    }
  }

  /// Obtiene el ícono representativo del rol para UI.
  String obtenerIconoRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'USUARIO':
      case 'CLIENTE':
        return '👤';
      case 'PROVEEDOR':
        return '🏪';
      case 'REPARTIDOR':
        return '🛵';
      case 'ADMINISTRADOR':
        return '👑';
      default:
        return '❓';
    }
  }

  /// Verifica si el usuario tiene un rol específico aceptado
  Future<bool> tieneRol(String rol) async {
    try {
      final roles = await obtenerNombresRolesDisponibles();
      return roles.contains(rol.toUpperCase());
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario puede cambiar a un rol específico
  Future<bool> puedeCambiarA(String rol) async {
    return await tieneRol(rol);
  }

  // ---------------------------------------------------------------------------
  // DEBUG
  // ---------------------------------------------------------------------------

  void imprimirDebugRoles() {
    _log('Estado actual: Rol=${_client.userRole}, UserID=${_client.userId}');
  }
}