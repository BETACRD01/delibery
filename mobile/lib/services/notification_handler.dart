// lib/services/notification_handler.dart

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import '../widgets/notificacion_in_app.dart';
import 'package:provider/provider.dart';
import '../providers/notificaciones_provider.dart';

/// Servicio para manejar las notificaciones push y navegar a las pantallas correctas
class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  BuildContext? _context;

  /// Inicializa el manejador de notificaciones con el contexto de la app
  void initialize(BuildContext context) {
    _context = context;
    _setupListeners();
  }

  void _setupListeners() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Cuando se abre la app desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app se abrió desde una notificación (app cerrada)
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? message = await _fcm.getInitialMessage();
    if (message != null) {
      _handleNotificationTap(message);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    developer.log(
      'Notificación recibida en primer plano: ${message.notification?.title}',
      name: 'NotificationHandler',
    );

    // Guardar en inbox unificado
    if (_context != null) {
      try {
        _context!.read<NotificacionesProvider>().agregarDesdePush(message);
      } catch (e) {
        developer.log('No se pudo guardar notificación en inbox', name: 'NotificationHandler', error: e);
      }
    }

    // Mostrar notificación in-app si el contexto está disponible
    if (_context != null) {
      NotificacionInApp.mostrar(_context!, message);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (_context == null) {
      developer.log('Context no disponible para navegar', name: 'NotificationHandler');
      return;
    }

    // Guardar/actualizar en inbox y marcar como leída
    try {
      _context!.read<NotificacionesProvider>().agregarDesdePush(message);
      final id = message.messageId ?? message.data['id'];
      if (id != null) {
        _context!.read<NotificacionesProvider>().marcarComoLeida(id.toString());
      }
    } catch (e) {
      developer.log('No se pudo actualizar inbox al tocar notificación', name: 'NotificationHandler', error: e);
    }

    final data = message.data;
    final accion = data['accion'];

    developer.log(
      'Notificación tocada. Acción: $accion',
      name: 'NotificationHandler',
    );

    switch (accion) {
      case 'ver_comprobante':
        _navegarAVerComprobante(data);
        break;
      case 'subir_comprobante':
        _navegarASubirComprobante(data);
        break;
      case 'ver_pedido_disponible':
        _navegarAPedidosDisponibles(data);
        break;
      case 'abrir_calificacion':
        _navegarACalificar(data);
        break;
      default:
        developer.log('Acción desconocida: $accion', name: 'NotificationHandler');
    }
  }

  void _navegarAVerComprobante(Map<String, dynamic> data) {
    if (_context == null) return;

    final pagoId = int.tryParse(data['pago_id'] ?? '0');
    if (pagoId == null || pagoId == 0) {
      developer.log('ID de pago inválido', name: 'NotificationHandler');
      return;
    }

    // Importar dinámicamente para evitar dependencias circulares
    // Navegar a la pantalla de ver comprobante
    try {
      Navigator.of(_context!).pushNamed(
        '/delivery/ver-comprobante',
        arguments: {'pagoId': pagoId},
      );
    } catch (e) {
      developer.log('Error navegando a ver comprobante: $e', name: 'NotificationHandler');
    }
  }

  void _navegarAPedidosDisponibles(Map<String, dynamic> data) {
    if (_context == null) return;

    try {
      // Navegar a la pantalla de pedidos disponibles (tab de disponibles)
      Navigator.of(_context!).pushNamed('/delivery/home');
    } catch (e) {
      developer.log('Error navegando a pedidos disponibles: $e', name: 'NotificationHandler');
    }
  }

  void _navegarACalificar(Map<String, dynamic> data) {
    if (_context == null) return;

    final pedidoId = int.tryParse(data['pedido_id'] ?? '0');
    if (pedidoId == null || pedidoId == 0) return;

    try {
      Navigator.of(_context!).pushNamed(
        '/user/pedido-detalle',
        arguments: {'pedidoId': pedidoId},
      );
    } catch (e) {
      developer.log('Error navegando a calificación: $e', name: 'NotificationHandler');
    }
  }

  void _navegarASubirComprobante(Map<String, dynamic> data) {
    if (_context == null) return;

    final pedidoId = int.tryParse(data['pedido_id'] ?? '0');
    if (pedidoId == null || pedidoId == 0) {
      developer.log('PedidoId inválido en subir_comprobante', name: 'NotificationHandler');
      return;
    }

    try {
      Navigator.of(_context!).pushNamed(
        '/user/pedido-detalle',
        arguments: {'pedidoId': pedidoId},
      );
    } catch (e) {
      developer.log('Error navegando a subir comprobante: $e', name: 'NotificationHandler');
    }
  }

  /// Actualiza el contexto cuando cambia (útil para navegación global)
  void updateContext(BuildContext context) {
    _context = context;
  }
}
