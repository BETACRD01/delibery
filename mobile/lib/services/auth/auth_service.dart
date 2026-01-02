// lib/services/auth/auth_service.dart

import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../../apis/auth/auth_api.dart';
import '../../apis/auth/password_api.dart';
import '../../apis/auth/roles_api.dart';
import '../../apis/helpers/api_exception.dart';
import '../../apis/subapis/http_client.dart';
import '../../controllers/user/home_controller.dart';
import '../../models/user_info.dart';
import '../core/cache/cache_manager.dart';
import '../repartidor/repartidor_service.dart';
import '../roles/role_manager.dart';
import '../usuarios/usuarios_service.dart';
import '../notifications/servicio_notificacion.dart';

// ============================================================================
// AUTH SERVICE
// ============================================================================

/// Servicio de autenticación y gestión de sesión
/// Delegación: Usa AuthApi, PasswordApi y RolesApi para llamadas HTTP
class AuthService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  // ---------------------------------------------------------------------------
  // APIS
  // ---------------------------------------------------------------------------

  final _authApi = AuthApi();
  final _passwordApi = PasswordApi();
  final _rolesApi = RolesApi();
  final _client = ApiClient(); // Solo para tokens y estado

  void _log(String msg, {Object? error, StackTrace? stack}) =>
      developer.log(msg, name: 'AuthService', error: error, stackTrace: stack);

  // ---------------------------------------------------------------------------
  // REGISTRO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    _log('Registro: ${data['email']}');

    _normalizeData(data);
    _validateRequired(data);
    _validatePasswords(data);

    try {
      final response = await _authApi.register(data);
      await _handleAuthResponse(response);
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      _log('Error en registro', error: e, stack: stack);
      throw ApiException(
        statusCode: 0,
        message: 'Error al registrar',
        errors: {'error': '$e'},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _log('Login: $email');

    try {
      final response = await _authApi.login(email: email, password: password);
      await _handleAuthResponse(response);
      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw ApiException.loginFallido(
          mensaje: 'Email o contraseña incorrectos',
          errors: e.errors,
        );
      }
      rethrow;
    } catch (e, stack) {
      _log('Error en login', error: e, stack: stack);
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión',
        errors: {'error': '$e'},
        contexto: 'login',
      );
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String accessToken,
  }) async {
    _log('Login Google');

    try {
      final response = await _authApi.loginWithGoogle(accessToken: accessToken);
      await _handleAuthResponse(response);
      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw ApiException.loginFallido(
          mensaje: 'No se pudo autenticar con Google',
          errors: e.errors,
        );
      }
      rethrow;
    } catch (e, stack) {
      _log('Error en login Google', error: e, stack: stack);
      throw ApiException(
        statusCode: 0,
        message: 'Error al conectar con Google',
        errors: {'error': '$e'},
        contexto: 'login',
      );
    }
  }

  Future<void> logout() async {
    try {
      _log('Cerrando sesión...');
      await _authApi
          .logout(_client.refreshToken)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => {'message': 'Timeout'},
          );
    } catch (e) {
      _log('Advertencia logout: $e');
    } finally {
      await _client.clearTokens();
      try {
        CacheManager.instance.clear();
        UsuarioService().limpiarCache();
        RepartidorService().limpiarCache();
        HomeController.limpiarCacheMemoria();
        await RoleManager().logout();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('historial_busqueda');
        await prefs.remove('inbox_notificaciones');
      } catch (e) {
        _log('Advertencia limpiando caché local: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PERFIL
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getPerfil() => _authApi.getPerfil();

  Future<Map<String, dynamic>> actualizarPerfil(Map<String, dynamic> data) =>
      _authApi.actualizarPerfil(data);

  Future<Map<String, dynamic>> actualizarFotoPerfil(dynamic imagen) {
    // Acepta File de dart:io
    // Si usas image_picker, obtienes un XFile, conviértelo a File antes de llamar aquí
    return _authApi.actualizarFotoPerfil(imagen);
  }

  Future<Map<String, dynamic>> getInfoRol() => _authApi.getInfoRol();

  Future<bool> verificarToken() async {
    try {
      await _authApi.verificarToken();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // RECUPERACIÓN DE CONTRASEÑA
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> solicitarRecuperacion({required String email}) =>
      _passwordApi.solicitarRecuperacion(email: email);

  Future<Map<String, dynamic>> verificarCodigo({
    required String email,
    required String codigo,
  }) => _passwordApi.verificarCodigo(email: email, codigo: codigo);

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) => _passwordApi.resetPassword(
    email: email,
    codigo: codigo,
    nuevaPassword: nuevaPassword,
  );

  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) => _passwordApi.cambiarPassword(
    passwordActual: passwordActual,
    nuevaPassword: nuevaPassword,
  );

  // ---------------------------------------------------------------------------
  // ROLES
  // ---------------------------------------------------------------------------

  String? getRolCacheado() => _client.userRole;
  int? getUserIdCacheado() => _client.userId;

  bool esRepartidor() => _client.userRole?.toUpperCase() == 'REPARTIDOR';
  bool esUsuario() => _client.userRole?.toUpperCase() == 'USUARIO';
  bool esProveedor() => _client.userRole?.toUpperCase() == 'PROVEEDOR';
  bool esAdministrador() => _client.userRole?.toUpperCase() == 'ADMINISTRADOR';
  bool tieneRol(String rol) =>
      _client.userRole?.toUpperCase() == rol.toUpperCase();

  Future<Map<String, dynamic>> obtenerRolesDisponibles() =>
      _rolesApi.obtenerRolesDisponibles();

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    _log('Cambiando rol a: $nuevoRol');

    final response = await _rolesApi.cambiarRolActivo(nuevoRol);

    if (response.containsKey('tokens')) {
      final tokens = response['tokens'];
      final rolFinal = (tokens['rol'] as String? ?? nuevoRol)
          .toString()
          .toUpperCase();

      await _client.saveTokens(
        tokens['access'],
        tokens['refresh'],
        role: rolFinal,
        userId: _client.userId,
      );
      _log('Rol cambiado (con tokens). Rol final: $rolFinal');
    } else {
      await _client.cacheUserRole(nuevoRol);
      _log('Rol cambiado sin tokens, caché actualizado');
    }

    return response;
  }

  // ---------------------------------------------------------------------------
  // ESTADO Y UTILIDADES
  // ---------------------------------------------------------------------------

  UserInfo? get user {
    if (!_client.isAuthenticated) {
      return null;
    }
    final rol = getRolCacheado();
    if (rol == null) {
      return null;
    }
    return UserInfo(
      email: 'usuario@deliber.com',
      roles: [rol],
      userId: getUserIdCacheado(),
    );
  }

  bool get isAuthenticated => _client.isAuthenticated;

  Future<bool> hasStoredTokens() async => _client.isAuthenticated;

  Future<void> loadTokens() async {
    await _client.loadTokens();
    _log(
      'Tokens cargados${_client.userRole != null ? " - Rol: ${_client.userRole}" : ""}',
    );
  }

  void imprimirEstadoAuth() {
    _log('--- Estado Auth ---');
    _log('Autenticado: ${_client.isAuthenticated}');
    _log('Rol: ${_client.userRole ?? "N/A"}');
    _log('User ID: ${_client.userId ?? "N/A"}');
  }

  // ---------------------------------------------------------------------------
  // HELPERS PRIVADOS
  // ---------------------------------------------------------------------------

  Future<void> _handleAuthResponse(Map<String, dynamic> response) async {
    if (!response.containsKey('tokens')) {
      return;
    }

    final tokens = response['tokens'];
    final usuario = response['usuario'] as Map<String, dynamic>?;

    String? rol = tokens['rol'] as String?;
    if (rol == null && usuario != null) {
      rol = _determinarRol(usuario);
    }

    await _client.saveTokens(
      tokens['access'],
      tokens['refresh'],
      role: rol,
      userId: tokens['user_id'] as int?,
    );

    // IMPORTANTE: Inicializar notificaciones después del login exitoso
    // para asegurar que el token FCM se vincule al usuario
    try {
      await NotificationService().initialize();
    } catch (e) {
      _log('Advertencia: No se pudieron activar notificaciones tras login: $e');
    }

    _log('Auth exitoso - Rol: $rol');
  }

  String _determinarRol(Map<String, dynamic> usuario) {
    final rolActivo = usuario['rol_activo'] as String?;
    if (rolActivo?.isNotEmpty == true) {
      return _mapRol(rolActivo!);
    }

    final tipo = usuario['tipo_usuario'] as String?;
    if (tipo?.isNotEmpty == true) {
      return _mapRol(tipo!);
    }

    final roles = usuario['roles_aprobados'];
    if (roles is List) {
      for (final r in ['admin', 'repartidor', 'proveedor', 'cliente']) {
        if (roles.any((x) => x.toString().toLowerCase() == r)) {
          return _mapRol(r);
        }
      }
    }

    if (usuario['is_superuser'] == true) {
      return 'ADMINISTRADOR';
    }

    return 'USUARIO';
  }

  String _mapRol(String raw) => switch (raw.toLowerCase()) {
    'cliente' || 'usuario' => 'USUARIO',
    'proveedor' => 'PROVEEDOR',
    'repartidor' => 'REPARTIDOR',
    'admin' || 'administrador' => 'ADMINISTRADOR',
    _ => 'USUARIO',
  };

  void _normalizeData(Map<String, dynamic> data) {
    if (data.containsKey('email')) {
      data['email'] = data['email'].toString().trim().toLowerCase();
    }

    for (final field in [
      'first_name',
      'last_name',
      'username',
      'celular',
      'password',
      'password2',
    ]) {
      if (data[field] != null) {
        data[field] = data[field].toString().trim();
      }
    }

    data['terminos_aceptados'] ??= true;
  }

  void _validateRequired(Map<String, dynamic> data) {
    final required = {
      'first_name': 'Nombre',
      'last_name': 'Apellido',
      'email': 'Email',
      'celular': 'Celular',
      'password': 'Contraseña',
      'password2': 'Confirmar contraseña',
    };

    final missing = required.entries
        .where((e) => data[e.key] == null || data[e.key].toString().isEmpty)
        .map((e) => '${e.value} es requerido')
        .toList();

    if (missing.isNotEmpty) {
      throw ApiException(
        statusCode: 400,
        message: 'Campos faltantes:\n${missing.join("\n")}',
        errors: {'campos': missing},
      );
    }
  }

  void _validatePasswords(Map<String, dynamic> data) {
    if (data['password'] != data['password2']) {
      throw ApiException(
        statusCode: 400,
        message: 'Las contraseñas no coinciden',
        errors: {'password2': 'No coincide'},
      );
    }
  }
}
