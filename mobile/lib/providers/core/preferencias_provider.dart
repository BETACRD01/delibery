import 'package:flutter/material.dart';
import '../../apis/auth/auth_api.dart';

class PreferenciasProvider extends ChangeNotifier {
  final _api = AuthApi();

  bool _notificacionesEmail = true;
  bool _notificacionesPush = true;
  bool _modoSilencio = false;
  bool _cargando = true;

  bool get notificacionesEmail => _notificacionesEmail;
  bool get notificacionesPush => _notificacionesPush;
  bool get modoSilencio => _modoSilencio;
  bool get cargando => _cargando;

  PreferenciasProvider() {
    cargarPreferencias();
  }

  Future<void> cargarPreferencias() async {
    try {
      _cargando = true;
      notifyListeners();

      final res = await _api.getPreferencias();
      // El backend puede devolver {notificaciones_email: true, ...}

      _notificacionesEmail = res['notificaciones_email'] ?? true;
      _notificacionesPush = res['notificaciones_push'] ?? true;
      _modoSilencio = res['modo_silencio'] ?? false;
    } catch (e) {
      debugPrint('Error cargando preferencias: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> updateEmail(bool value) async {
    _notificacionesEmail = value;
    notifyListeners();
    await _syncBackend({'notificaciones_email': value});
  }

  Future<void> updatePush(bool value) async {
    _notificacionesPush = value;
    notifyListeners();
    await _syncBackend({'notificaciones_push': value});
  }

  Future<void> updateModoSilencio(bool value) async {
    _modoSilencio = value;
    notifyListeners();
    await _syncBackend({'modo_silencio': value});
  }

  Future<void> _syncBackend(Map<String, dynamic> data) async {
    try {
      await _api.updatePreferencias(data);
    } catch (e) {
      debugPrint('Error sincronizando preferencias: $e');
      // Podríamos revertir el cambio local si falla, pero por UX es mejor reintentar o ignorar
    }
  }
}
