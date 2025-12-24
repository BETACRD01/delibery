// lib/apis/solicitudes/solicitudes_api.dart

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de solicitudes de cambio de rol
class SolicitudesApi {
  static final SolicitudesApi _instance = SolicitudesApi._internal();
  factory SolicitudesApi() => _instance;
  SolicitudesApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // USUARIO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMisSolicitudes() async {
    return await _client.get(ApiConfig.usuariosSolicitudesCambioRol);
  }

  Future<Map<String, dynamic>> crearSolicitud(Map<String, dynamic> body) async {
    return await _client.post(ApiConfig.usuariosSolicitudesCambioRol, body);
  }

  Future<Map<String, dynamic>> getDetalleSolicitud(String id) async {
    return await _client.get(ApiConfig.usuariosSolicitudCambioRolDetalle(id));
  }

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    return await _client.post(ApiConfig.usuariosCambiarRolActivo, {
      'nuevo_rol': nuevoRol,
    });
  }

  Future<Map<String, dynamic>> getMisRoles() async {
    return await _client.get(ApiConfig.usuariosMisRoles);
  }

  // ---------------------------------------------------------------------------
  // ADMIN
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> adminListarSolicitudes(String url) async {
    return await _client.get(url);
  }

  Future<Map<String, dynamic>> adminObtenerDetalle(String id) async {
    return await _client.get(ApiConfig.adminSolicitudCambioRolDetalle(id));
  }

  Future<Map<String, dynamic>> adminAceptarSolicitud(
    String id,
    Map<String, dynamic> body,
  ) async {
    return await _client.post(ApiConfig.adminAceptarSolicitud(id), body);
  }

  Future<Map<String, dynamic>> adminRechazarSolicitud(
    String id,
    Map<String, dynamic> body,
  ) async {
    return await _client.post(ApiConfig.adminRechazarSolicitud(id), body);
  }

  Future<Map<String, dynamic>> adminListarPendientes() async {
    return await _client.get(ApiConfig.adminSolicitudesPendientes);
  }

  Future<Map<String, dynamic>> adminObtenerEstadisticas() async {
    return await _client.get(ApiConfig.adminSolicitudesEstadisticas);
  }
}
