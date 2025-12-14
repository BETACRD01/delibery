// lib/services/auth_service.dart

import '../apis/subapis/http_client.dart';
import '../config/api_config.dart';
import '../apis/helpers/api_exception.dart';
import 'dart:developer' as developer;

// Modelo simplificado para representar informacion basica del usuario
class UserInfo {
  final String email;
  final List<String> roles;
  final int? userId;

  UserInfo({required this.email, required this.roles, this.userId});

  bool tieneRol(String rol) {
    return roles.any((r) => r.toUpperCase() == rol.toUpperCase());
  }

  bool get esProveedor => tieneRol('PROVEEDOR');
  bool get esRepartidor => tieneRol('REPARTIDOR');
  bool get esAdmin => tieneRol('ADMINISTRADOR');
  bool get esAnonimo => email.toLowerCase().contains('anonymous');

  @override
  String toString() => 'UserInfo(email: $email, roles: $roles, userId: $userId)';
}

class AuthService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------
  
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _client = ApiClient();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'AuthService', error: error, stackTrace: stackTrace);
  }

  // ---------------------------------------------------------------------------
  // REGISTRO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    _log('Iniciando registro para: ${data['email']}');

    _normalizarDatosRegistro(data);
    _logDatosRegistro(data);
    _validarCamposRequeridos(data);
    _validarCoincidenciaPasswords(data);

    try {
      final response = await _client.postPublic(ApiConfig.registro, data);

      if (response.containsKey('tokens')) {
        final tokens = response['tokens'];
        final usuario = response['usuario'] as Map<String, dynamic>?;

        String? rol = tokens['rol'] as String?;
        if (rol == null && usuario != null) {
          rol = _determinarRolDesdeUsuario(usuario);
        }

        final int? userId = tokens['user_id'] as int?;

        await _client.saveTokens(
          tokens['access'],
          tokens['refresh'],
          role: rol,
          userId: userId,
          tokenLifetime: const Duration(hours: 24),
        );

        _log('Registro exitoso - Rol: $rol - ID: $userId');
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error inesperado en registro', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al registrar usuario',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    _log('Login para: $email');

    try {
      final response = await _client.postPublic(ApiConfig.login, {
        'identificador': email,
        'password': password,
      });

      if (response.containsKey('tokens')) {
        final tokens = response['tokens'];
        final usuario = response['usuario'] as Map<String, dynamic>?;

        String? rol = tokens['rol'] as String?;
        if (rol == null && usuario != null) {
          rol = _determinarRolDesdeUsuario(usuario);
        }

        final int? userId = tokens['user_id'] as int?;

        await _client.saveTokens(
          tokens['access'],
          tokens['refresh'],
          role: rol,
          userId: userId,
          tokenLifetime: const Duration(hours: 24),
        );

        _log('Login exitoso - Rol: $rol - ID: $userId');
      }

      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _log('Credenciales invalidas');
        throw ApiException.loginFallido(
          mensaje: 'Email o contraseña incorrectos',
          errors: e.errors,
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      _log('Error inesperado en login', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexion',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
        contexto: 'login',
      );
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle({required String accessToken}) async {
    _log('Login con Google');

    try {
      final response = await _client.postPublic(ApiConfig.googleLogin, {
        'access_token': accessToken,
      });

      if (response.containsKey('tokens')) {
        final tokens = response['tokens'];
        final usuario = response['usuario'] as Map<String, dynamic>?;

        String? rol = tokens['rol'] as String?;
        if (rol == null && usuario != null) {
          rol = _determinarRolDesdeUsuario(usuario);
        }

        final int? userId = tokens['user_id'] as int?;

        await _client.saveTokens(
          tokens['access'],
          tokens['refresh'],
          role: rol,
          userId: userId,
          tokenLifetime: const Duration(hours: 24),
        );

        _log('Login Google exitoso - Rol: $rol');
      }

      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw ApiException.loginFallido(
          mensaje: 'No se pudo autenticar con Google',
          errors: e.errors,
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      _log('Error inesperado en login Google', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al conectar con Google',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
        contexto: 'login',
      );
    }
  }

  Future<void> logout() async {
    try {
      _log('Cerrando sesion...');
      if (_client.refreshToken != null) {
        await _client.post(ApiConfig.logout, {'refresh_token': _client.refreshToken});
      }
      _log('Logout exitoso');
    } catch (e) {
      _log('Advertencia en logout servidor: $e');
    } finally {
      await _client.clearTokens();
    }
  }

  // ---------------------------------------------------------------------------
  // PERFIL Y RECUPERACION
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getPerfil() async {
    return await _client.get(ApiConfig.perfil);
  }

  Future<Map<String, dynamic>> actualizarPerfil(Map<String, dynamic> data) async {
    return await _client.put(ApiConfig.actualizarPerfil, data);
  }

  Future<Map<String, dynamic>> getInfoRol() async {
    return await _client.get(ApiConfig.infoRol);
  }

  Future<bool> verificarToken() async {
    try {
      await _client.get(ApiConfig.verificarToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> solicitarRecuperacion({required String email}) async {
    return await _client.postPublic(ApiConfig.solicitarCodigoRecuperacion, {'email': email});
  }

  Future<Map<String, dynamic>> verificarCodigo({required String email, required String codigo}) async {
    return await _client.postPublic(ApiConfig.verificarCodigoRecuperacion, {
      'email': email,
      'codigo': codigo,
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    return await _client.postPublic(ApiConfig.resetPasswordConCodigo, {
      'email': email,
      'codigo': codigo,
      'nueva_password': nuevaPassword,
    });
  }

  // ---------------------------------------------------------------------------
  // ROLES Y ESTADO (Getters directos)
  // ---------------------------------------------------------------------------

  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    await _client.post(ApiConfig.cambiarPassword, {
      'password_actual': passwordActual,
      'password_nueva': nuevaPassword,
      'password_nueva2': nuevaPassword, // Confirmación automática
    });
  }

  String? getRolCacheado() => _client.userRole;
  int? getUserIdCacheado() => _client.userId;

  bool esRepartidor() => _client.userRole?.toUpperCase() == ApiConfig.rolRepartidor;
  bool esUsuario() => _client.userRole?.toUpperCase() == ApiConfig.rolUsuario;
  bool esProveedor() => _client.userRole?.toUpperCase() == ApiConfig.rolProveedor;
  bool esAdministrador() => _client.userRole?.toUpperCase() == ApiConfig.rolAdministrador;

  bool tieneRol(String rol) => _client.userRole?.toUpperCase() == rol.toUpperCase();

  // ---------------------------------------------------------------------------
  // GESTION ROLES MULTIPLES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> obtenerRolesDisponibles() async {
    return await _client.get(ApiConfig.usuariosMisRoles);
  }

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    _log('Cambiando rol activo a: $nuevoRol');
    // ✅ CORRECCIÓN: Clave 'nuevo_rol' para coincidir con Django views.py
    final response = await _client.post(ApiConfig.usuariosCambiarRolActivo, {
      'nuevo_rol': nuevoRol.toUpperCase(), 
    });

    if (response.containsKey('tokens')) {
      final tokens = response['tokens'];
      await _client.saveTokens(
        tokens['access'],
        tokens['refresh'],
        role: tokens['rol'] as String?,
        userId: _client.userId,
        tokenLifetime: const Duration(hours: 24),
      );
      _log('Rol cambiado exitosamente');
    }

    return response;
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES PUBLICAS
  // ---------------------------------------------------------------------------

  UserInfo? get user {
    if (!_client.isAuthenticated) return null;
    final rol = getRolCacheado();
    final userId = getUserIdCacheado();
    if (rol == null) return null;

    return UserInfo(
      email: 'usuario@deliber.com',
      roles: [rol],
      userId: userId,
    );
  }

  void imprimirEstadoAuth() {
    _log('--- Estado Auth ---');
    _log('Autenticado: ${_client.isAuthenticated}');
    _log('Rol Cacheado: ${_client.userRole ?? "N/A"}');
    _log('User ID: ${_client.userId ?? "N/A"}');
    
    if (_client.tokenExpiry != null) {
      final remaining = _client.tokenExpiry!.difference(DateTime.now());
      _log('Token expira en: ${remaining.inMinutes} min');
    }
  }

  static String formatearTiempoEspera(int segundos) {
    final duracion = Duration(seconds: segundos);
    final minutos = duracion.inMinutes;
    final segundosRestantes = duracion.inSeconds % 60;
    return minutos > 0 ? '$minutos m $segundosRestantes s' : '$segundosRestantes s';
  }

  Future<bool> hasStoredTokens() async {
    return await _client.hasStoredTokens();
  }

  Future<void> loadTokens() async {
    await _client.loadTokens();
    if (_client.userRole == null) {
      _log('Tokens cargados sin rol');
    } else {
      _log('Tokens cargados con rol: ${_client.userRole}');
    }
  }

  bool get isAuthenticated => _client.isAuthenticated;

  // ---------------------------------------------------------------------------
  // HELPERS PRIVADOS
  // ---------------------------------------------------------------------------

  String _determinarRolDesdeUsuario(Map<String, dynamic> usuario) {
    if (usuario['is_superuser'] == true) return 'ADMINISTRADOR';
    if (usuario['is_staff'] == true) return 'STAFF';
    return 'USUARIO';
  }

  void _normalizarDatosRegistro(Map<String, dynamic> data) {
    if (data.containsKey('email')) {
      data['email'] = data['email'].toString().trim().toLowerCase();
    }

    const textFields = ['first_name', 'last_name', 'username', 'celular', 'password', 'password2'];
    for (final field in textFields) {
      if (data[field] != null) {
        data[field] = data[field].toString().trim();
      }
    }

    if (!data.containsKey('terminos_aceptados')) {
      data['terminos_aceptados'] = true;
    }
  }

  void _logDatosRegistro(Map<String, dynamic> data) {
    _log('Datos normalizados:');
    data.forEach((key, value) {
      if (key != 'password' && key != 'password2') {
        _log('  $key: "$value"');
      } else {
        _log('  $key: [OCULTO]');
      }
    });
  }

  void _validarCamposRequeridos(Map<String, dynamic> data) {
    final required = {
      'first_name': 'Nombre',
      'last_name': 'Apellido',
      'email': 'Email',
      'celular': 'Celular',
      'password': 'Contraseña',
      'password2': 'Confirmar contraseña',
    };

    final missing = <String>[];
    required.forEach((key, label) {
      if (!data.containsKey(key) || data[key] == null || data[key].toString().isEmpty) {
        missing.add('$label es requerido');
      }
    });

    if (missing.isNotEmpty) {
      throw ApiException(
        statusCode: 400,
        message: 'Faltan campos obligatorios:\n${missing.join("\n")}',
        errors: {'campos_faltantes': missing},
        stackTrace: StackTrace.current,
      );
    }
  }

  void _validarCoincidenciaPasswords(Map<String, dynamic> data) {
    final p1 = data['password'] ?? '';
    final p2 = data['password2'] ?? '';

    if (p1 != p2) {
      throw ApiException(
        statusCode: 400,
        message: 'Las contraseñas no coinciden',
        errors: {'password2': 'No coincide con la contraseña'},
        stackTrace: StackTrace.current,
      );
    }
  }
}
