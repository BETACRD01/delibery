// lib/services/calificaciones/calificaciones_service.dart

import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';
import '../../models/social/resena_model.dart';

/// Servicio centralizado para calificaciones y reseñas.
class CalificacionesService {
  final ApiClient _client = ApiClient();

  /// Obtiene calificaciones de una entidad (repartidor, producto, cliente, proveedor).
  Future<ResenaListResponse> obtenerCalificaciones({
    required String entityType,
    required int entityId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url =
        '${ApiConfig.calificacionesEntidad(entityType, entityId)}?page=$page&page_size=$pageSize';

    final response = await _client.get(url);
    return ResenaListResponse.fromJson(response);
  }

  /// Obtiene resumen estadístico de calificaciones de una entidad.
  Future<RatingSummary> obtenerResumen({
    required String entityType,
    required int entityId,
  }) async {
    final url = ApiConfig.calificacionesResumen(entityType, entityId);
    final response = await _client.get(url);
    return RatingSummary.fromJson(response);
  }

  /// Calificar cliente (desde repartidor).
  Future<void> calificarCliente({
    required int pedidoId,
    required int estrellas,
    String? comentario,
  }) async {
    await _client.post(
      ApiConfig.calificacionesRapida,
      {
        'pedido_id': pedidoId,
        'tipo': 'repartidor_a_cliente',
        'estrellas': estrellas,
        if (comentario != null && comentario.trim().isNotEmpty)
          'comentario': comentario.trim(),
      },
    );
  }
}
