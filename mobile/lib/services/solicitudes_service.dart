// lib/services/solicitudes_service.dart

import 'dart:developer' as developer;
import '../config/api_config.dart';
import '../apis/subapis/http_client.dart';
import '../apis/helpers/api_exception.dart';

/// Servicio para la gestion de solicitudes de cambio de rol (Usuario y Admin)
class SolicitudesService {
  final ApiClient _client = ApiClient();

  void _log(String message, {Object? error}) {
    developer.log(message, name: 'SolicitudesService', error: error);
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS USUARIO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> obtenerMisSolicitudes() async {
    try {
      _log('Obteniendo solicitudes propias...');
      final response = await _client.get(ApiConfig.usuariosSolicitudesCambioRol);
      _log('Solicitudes obtenidas: ${response['total'] ?? 0}');
      return response;
    } on ApiException catch (e) {
      _log('Error obteniendo solicitudes: ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> crearSolicitudProveedor({
    required String ruc,
    required String nombreComercial,
    required String tipoNegocio,
    required String descripcionNegocio,
    required String motivo,
    String? horarioApertura,
    String? horarioCierre,
  }) async {
    try {
      _log('Creando solicitud PROVEEDOR: $nombreComercial');

      if (ruc.length != 13) {
        throw ApiException(
          statusCode: 400,
          message: 'El RUC debe tener exactamente 13 digitos',
          errors: {'ruc': ['Longitud incorrecta']},
          stackTrace: StackTrace.current,
        );
      }

      if (motivo.length < 10) {
        throw ApiException(
          statusCode: 400,
          message: 'El motivo debe ser mas detallado (min. 10 caracteres)',
          errors: {'motivo': ['Muy corto']},
          stackTrace: StackTrace.current,
        );
      }

      final Map<String, dynamic> body = {
        'rol_solicitado': 'PROVEEDOR',
        'ruc': ruc,
        'nombre_comercial': nombreComercial,
        'tipo_negocio': tipoNegocio,
        'descripcion_negocio': descripcionNegocio,
        'motivo': motivo,
      };

      if (horarioApertura != null) body['horario_apertura'] = horarioApertura;
      if (horarioCierre != null) body['horario_cierre'] = horarioCierre;

      final response = await _client.post(ApiConfig.usuariosSolicitudesCambioRol, body);
      _log('Solicitud PROVEEDOR creada exitosamente');
      return response;

    } on ApiException catch (e) {
      _log('Error creando solicitud PROVEEDOR', error: e);
      // 🔥 AQUI ESTÁ LA CLAVE: Usamos el mismo helper de limpieza que creamos antes
      _procesarYLanzarError(e); 
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> crearSolicitudRepartidor({
    required String cedulaIdentidad,
    required String tipoVehiculo,
    required String zonaCobertura,
    required String motivo,
    Map<String, dynamic>? disponibilidad,
  }) async {
    try {
      _log('Creando solicitud REPARTIDOR: $cedulaIdentidad');

      if (cedulaIdentidad.length < 10) {
        throw ApiException(
          statusCode: 400,
          message: 'La cedula debe tener al menos 10 digitos',
          errors: {'cedula_identidad': ['Longitud incorrecta']},
          stackTrace: StackTrace.current,
        );
      }

      final Map<String, dynamic> body = {
        'rol_solicitado': 'REPARTIDOR',
        'cedula_identidad': cedulaIdentidad,
        'tipo_vehiculo': tipoVehiculo,
        'zona_cobertura': zonaCobertura,
        'motivo': motivo,
      };

      if (disponibilidad != null) {
        body['disponibilidad'] = disponibilidad;
      }

      final response = await _client.post(ApiConfig.usuariosSolicitudesCambioRol, body);
      _log('Solicitud REPARTIDOR creada exitosamente');
      return response;

    } on ApiException catch (e) {
      _log('Error creando solicitud REPARTIDOR', error: e);
      _procesarYLanzarError(e); // Usamos la función auxiliar
      rethrow;
    }
  }

  /// Helper para extraer el mensaje limpio de Django y lanzarlo a la UI
  void _procesarYLanzarError(ApiException e) {
    String mensajeLimpio = e.message;

    // Corrección de Warnings: e.errors no es nullable, así que accedemos directo
    if (e.errors.isNotEmpty) {
      if (e.errors.containsKey('detalles')) {
        mensajeLimpio = e.errors['detalles'].toString();
      } else if (e.errors.containsKey('non_field_errors')) {
        mensajeLimpio = e.errors['non_field_errors'].toString();
      } else {
        // Tomar el primer error de campo disponible
        final primerKey = e.errors.keys.first;
        final primerValor = e.errors[primerKey];
        mensajeLimpio = "$primerKey: $primerValor";
      }
    }

    // Limpieza de formato de lista Python ['...']
    mensajeLimpio = mensajeLimpio
        .replaceAll("['", "")
        .replaceAll("']", "")
        .replaceAll('["', "")
        .replaceAll('"]', "");

    throw Exception(mensajeLimpio);
  }

  Future<Map<String, dynamic>> obtenerDetalleSolicitud(String id) async {
    try {
      _log('Obteniendo detalle solicitud: $id');
      return await _client.get(ApiConfig.usuariosSolicitudCambioRolDetalle(id));
    } on ApiException catch (e) {
      _log('Error obteniendo detalle', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    try {
      _log('Cambiando rol activo a: $nuevoRol');
      final response = await _client.post(
        ApiConfig.usuariosCambiarRolActivo, 
        {'nuevo_rol': nuevoRol}
      );
      _log('Rol activo cambiado exitosamente');
      return response;
    } on ApiException catch (e) {
      _log('Error cambiando rol', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerMisRoles() async {
    try {
      _log('Obteniendo roles disponibles...');
      return await _client.get(ApiConfig.usuariosMisRoles);
    } on ApiException catch (e) {
      _log('Error obteniendo roles', error: e);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS ADMIN
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> adminListarSolicitudes({
    String? estado,
    String? rolSolicitado,
  }) async {
    try {
      _log('[ADMIN] Listando solicitudes...');
      
      String url = ApiConfig.adminSolicitudesCambioRol;
      final params = <String, String>{};
      
      if (estado != null) params['estado'] = estado;
      if (rolSolicitado != null) params['rol_solicitado'] = rolSolicitado;

      if (params.isNotEmpty) {
        final query = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$query';
      }

      return await _client.get(url);
    } on ApiException catch (e) {
      _log('[ADMIN] Error listando solicitudes', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> adminObtenerDetalle(String id) async {
    try {
      _log('[ADMIN] Obteniendo detalle: $id');
      return await _client.get(ApiConfig.adminSolicitudCambioRolDetalle(id));
    } on ApiException catch (e) {
      _log('[ADMIN] Error obteniendo detalle', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> adminAceptarSolicitud(String id, {String? motivo}) async {
    try {
      _log('[ADMIN] Aceptando solicitud: $id');
      final body = <String, dynamic>{};
      if (motivo != null) body['motivo_respuesta'] = motivo;

      return await _client.post(ApiConfig.adminAceptarSolicitud(id), body);
    } on ApiException catch (e) {
      _log('[ADMIN] Error aceptando solicitud', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> adminRechazarSolicitud(String id, {required String motivo}) async {
    try {
      _log('[ADMIN] Rechazando solicitud: $id');
      
      if (motivo.trim().isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'El motivo de rechazo es obligatorio',
          errors: {'motivo_respuesta': ['Requerido']},
          stackTrace: StackTrace.current,
        );
      }

      return await _client.post(
        ApiConfig.adminRechazarSolicitud(id), 
        {'motivo_respuesta': motivo}
      );
    } on ApiException catch (e) {
      _log('[ADMIN] Error rechazando solicitud', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> adminListarPendientes() async {
    try {
      _log('[ADMIN] Listando pendientes...');
      return await _client.get(ApiConfig.adminSolicitudesPendientes);
    } on ApiException catch (e) {
      _log('[ADMIN] Error listando pendientes', error: e);
      rethrow;
    }
  }
  

  Future<Map<String, dynamic>> adminObtenerEstadisticas() async {
    try {
      _log('[ADMIN] Obteniendo estadisticas...');
      return await _client.get(ApiConfig.adminSolicitudesEstadisticas);
    } on ApiException catch (e) {
      _log('[ADMIN] Error obteniendo estadisticas', error: e);
      rethrow;
    }
  }
}