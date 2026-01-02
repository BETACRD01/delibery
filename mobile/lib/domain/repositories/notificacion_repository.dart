import '../../models/core/notificacion_model.dart';
import '../../models/core/paginated_response.dart';

abstract class NotificacionRepository {
  Future<PaginatedResponse<NotificacionModel>> getNotificaciones({
    int page = 1,
    int limit = 20,
  });

  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas();
}
