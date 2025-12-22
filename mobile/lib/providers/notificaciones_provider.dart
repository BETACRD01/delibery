import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notificacion_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Store unificado de notificaciones (push + internas)
class NotificacionesProvider extends ChangeNotifier {
  static const storageKey = 'inbox_notificaciones';

  final List<NotificacionModel> _notificaciones = [];
  bool _cargando = false;
  String? _error;

  List<NotificacionModel> get todas => List.unmodifiable(_notificaciones);
  List<NotificacionModel> get noLeidas =>
      _notificaciones.where((n) => !n.leida).toList(growable: false);
  bool get cargando => _cargando;
  String? get error => _error;

  NotificacionesProvider() {
    _cargarDesdeStorage();
  }

  Future<void> _cargarDesdeStorage() async {
    _cargando = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(storageKey) ?? [];
      _notificaciones
        ..clear()
        ..addAll(stored.map((s) => NotificacionModel.fromJson(jsonDecode(s))));
      _error = null;
    } catch (e) {
      _error = 'Error cargando notificaciones';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> recargar() async {
    await _cargarDesdeStorage();
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notificaciones
        .map((n) => jsonEncode(n.toJson()))
        .toList(growable: false);
    await prefs.setStringList(storageKey, data);
  }

  Future<void> limpiar() async {
    _notificaciones.clear();
    _cargando = false;
    _error = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  void agregar(NotificacionModel notificacion, {bool persistir = true}) {
    // Evitar duplicados por id
    _notificaciones.removeWhere((n) => n.id == notificacion.id);
    _notificaciones.insert(0, notificacion);
    notifyListeners();
    if (persistir) _persistir();
  }

  void agregarDesdePush(RemoteMessage message) {
    final titulo = message.notification?.title ?? 'Notificación';
    final cuerpo = message.notification?.body ?? '';
    final tipo = message.data['tipo'] ?? 'sistema';
    final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    agregar(NotificacionModel(
      id: id,
      titulo: titulo,
      mensaje: cuerpo,
      tipo: tipo,
      fecha: DateTime.now(),
      leida: false,
      metadata: message.data.isNotEmpty ? Map<String, dynamic>.from(message.data) : null,
    ));
  }

  void marcarComoLeida(String id) {
    final idx = _notificaciones.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notificaciones[idx] = _notificaciones[idx].copyWith(leida: true);
    notifyListeners();
    _persistir();
  }

  void marcarTodasComoLeidas() {
    for (var i = 0; i < _notificaciones.length; i++) {
      _notificaciones[i] = _notificaciones[i].copyWith(leida: true);
    }
    notifyListeners();
    _persistir();
  }

  void eliminar(String id) {
    _notificaciones.removeWhere((n) => n.id == id);
    notifyListeners();
    _persistir();
  }
}
