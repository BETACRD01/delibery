import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/repositories/notificacion_repository.dart';
import '../../infrastructure/repositories/notificacion_repository_impl.dart';
import '../../models/core/notificacion_model.dart';

/// Store unificado de notificaciones (API + Infinite Scroll)
class NotificacionesProvider extends ChangeNotifier {
  final NotificacionRepository _repository;

  NotificacionesProvider({NotificacionRepository? repository})
    : _repository = repository ?? NotificacionRepositoryImpl();

  // State
  List<NotificacionModel> _notificaciones = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _limit = 20;

  // Getters
  List<NotificacionModel> get todas => List.unmodifiable(_notificaciones);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Aliases for compatibility
  bool get cargando => _isLoading;
  List<NotificacionModel> get noLeidas =>
      _notificaciones.where((n) => !n.leida).toList();

  // Computed
  int get conteoNoLeidas => _notificaciones.where((n) => !n.leida).length;

  /// Carga inicial / pull-to-refresh
  Future<void> recargar() async {
    _currentPage = 1;
    _hasMore = true;
    _notificaciones = [];
    _error = null;
    notifyListeners();
    await cargarSiguientePagina();
  }

  /// Paginación
  Future<void> cargarSiguientePagina() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.getNotificaciones(
        page: _currentPage,
        limit: _limit,
      );

      final newItems = response.data;

      // Merge evitando duplicados (si la API devuelve alguno repetido por race condition)
      final existingIds = _notificaciones.map((e) => e.id).toSet();
      final toAdd = newItems.where((e) => !existingIds.contains(e.id)).toList();

      _notificaciones.addAll(toAdd);

      if (newItems.length < _limit || response.next == null) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manejo de Push en tiempo real (agrega al inicio)
  void agregarDesdePush(RemoteMessage message) {
    final titulo = message.notification?.title ?? 'Notificación';
    final cuerpo = message.notification?.body ?? '';
    final tipo = message.data['tipo'] ?? 'sistema';
    // ID temporal o del mensaje
    final id =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final nueva = NotificacionModel(
      id: id,
      titulo: titulo,
      mensaje: cuerpo,
      tipo: tipo,
      fecha: DateTime.now(),
      leida: false,
      metadata: message.data.isNotEmpty
          ? Map<String, dynamic>.from(message.data)
          : null,
    );

    _notificaciones.insert(0, nueva);
    notifyListeners();
  }

  /// Marca una como leída (Optimista)
  Future<void> marcarComoLeida(String id) async {
    final idx = _notificaciones.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    // Update optimista
    _notificaciones[idx] = _notificaciones[idx].copyWith(leida: true);
    notifyListeners();

    try {
      await _repository.marcarLeida(id);
    } catch (e) {
      // Revertir si falla? Por ahora no para mejor UX
      debugPrint('Error marcando leida: $e');
    }
  }

  /// Marca todas como leídas (Optimista)
  Future<void> marcarTodasComoLeidas() async {
    bool hasUnread = _notificaciones.any((n) => !n.leida);
    if (!hasUnread) return;

    // Optimista
    for (var i = 0; i < _notificaciones.length; i++) {
      if (!_notificaciones[i].leida) {
        _notificaciones[i] = _notificaciones[i].copyWith(leida: true);
      }
    }
    notifyListeners();

    try {
      await _repository.marcarTodasLeidas();
    } catch (e) {
      debugPrint('Error marcando todas leidas: $e');
    }
  }

  Future<void> limpiar() async {
    _notificaciones.clear();
    _currentPage = 1;
    notifyListeners();
  }

  void eliminar(String id) {
    _notificaciones.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
