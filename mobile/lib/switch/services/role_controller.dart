// lib/role_switch/services/role_controller.dart

import 'package:flutter/foundation.dart';
import '../../apis/subapis/http_client.dart';
import '../../services/roles/roles_service.dart';
import '../models/roles.dart';
import 'role_storage.dart';

class RoleController extends ChangeNotifier {
  RoleController({
    RolesService? rolesService,
    RoleStorage? storage,
    ApiClient? apiClient,
  }) : _rolesService = rolesService ?? RolesService(),
       _storage = storage ?? RoleStorage(),
       _apiClient = apiClient ?? ApiClient();

  final RolesService _rolesService;
  final RoleStorage _storage;
  final ApiClient _apiClient;

  AppRole _currentRole = AppRole.user;
  bool _loading = false;
  String? _error;

  AppRole get currentRole => _currentRole;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> initRole() async {
    _loading = true;
    notifyListeners();
    try {
      final cacheClient = _apiClient.userRole;
      if (cacheClient != null && cacheClient.isNotEmpty) {
        _currentRole = parseRole(cacheClient);
      } else {
        final stored = await _storage.getRole();
        if (stored != null) _currentRole = stored;
      }
    } catch (e) {
      _error = 'Error inicializando rol: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFromServer() async {
    try {
      final response = await _rolesService.obtenerRolesDisponibles();
      final rolActivo =
          (response['rol_activo'] as String?)?.toUpperCase() ?? 'USUARIO';
      _currentRole = parseRole(rolActivo);
      await _storage.setRole(_currentRole);
      await _apiClient.cacheUserRole(rolActivo);
      notifyListeners();
    } catch (e) {
      _error = 'Error refrescando rol: $e';
      notifyListeners();
    }
  }

  Future<AppRole> switchRole(AppRole role) async {
    if (_loading) return _currentRole;
    _loading = true;
    _error = null;
    notifyListeners();

    final previo = _currentRole;
    final objetivo = roleToApi(role);
    debugPrint('[RoleController] Cambio solicitado: $previo -> $objetivo');

    try {
      final respuesta = await _rolesService.cambiarRolActivo(objetivo);
      final rolApi =
          (respuesta['rol_activo'] as String?)?.toUpperCase() ?? objetivo;
      final rolToken = (respuesta['tokens']?['rol'] as String?)?.toUpperCase();

      final confirmado = parseRole(rolApi.isNotEmpty ? rolApi : rolToken);

      _currentRole = confirmado;
      await _storage.setRole(confirmado);
      await _apiClient.cacheUserRole(roleToApi(confirmado));

      debugPrint(
        '[RoleController] Cambio aplicado: ${roleToApi(previo)} -> ${roleToApi(confirmado)}',
      );
      notifyListeners();
      return confirmado;
    } catch (e) {
      _error = 'No se pudo cambiar de rol: $e';
      debugPrint('[RoleController] Error cambiando rol: $e');
      notifyListeners();
      return _currentRole;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
