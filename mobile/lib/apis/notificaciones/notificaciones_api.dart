import '../../config/network/api_config.dart';
import 'package:mobile/services/core/api/http_client.dart';

class NotificacionesApi {
  static final NotificacionesApi _instance = NotificacionesApi._internal();
  factory NotificacionesApi() => _instance;
  NotificacionesApi._internal();

  final _client = ApiClient();

  /// Obtiene lista de notificaciones paginada
  Future<dynamic> getNotificaciones({int page = 1, int limit = 20}) async {
    return await _client.get(
      '${ApiConfig.notificaciones}?page=$page&page_size=$limit',
    );
  }

  /// Marca una notificación como leída
  Future<void> marcarLeida(String id) async {
    await _client.post('${ApiConfig.notificaciones}$id/marcar_leida/', {});
  }

  /// Marca todas como leídas
  Future<void> marcarTodasLeidas() async {
    await _client.post('${ApiConfig.notificaciones}marcar_todas_leidas/', {});
  }
}
