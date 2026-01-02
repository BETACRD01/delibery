// lib/apis/admin/solicitudes_api.dart

import 'dart:developer' as developer;
import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API Service para gestión de Solicitudes de Cambio de Rol (Admin)
class SolicitudesAdminAPI {
  final ApiClient _client = ApiClient();

  // ==========================================================================
  // LISTAR SOLICITUDES (Admin)
  // ==========================================================================

  /// Obtiene todas las solicitudes de cambio de rol
  Future<Map<String, dynamic>> listarSolicitudes({
    String? estado, // PENDIENTE, ACEPTADA, RECHAZADA, REVERTIDA
    String? rolSolicitado, // PROVEEDOR, REPARTIDOR
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (estado != null) params['estado'] = estado;
      if (rolSolicitado != null) params['rol_solicitado'] = rolSolicitado;

      final url = Uri.parse(ApiConfig.adminSolicitudesCambioRol).replace(
        queryParameters: params.isNotEmpty ? params : null,
      );

      return await _client.get(url.toString());
    } catch (e) {
      developer.log('Error listando solicitudes: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }

  // ==========================================================================
  // OBTENER DETALLE DE SOLICITUD
  // ==========================================================================

  /// Obtiene el detalle completo de una solicitud
  Future<Map<String, dynamic>> obtenerDetalle(String solicitudId) async {
    try {
      final url = ApiConfig.adminSolicitudCambioRolDetalle(solicitudId);
      return await _client.get(url);
    } catch (e) {
      developer.log('Error obteniendo detalle: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }

  // ==========================================================================
  // ACEPTAR SOLICITUD
  // ==========================================================================

  /// Acepta una solicitud de cambio de rol
  Future<Map<String, dynamic>> aceptarSolicitud(
    String solicitudId, {
    String? motivoRespuesta,
  }) async {
    try {
      final url = ApiConfig.adminAceptarSolicitud(solicitudId);

      final body = <String, dynamic>{};
      if (motivoRespuesta != null && motivoRespuesta.isNotEmpty) {
        body['motivo_respuesta'] = motivoRespuesta;
      }

      return await _client.post(url, body);
    } catch (e) {
      developer.log('Error aceptando solicitud: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }

  // ==========================================================================
  // RECHAZAR SOLICITUD
  // ==========================================================================

  /// Rechaza una solicitud de cambio de rol
  Future<Map<String, dynamic>> rechazarSolicitud(
    String solicitudId, {
    String? motivoRespuesta,
  }) async {
    try {
      final url = ApiConfig.adminRechazarSolicitud(solicitudId);

      final body = <String, dynamic>{};
      if (motivoRespuesta != null && motivoRespuesta.isNotEmpty) {
        body['motivo_respuesta'] = motivoRespuesta;
      }

      return await _client.post(url, body);
    } catch (e) {
      developer.log('Error rechazando solicitud: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }

  // ==========================================================================
  // REVERTIR SOLICITUD
  // ==========================================================================

  /// Revierte una solicitud previamente aceptada
  Future<Map<String, dynamic>> revertirSolicitud(
    String solicitudId, {
    required String motivoReversion,
  }) async {
    try {
      final url = ApiConfig.adminSolicitudCambioRolDetalle(solicitudId);

      final body = {
        'motivo_reversion': motivoReversion,
      };

      // Endpoint personalizado para revertir
      final revertirUrl = '$url/revertir/';
      return await _client.post(revertirUrl, body);
    } catch (e) {
      developer.log('Error revirtiendo solicitud: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }

  // ==========================================================================
  // ELIMINAR SOLICITUD
  // ==========================================================================

  /// Elimina permanentemente una solicitud
  Future<bool> eliminarSolicitud(String solicitudId) async {
    try {
      final url = ApiConfig.adminSolicitudCambioRolDetalle(solicitudId);
      await _client.delete(url);
      return true;
    } catch (e) {
      developer.log('Error eliminando solicitud: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }

  // ==========================================================================
  // ESTADÍSTICAS (OPCIONAL)
  // ==========================================================================

  /// Obtiene estadísticas de solicitudes
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final url = ApiConfig.adminSolicitudesEstadisticas;
      return await _client.get(url);
    } catch (e) {
      developer.log('Error obteniendo estadísticas: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }

  // ==========================================================================
  // SOLICITUDES PENDIENTES (RÁPIDO ACCESO)
  // ==========================================================================

  /// Obtiene solo las solicitudes pendientes
  Future<List<dynamic>> listarPendientes() async {
    try {
      final url = ApiConfig.adminSolicitudesPendientes;
      final data = await _client.get(url);
      return (data['results'] as List?) ?? [];
    } catch (e) {
      developer.log('Error listando pendientes: $e', name: 'SolicitudesAPI');
      rethrow;
    }
  }
}
