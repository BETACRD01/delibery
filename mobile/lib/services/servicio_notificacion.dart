// lib/services/servicio_notificacion.dart

import 'dart:async'; // Necesario para Timer, Future.delayed y reintentos
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../apis/helpers/api_exception.dart'; // Importar ApiException
import '../apis/user/usuarios_api.dart';

class NotificationService {
  // ---------------------------------------------------------------------------
  // DEPENDENCIAS
  // ---------------------------------------------------------------------------

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final UsuariosApi _usuariosApi = UsuariosApi();

  // 💡 CONSTANTES PARA REINTENTOS
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 5);

  void _log(String message, {Object? error}) {
    developer.log(message, name: 'NotificationService', error: error);
  }

  // ---------------------------------------------------------------------------
  // INICIALIZACION
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    // 1. Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _log('Permisos de notificacion: ${settings.authorizationStatus}');

    // 2. Configurar notificaciones locales (Android)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _log('Notificacion local tocada: ${details.payload}');
      },
    );

    // 3. Gestionar Token FCM
    String? token = await _messaging.getToken();
    if (token != null) {
      _log('Token FCM obtenido exitosamente');
      await _enviarTokenAlBackend(token);

      // Listener para refresco de token
      _messaging.onTokenRefresh.listen((nuevoToken) {
        _log('Token FCM refrescado automaticamente');
        _enviarTokenAlBackend(nuevoToken);
      });
    } else {
      _log('No se pudo obtener el token FCM');
    }

    // 4. Listeners de Mensajes
    _configurarListeners();
  }

  void _configurarListeners() {
    // Foreground (App abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log('Mensaje recibido en primer plano: ${message.messageId}');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Background / Terminated (Al abrir desde notificacion)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log('Aplicacion abierta desde notificacion: ${message.messageId}');
      // Aqui puedes agregar logica de navegacion si es necesario
    });
  }

  // ---------------------------------------------------------------------------
  // SINCRONIZACION CON BACKEND (Corregido)
  // ---------------------------------------------------------------------------

  /// Implementación de reintentos con retraso exponencial para manejar el error 429.
  Future<void> _enviarTokenAlBackend(String token) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _retryEnviarToken(token, attempt);
        return; // Éxito, salir de la función
      } on ApiException catch (e) {
        // Error de red: se intentará más tarde
        if (e.isNetworkError) {
          _log(
            'Sin conexion al registrar token FCM; se intentara de nuevo mas tarde',
          );
          return;
        }

        // Error 401: Sesión expirada - silenciosamente saltar (comportamiento esperado)
        if (e.statusCode == 401) {
          _log(
            'Sesion expirada, omitiendo registro FCM (el usuario debera iniciar sesion)',
          );
          return;
        }

        // Error 429: Reintentar después de un delay
        if (e.statusCode == 429 && attempt < _maxRetries) {
          final delay = _baseDelay * attempt;
          _log(
            'Token FCM: Error 429 (Throttle). Reintentando en ${delay.inSeconds}s (Intento $attempt/$_maxRetries)',
            error: e,
          );
          await Future.delayed(delay);
          continue;
        } else {
          // Cualquier otro error fatal
          _log('Error registrando token FCM (Intento $attempt): ${e.message}');
          return;
        }
      } catch (e) {
        // Otros errores no ApiException (ej. Timeout, SocketException)
        _log('Error de red/desconocido al enviar token', error: e);
        return;
      }
    }
  }

  Future<void> _retryEnviarToken(String token, int attempt) async {
    try {
      final response = await _usuariosApi.registrarFCMToken(token);

      // Verificacion flexible de exito
      if (response['success'] == true || response.containsKey('mensaje')) {
        _log(
          'Token FCM registrado en backend correctamente (Intento $attempt)',
        );
      } else {
        _log('Respuesta inesperada al registrar token: $response');
      }
    } on ApiException {
      rethrow;
    }
  }

  Future<void> eliminarToken() async {
    try {
      // Intentar eliminar del backend primero
      await _usuariosApi.eliminarFCMToken();
      // Luego eliminar del dispositivo local
      await _messaging.deleteToken();
      _log('Token FCM eliminado completamente');
    } catch (e) {
      _log('Error eliminando token FCM', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES UI
  // ---------------------------------------------------------------------------

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones Importantes',
          channelDescription: 'Canal para notificaciones de alta prioridad',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Sin titulo',
      message.notification?.body ?? 'Sin contenido',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
