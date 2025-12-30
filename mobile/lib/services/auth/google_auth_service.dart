// lib/services/auth/google_auth_service.dart

import 'dart:developer' as developer;

import 'package:google_sign_in/google_sign_in.dart';

import '../../apis/helpers/api_exception.dart';
import 'auth_service.dart';

/// Servicio para autenticación con Google OAuth 2.0
///
/// Uso:
/// ```dart
/// final result = await GoogleAuthService().signInWithGoogle();
/// if (result != null) {
///   // Usuario autenticado exitosamente
/// }
/// ```
class GoogleAuthService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  GoogleAuthService._();
  static final GoogleAuthService _instance = GoogleAuthService._();
  factory GoogleAuthService() => _instance;

  // ---------------------------------------------------------------------------
  // CONFIGURACIÓN
  // ---------------------------------------------------------------------------

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  final _authService = AuthService();

  void _log(String msg, {Object? error, StackTrace? stack}) =>
      developer.log(msg, name: 'GoogleAuth', error: error, stackTrace: stack);

  // ---------------------------------------------------------------------------
  // ESTADO
  // ---------------------------------------------------------------------------

  /// Verifica si hay una sesión de Google activa
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Usuario actual de Google (si existe)
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  // ---------------------------------------------------------------------------
  // MÉTODOS PRINCIPALES
  // ---------------------------------------------------------------------------

  /// Inicia sesión con Google y autentica con el backend
  ///
  /// Retorna el response del backend si es exitoso, null si el usuario cancela.
  /// Lanza [ApiException] si hay errores.
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      _log('Iniciando login con Google...');

      // 0. Forzar mostrar selector de cuentas cerrando sesión previa
      await _googleSignIn.signOut();

      // 1. Mostrar picker de Google y obtener cuenta
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _log('Usuario canceló el login de Google');
        return null; // Usuario canceló
      }

      _log('Cuenta Google obtenida: ${googleUser.email}');

      // 2. Obtener tokens de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw ApiException(
          statusCode: 401,
          message: 'No se pudo obtener el token de Google',
          errors: {'google': 'accessToken es null'},
        );
      }

      _log('Token de Google obtenido, autenticando con backend...');

      // 3. Enviar token al backend para autenticar/registrar
      final response = await _authService.loginWithGoogle(
        accessToken: accessToken,
      );

      _log('Login con Google exitoso: ${googleUser.email}');

      return response;
    } on ApiException {
      // Cerrar sesión de Google si falló el backend
      await _googleSignIn.signOut();
      rethrow;
    } catch (e, stack) {
      _log('Error en login con Google', error: e, stack: stack);

      // Cerrar sesión de Google si hubo error
      await _googleSignIn.signOut();

      throw ApiException(
        statusCode: 0,
        message: 'Error al conectar con Google',
        errors: {'error': '$e'},
        contexto: 'google_login',
      );
    }
  }

  /// Cierra sesión de Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _log('Sesión de Google cerrada');
    } catch (e) {
      _log('Error cerrando sesión de Google: $e');
    }
  }

  /// Desconecta completamente la cuenta de Google
  /// (Revoca permisos - el usuario deberá autorizar de nuevo)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      _log('Cuenta de Google desconectada');
    } catch (e) {
      _log('Error desconectando cuenta de Google: $e');
    }
  }
}
