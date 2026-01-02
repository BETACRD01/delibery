// lib/apis/auth/auth_api.dart

import 'dart:developer' as developer;
import 'dart:io';
import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';

/// API para autenticación (login, registro, logout)
class AuthApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final AuthApi _instance = AuthApi._internal();
  factory AuthApi() => _instance;
  AuthApi._internal();

  final _client = ApiClient();

  void _log(String msg, {Object? error, StackTrace? stack}) {
    developer.log(msg, name: 'AuthApi', error: error, stackTrace: stack);
  }

  // ---------------------------------------------------------------------------
  // REGISTRO
  // ---------------------------------------------------------------------------

  /// Registra un nuevo usuario en el sistema
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      _log('Registro: ${data['email']}');
      return await _client.postPublic(ApiConfig.registro, data);
    } catch (e, stack) {
      _log('Error en registro', error: e, stack: stack);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------

  /// Login con email y contraseña
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      _log('Login: $email');
      return await _client.postPublic(ApiConfig.login, {
        'identificador': email,
        'password': password,
      });
    } catch (e, stack) {
      _log('Error en login', error: e, stack: stack);
      rethrow;
    }
  }

  /// Login con Google
  Future<Map<String, dynamic>> loginWithGoogle({
    required String accessToken,
  }) async {
    try {
      _log('Login Google');
      return await _client.postPublic(ApiConfig.googleLogin, {
        'access_token': accessToken,
      });
    } catch (e, stack) {
      _log('Error en login Google', error: e, stack: stack);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  /// Cierra sesión y notifica al backend
  Future<Map<String, dynamic>> logout(String? refreshToken) async {
    try {
      _log('Logout');
      if (refreshToken == null) {
        return {};
      }
      return await _client.post(ApiConfig.logout, {
        'refresh_token': refreshToken,
      });
    } catch (e, stack) {
      _log('Error en logout', error: e, stack: stack);
      return {}; // No bloqueamos el logout si falla la notificación
    }
  }

  // ---------------------------------------------------------------------------
  // PERFIL
  // ---------------------------------------------------------------------------

  /// Obtiene el perfil del usuario autenticado
  Future<Map<String, dynamic>> getPerfil() async {
    try {
      return await _client.get(ApiConfig.perfil);
    } catch (e, stack) {
      _log('Error obteniendo perfil', error: e, stack: stack);
      rethrow;
    }
  }

  /// Actualiza el perfil del usuario autenticado
  Future<Map<String, dynamic>> actualizarPerfil(
    Map<String, dynamic> data,
  ) async {
    try {
      return await _client.put(ApiConfig.actualizarPerfil, data);
    } catch (e, stack) {
      _log('Error actualizando perfil', error: e, stack: stack);
      rethrow;
    }
  }

  /// Actualiza la foto de perfil
  Future<Map<String, dynamic>> actualizarFotoPerfil(File imagen) async {
    try {
      return await _client.multipart('PATCH', ApiConfig.actualizarPerfil, {}, {
        'foto_perfil': imagen,
      });
    } catch (e, stack) {
      _log('Error actualizando foto perfil', error: e, stack: stack);
      rethrow;
    }
  }

  /// Obtiene información del rol activo
  Future<Map<String, dynamic>> getInfoRol() async {
    try {
      return await _client.get(ApiConfig.infoRol);
    } catch (e, stack) {
      _log('Error obteniendo info rol', error: e, stack: stack);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VERIFICACIÓN
  // ---------------------------------------------------------------------------

  /// Verifica si el token actual es válido
  Future<Map<String, dynamic>> verificarToken() async {
    try {
      return await _client.get(ApiConfig.verificarToken);
    } catch (e, stack) {
      _log('Error verificando token', error: e, stack: stack);
      rethrow;
    }
  }
  // ---------------------------------------------------------------------------
  // PREFERENCIAS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getPreferencias() async {
    return await _client.get(ApiConfig.actualizarPreferencias);
  }

  Future<Map<String, dynamic>> updatePreferencias(
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.actualizarPreferencias, data);
  }
}
