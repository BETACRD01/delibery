// lib/apis/auth/password_api.dart

import 'dart:developer' as developer;
import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';

/// API para gestión de contraseñas (recuperación y cambio)
class PasswordApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final PasswordApi _instance = PasswordApi._internal();
  factory PasswordApi() => _instance;
  PasswordApi._internal();

  final _client = ApiClient();

  void _log(String msg, {Object? error, StackTrace? stack}) {
    developer.log(msg, name: 'PasswordApi', error: error, stackTrace: stack);
  }

  // ---------------------------------------------------------------------------
  // RECUPERACIÓN DE CONTRASEÑA
  // ---------------------------------------------------------------------------

  /// Solicita un código de recuperación de contraseña
  Future<Map<String, dynamic>> solicitarRecuperacion({
    required String email,
  }) async {
    try {
      _log('Solicitando código de recuperación para: $email');
      return await _client.postPublic(
        ApiConfig.solicitarCodigoRecuperacion,
        {'email': email},
      );
    } catch (e, stack) {
      _log('Error solicitando recuperación', error: e, stack: stack);
      rethrow;
    }
  }

  /// Verifica el código de recuperación
  Future<Map<String, dynamic>> verificarCodigo({
    required String email,
    required String codigo,
  }) async {
    try {
      _log('Verificando código para: $email');
      return await _client.postPublic(
        ApiConfig.verificarCodigoRecuperacion,
        {
          'email': email,
          'codigo': codigo,
        },
      );
    } catch (e, stack) {
      _log('Error verificando código', error: e, stack: stack);
      rethrow;
    }
  }

  /// Resetea la contraseña con el código de recuperación
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    try {
      _log('Reseteando contraseña para: $email');
      return await _client.postPublic(
        ApiConfig.resetPasswordConCodigo,
        {
          'email': email,
          'codigo': codigo,
          'nueva_password': nuevaPassword,
        },
      );
    } catch (e, stack) {
      _log('Error reseteando contraseña', error: e, stack: stack);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // CAMBIO DE CONTRASEÑA (USUARIO AUTENTICADO)
  // ---------------------------------------------------------------------------

  /// Cambia la contraseña del usuario autenticado
  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
  }) async {
    try {
      _log('Cambiando contraseña');
      await _client.post(ApiConfig.cambiarPassword, {
        'password_actual': passwordActual,
        'password_nueva': nuevaPassword,
        'password_nueva2': nuevaPassword,
      });
    } catch (e, stack) {
      _log('Error cambiando contraseña', error: e, stack: stack);
      rethrow;
    }
  }
}
