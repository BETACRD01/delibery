// lib/apis/calificaciones/calificaciones_api.dart

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de calificaciones
class CalificacionesApi {
  static final CalificacionesApi _instance = CalificacionesApi._internal();
  factory CalificacionesApi() => _instance;
  CalificacionesApi._internal();

  final _client = ApiClient();

  /// Obtiene calificaciones de una entidad
  Future<Map<String, dynamic>> getCalificaciones(String url) async {
    return await _client.get(url);
  }

  /// Obtiene resumen de calificaciones
  Future<Map<String, dynamic>> getResumen(
    String entityType,
    int entityId,
  ) async {
    return await _client.get(
      ApiConfig.calificacionesResumen(entityType, entityId),
    );
  }

  /// Calificar cliente (desde repartidor)
  Future<void> calificarCliente(Map<String, dynamic> data) async {
    await _client.post(ApiConfig.calificacionesRapida, data);
  }
}
