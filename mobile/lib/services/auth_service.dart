// lib/services/auth_service.dart
import 'dart:developer' as developer;
import '../apis/subapis/http_client.dart';
import '../config/api_config.dart';
import '../apis/helpers/api_exception.dart';

// ============================================================================
// USER INFO MODEL
// ============================================================================

class UserInfo {
  final String email;
  final List<String> roles;
  final int? userId;

  UserInfo({required this.email, required this.roles, this.userId});

  bool tieneRol(String rol) =>
      roles.any((r) => r.toUpperCase() == rol.toUpperCase());
  bool get esProveedor => tieneRol('PROVEEDOR');
  bool get esRepartidor => tieneRol('REPARTIDOR');
  bool get esAdmin => tieneRol('ADMINISTRADOR');
  bool get esAnonimo => email.toLowerCase().contains('anonymous');

  @override
  String toString() =>
      'UserInfo(email: $email, roles: $roles, userId: $userId)';
}

// ============================================================================
// AUTH SERVICE
// ============================================================================

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final _client = ApiClient();
  static const _tokenDuration = Duration(hours: 24);

  void _log(String msg, {Object? error, StackTrace? stack}) =>
      developer.log(msg, name: 'AuthService', error: error, stackTrace: stack);

  // --------------------------------------------------------------------------
  // Registro
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    _log('Registro: ${data['email']}');

    _normalizeData(data);
    _validateRequired(data);
    _validatePasswords(data);

    try {
      final response = await _client.postPublic(ApiConfig.registro, data);
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

  // --------------------------------------------------------------------------
  // Login
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _log('Login: $email');

    try {
      final response = await _client.postPublic(ApiConfig.login, {
        'identificador': email,
        'password': password,
      });
      await _handleAuthResponse(response);
      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw ApiException.loginFallido(
          mensaje: 'Email o contrasena incorrectos',
          errors: e.errors,
        );
      }
      rethrow;
    } catch (e, stack) {
      _log('Error en login', error: e, stack: stack);
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexion',
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
      final response = await _client.postPublic(ApiConfig.googleLogin, {
        'access_token': accessToken,
      });
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
      _log('Cerrando sesion...');
      if (_client.refreshToken != null) {
        await _client.post(ApiConfig.logout, {
          'refresh_token': _client.refreshToken,
        });
      }
    } catch (e) {
      _log('Advertencia logout: $e');
    } finally {
      await _client.clearTokens();
    }
  }

  // --------------------------------------------------------------------------
  // Perfil y Recuperacion
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> getPerfil() => _client.get(ApiConfig.perfil);
  Future<Map<String, dynamic>> actualizarPerfil(Map<String, dynamic> data) =>
      _client.put(ApiConfig.actualizarPerfil, data);
  Future<Map<String, dynamic>> getInfoRol() => _client.get(ApiConfig.infoRol);

  Future<bool> verificarToken() async {
    try {
      await _client.get(ApiConfig.verificarToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> solicitarRecuperacion({required String email}) =>
      _client.postPublic(ApiConfig.solicitarCodigoRecuperacion, {
        'email': email,
      });

  Future<Map<String, dynamic>> verificarCodigo({
    required String email,
    required String codigo,
  }) => _client.postPublic(ApiConfig.verificarCodigoRecuperacion, {
    'email': email,
    'codigo': codigo,
  });

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) => _client.postPublic(ApiConfig.resetPasswordConCodigo, {
    'email': email,
    'codigo': codigo,
    'nueva_password': nuevaPassword,
  });

  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    await _client.post(ApiConfig.cambiarPassword, {
      'password_actual': passwordActual,
      'password_nueva': nuevaPassword,
      'password_nueva2': nuevaPassword,
    });
  }

  // --------------------------------------------------------------------------
  // Roles y Estado
  // --------------------------------------------------------------------------

  String? getRolCacheado() => _client.userRole;
  int? getUserIdCacheado() => _client.userId;

  bool esRepartidor() =>
      _client.userRole?.toUpperCase() == ApiConfig.rolRepartidor;
  bool esUsuario() => _client.userRole?.toUpperCase() == ApiConfig.rolUsuario;
  bool esProveedor() =>
      _client.userRole?.toUpperCase() == ApiConfig.rolProveedor;
  bool esAdministrador() =>
      _client.userRole?.toUpperCase() == ApiConfig.rolAdministrador;
  bool tieneRol(String rol) =>
      _client.userRole?.toUpperCase() == rol.toUpperCase();

  Future<Map<String, dynamic>> obtenerRolesDisponibles() =>
      _client.get(ApiConfig.usuariosMisRoles);

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    _log('Cambiando rol a: $nuevoRol');

    final response = await _client.post(ApiConfig.usuariosCambiarRolActivo, {
      'nuevo_rol': nuevoRol.toUpperCase(),
    });

    if (response.containsKey('tokens')) {
      final tokens = response['tokens'];
      final rolFinal =
          (tokens['rol'] as String? ?? nuevoRol).toString().toUpperCase();
      await _client.saveTokens(
        tokens['access'],
        tokens['refresh'],
        role: rolFinal,
        userId: _client.userId,
        lifetime: _tokenDuration,
      );
      _log('Rol cambiado (con tokens). Rol final: $rolFinal');
    } else {
      await _client.cacheUserRole(nuevoRol);
      _log('Rol cambiado sin tokens, cache actualizado');
    }

    return response;
  }

  // --------------------------------------------------------------------------
  // Utilidades Publicas
  // --------------------------------------------------------------------------

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
  Future<bool> hasStoredTokens() => _client.hasStoredTokens();

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
    if (_client.tokenExpiry != null) {
      _log(
        'Expira en: ${_client.tokenExpiry!.difference(DateTime.now()).inMinutes} min',
      );
    }
  }

  static String formatearTiempoEspera(int segundos) {
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    return min > 0 ? '$min m $sec s' : '$sec s';
  }

  // --------------------------------------------------------------------------
  // Helpers Privados
  // --------------------------------------------------------------------------

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
      lifetime: _tokenDuration,
    );

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
      'password': 'Contrasena',
      'password2': 'Confirmar contrasena',
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
        message: 'Las contrasenas no coinciden',
        errors: {'password2': 'No coincide'},
      );
    }
  }
}
