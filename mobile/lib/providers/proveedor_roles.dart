// lib/providers/proveedor_roles.dart
import 'package:flutter/material.dart';
import '../services/roles_service.dart';
import '../services/auth_service.dart';

// ============================================================================
// PROVEEDOR ROLES
// ============================================================================

class ProveedorRoles extends ChangeNotifier {
  // --------------------------------------------------------------------------
  // Estado
  // --------------------------------------------------------------------------

  List<String> _rolesDisponibles = [];
  String? _rolActivo;
  bool _isLoading = false;
  String? _error;

  final _rolesService = RolesService();
  final _authService = AuthService();

  // --------------------------------------------------------------------------
  // Getters
  // --------------------------------------------------------------------------

  List<String> get rolesDisponibles => _rolesDisponibles;
  String? get rolActivo => _rolActivo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get tieneMultiplesRoles => _rolesDisponibles.length > 1;
  bool get puedeCambiarRol => tieneMultiplesRoles && !_isLoading;

  List<String> get rolesParaCambiar => _rolActivo == null
      ? []
      : _rolesDisponibles.where((r) => r != _rolActivo).toList();

  // --------------------------------------------------------------------------
  // Inicializacion
  // --------------------------------------------------------------------------

  Future<void> inicializar() async {
    debugPrint('Inicializando ProveedorRoles...');
    _rolActivo = _authService.getRolCacheado();
    debugPrint('Rol cacheado: $_rolActivo');
    await cargarRoles();
  }

  Future<void> cargarRoles() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Cargando roles...');

      final response = await _rolesService.obtenerRolesDisponibles();
      _rolesDisponibles = List<String>.from(
        response['roles_disponibles'] ?? [],
      );
      _rolActivo = response['rol_activo'] as String?;

      debugPrint('Roles: $_rolesDisponibles | Activo: $_rolActivo');
      _error = null;
    } catch (e) {
      debugPrint('Error cargando roles: $e');
      _error = 'Error al cargar roles: $e';

      if (_rolActivo == null) {
        _rolActivo = _authService.getRolCacheado();
        if (_rolActivo != null) {
          _rolesDisponibles = [_rolActivo!];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // Cambio de Rol
  // --------------------------------------------------------------------------

  Future<bool> cambiarARol(String nuevoRol) async {
    if (_isLoading) {
      debugPrint('Cambio de rol en progreso');
      return false;
    }

    if (nuevoRol == _rolActivo) {
      debugPrint('Rol $nuevoRol ya activo');
      return false;
    }

    if (!_rolesDisponibles.contains(nuevoRol)) {
      debugPrint('Rol $nuevoRol no disponible');
      _error = 'Rol $nuevoRol no disponible';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Cambiando rol: $_rolActivo -> $nuevoRol');

      await _rolesService.cambiarRolActivo(nuevoRol);
      _rolActivo = nuevoRol;

      debugPrint('Rol cambiado a: $nuevoRol');
      _error = null;
      return true;
    } catch (e) {
      debugPrint('Error cambiando rol: $e');
      _error = 'Error al cambiar rol: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // Helpers UI
  // --------------------------------------------------------------------------

  String obtenerNombreRol(String rol) => _rolesService.obtenerNombreRol(rol);
  bool esRolActivo(String rol) => rol == _rolActivo;

  // --------------------------------------------------------------------------
  // Limpieza
  // --------------------------------------------------------------------------

  void limpiar() {
    _rolesDisponibles = [];
    _rolActivo = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
    debugPrint('ProveedorRoles limpiado');
  }
}
