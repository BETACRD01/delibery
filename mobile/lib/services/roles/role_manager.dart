// lib/services/roles/role_manager.dart
// Sistema centralizado y unificado de gestión de roles
// Reemplaza ProveedorRoles y RoleController para eliminar duplicación

import 'package:flutter/foundation.dart';
import '../../switch/roles.dart';
import '../../switch/role_storage.dart';
import 'roles_service.dart';
import '../../apis/subapis/http_client.dart';

// Importar RolUsuario para type checking
export 'roles_service.dart' show RolUsuario;

/// Estados posibles de un rol
enum RoleStatus {
  active, // Rol activo actualmente
  approved, // Aprobado pero no activo
  pending, // Solicitud en revisión
  rejected, // Solicitud rechazada
  notRequested, // No se ha solicitado
}

/// Información completa de un rol
class RoleInfo {
  final AppRole role;
  final RoleStatus status;
  final String displayName;
  final String? rejectionReason;
  final DateTime? statusDate;

  const RoleInfo({
    required this.role,
    required this.status,
    required this.displayName,
    this.rejectionReason,
    this.statusDate,
  });

  bool get canActivate =>
      status == RoleStatus.approved || status == RoleStatus.active;
  bool get isActive => status == RoleStatus.active;
  bool get isPending => status == RoleStatus.pending;
  bool get isRejected => status == RoleStatus.rejected;
  bool get notRequested => status == RoleStatus.notRequested;

  RoleInfo copyWith({
    AppRole? role,
    RoleStatus? status,
    String? displayName,
    String? rejectionReason,
    DateTime? statusDate,
  }) {
    return RoleInfo(
      role: role ?? this.role,
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      statusDate: statusDate ?? this.statusDate,
    );
  }
}

/// Gestor central y unificado de roles
/// Fuente única de verdad para el estado de roles en toda la app
class RoleManager extends ChangeNotifier {
  // Singleton pattern
  static final RoleManager _instance = RoleManager._internal();
  factory RoleManager() => _instance;
  RoleManager._internal();

  // Servicios
  final _rolesService = RolesService();
  final _roleStorage = RoleStorage();
  final _apiClient = ApiClient();

  // Estado
  AppRole _activeRole = AppRole.user;
  final Map<AppRole, RoleInfo> _roles = {};
  bool _isLoading = false;
  bool _isChangingRole = false;
  String? _error;
  DateTime? _lastSync;
  Future<void>? _initFuture;

  // Getters
  AppRole get activeRole => _activeRole;
  RoleInfo? getRoleInfo(AppRole role) => _roles[role];
  List<RoleInfo> get allRoles => _roles.values.toList();
  List<RoleInfo> get approvedRoles =>
      _roles.values.where((r) => r.canActivate).toList();
  bool get isLoading => _isLoading;
  bool get isChangingRole => _isChangingRole;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  bool get needsSync =>
      _lastSync == null || DateTime.now().difference(_lastSync!).inMinutes > 5;

