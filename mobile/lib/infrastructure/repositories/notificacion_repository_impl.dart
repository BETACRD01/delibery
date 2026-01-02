import '../../apis/notificaciones/notificaciones_api.dart';
import '../../domain/repositories/notificacion_repository.dart';
import '../../models/core/notificacion_model.dart';
import '../../models/core/paginated_response.dart';

class NotificacionRepositoryImpl implements NotificacionRepository {
  final NotificacionesApi _api;

  NotificacionRepositoryImpl({NotificacionesApi? api})
    : _api = api ?? NotificacionesApi();

  @override
  Future<PaginatedResponse<NotificacionModel>> getNotificaciones({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.getNotificaciones(page: page, limit: limit);

    // Standard DRF pagination parsing
    if (response is Map && response.containsKey('results')) {
      final List<dynamic> results = response['results'];
      final items = results.map((e) => NotificacionModel.fromJson(e)).toList();

      return PaginatedResponse(
        data: items,
        total: response['count'] ?? 0,
        next: response['next'],
        previous: response['previous'],
      );
    }

    // Fallback for list
    if (response is List) {
      final items = response.map((e) => NotificacionModel.fromJson(e)).toList();
      return PaginatedResponse(data: items, total: items.length);
    }

    return PaginatedResponse(data: [], total: 0);
  }

  @override
  Future<void> marcarLeida(String id) async {
    await _api.marcarLeida(id);
  }

  @override
  Future<void> marcarTodasLeidas() async {
    await _api.marcarTodasLeidas();
  }
}