  /// Inicializa el gestor de roles
  /// Debe llamarse al inicio de la app
  Future<void> initialize() async {
    if (_isLoading && _initFuture != null) {
      return _initFuture!;
    }
    if (_lastSync != null && !needsSync) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    _initFuture = _initializeInternal();
    return _initFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      // 1. Cargar rol activo del caché local
      final cachedRole = await _roleStorage.getRole();
      if (cachedRole != null) {
        _activeRole = cachedRole;
      }

      // 2. Sincronizar con el servidor
      await _syncWithServer();
    } catch (e) {
      _error = 'Error al inicializar roles: $e';

      // Fallback: usar rol del caché aunque haya error de red
      debugPrint('RoleManager: Error en inicialización, usando caché local');
    } finally {
      _isLoading = false;
      _initFuture = null;
      notifyListeners();
    }
  }

  /// Sincroniza el estado de roles con el servidor
  Future<void> _syncWithServer() async {
    try {
      final response = await _rolesService.obtenerRolesDisponibles();

      // Actualizar rol activo desde el servidor
      final activeRoleStr = response['rol_activo']?.toString().toUpperCase();
      if (activeRoleStr != null) {
        final serverRole = parseRole(activeRoleStr);
        if (serverRole != _activeRole) {
          _activeRole = serverRole;
          await _roleStorage.setRole(_activeRole);
          await _apiClient.cacheUserRole(roleToApi(_activeRole));
        }
      }

      // Actualizar estado de todos los roles
      _updateRolesFromResponse(response);

      _lastSync = DateTime.now();
      _error = null;
    } catch (e) {
      debugPrint('RoleManager: Error sincronizando con servidor: $e');
      rethrow;
    }
  }

  /// Actualiza el mapa de roles desde la respuesta del servidor
  void _updateRolesFromResponse(Map<String, dynamic> response) {
    final activeRoleStr = response['rol_activo']?.toString().toUpperCase();
    final rolesData = response['roles'] as List?;

    // Inicializar todos los roles como no solicitados
    _roles.clear();
    for (final role in AppRole.values) {
      _roles[role] = RoleInfo(
        role: role,
        status: RoleStatus.notRequested,
        displayName: roleToDisplay(role),
      );
    }

    // Actualizar con datos del servidor
    if (rolesData != null) {
      for (final roleData in rolesData) {
        // Extraer nombre y estado dependiendo del tipo de dato
        String roleName;
        String? estado;

        if (roleData is RolUsuario) {
          // roleData es una instancia de RolUsuario
          roleName = roleData.nombre.toUpperCase();
          estado = roleData.estado;
        } else if (roleData is Map) {
          // roleData es un Map (fallback para compatibilidad)
          roleName =
              roleData['nombre']?.toString().toUpperCase() ??
              roleData.toString().toUpperCase();
          estado = roleData['estado']?.toString();
        } else {
          // Fallback: convertir a string
          roleName = roleData.toString().toUpperCase();
          estado = null;
        }

        final role = parseRole(roleName);

        // Determinar estado del rol
        RoleStatus status;
        final isActive = roleName == activeRoleStr;

        if (isActive) {
          status = RoleStatus.active;
        } else if (estado == 'ACEPTADO' || estado == 'APPROVED') {
          status = RoleStatus.approved;
        } else if (estado == 'PENDIENTE' || estado == 'PENDING') {
          status = RoleStatus.pending;
        } else if (estado == 'RECHAZADO' || estado == 'REJECTED') {
          status = RoleStatus.rejected;
        } else {
          status = RoleStatus.approved; // Asumimos aprobado si está en la lista
        }

        _roles[role] = RoleInfo(
          role: role,
          status: status,
          displayName: roleToDisplay(role),
        );
      }
    }

    // El rol de usuario siempre está aprobado
    _roles[AppRole.user] = RoleInfo(
      role: AppRole.user,
      status: _activeRole == AppRole.user
          ? RoleStatus.active
          : RoleStatus.approved,
      displayName: roleToDisplay(AppRole.user),
    );
  }

  /// Cambia el rol activo de forma atómica
  /// Retorna true si el cambio fue exitoso
  Future<bool> switchRole(AppRole newRole) async {
    if (_isChangingRole) {
      debugPrint('RoleManager: Cambio de rol ya en progreso');
      return false;
    }

    if (newRole == _activeRole) {
      debugPrint('RoleManager: Ya estás en el rol ${roleToDisplay(newRole)}');
      return true; // No es error, simplemente ya está activo
    }

    // Validar que el rol esté aprobado
    final roleInfo = _roles[newRole];
    if (roleInfo == null || !roleInfo.canActivate) {
      _error = 'No tienes acceso al rol ${roleToDisplay(newRole)}';
      notifyListeners();
      return false;
    }

    _isChangingRole = true;
    _error = null;
    notifyListeners();

    // Guardar rol anterior para rollback
    final previousRole = _activeRole;

    try {
      debugPrint(
        'RoleManager: Cambiando rol de ${roleToDisplay(previousRole)} a ${roleToDisplay(newRole)}',
      );

      // 1. Cambiar rol en el servidor
      final response = await _rolesService.cambiarRolActivo(roleToApi(newRole));

      // 2. Actualizar tokens si el servidor los devuelve
      if (response.containsKey('access') && response.containsKey('refresh')) {
        await _apiClient.saveTokens(
          response['access'],
          response['refresh'],
          role: roleToApi(newRole),
        );
      } else {
        // Solo actualizar caché del rol
        await _apiClient.cacheUserRole(roleToApi(newRole));
      }

      // 3. Actualizar almacenamiento seguro
      await _roleStorage.setRole(newRole);

      // 4. Actualizar estado local
      final oldActiveRole = _activeRole;
      _activeRole = newRole;

      // Actualizar estados de roles
      if (_roles[oldActiveRole] != null) {
        _roles[oldActiveRole] = _roles[oldActiveRole]!.copyWith(
          status: RoleStatus.approved,
        );
      }
      if (_roles[newRole] != null) {
        _roles[newRole] = _roles[newRole]!.copyWith(status: RoleStatus.active);
      }

      _lastSync = DateTime.now();
      _isChangingRole = false;
      notifyListeners();

      debugPrint('RoleManager: Cambio de rol exitoso');
      return true;
    } catch (e) {
      debugPrint('RoleManager: Error cambiando rol: $e');

      // Rollback: restaurar rol anterior
      _activeRole = previousRole;
      _error = 'Error al cambiar de rol: $e';
      _isChangingRole = false;
      notifyListeners();

      return false;
    }
  }

  /// Recarga el estado de roles desde el servidor
  Future<void> refresh() async {
    if (_isLoading) {
      if (_initFuture != null) {
        await _initFuture!;
      }
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _syncWithServer();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar roles: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el error actual
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cierra sesión y limpia todos los datos
  Future<void> logout() async {
    _activeRole = AppRole.user;
    _roles.clear();
    _lastSync = null;
    _error = null;
    _initFuture = null;
    await _roleStorage.clearRole();
    notifyListeners();
  }

  /// Verifica si un rol requiere aprobación
  bool requiresApproval(AppRole role) {
    return role == AppRole.provider || role == AppRole.courier;
  }

  /// Obtiene el mensaje de estado para un rol
  String getStatusMessage(AppRole role) {
    final roleInfo = _roles[role];
    if (roleInfo == null) return 'Estado desconocido';

    switch (roleInfo.status) {
      case RoleStatus.active:
        return 'Rol actual';
      case RoleStatus.approved:
        return 'Disponible';
      case RoleStatus.pending:
        return 'Solicitud en revisión';
      case RoleStatus.rejected:
        return roleInfo.rejectionReason ?? 'Solicitud rechazada';
      case RoleStatus.notRequested:
        return 'No solicitado';
    }
  }
}
