// lib/apis/usuarios_api.dart

import 'dart:io';
import 'dart:developer' as developer;
import '../subapis/http_client.dart';
import '../../config/network/api_config.dart';
import '../helpers/api_exception.dart';

class UsuariosApi {
  // ---------------------------------------------------------------------------
  // SINGLETON & CLIENTE
  // ---------------------------------------------------------------------------

  static final UsuariosApi _instance = UsuariosApi._internal();
  factory UsuariosApi() => _instance;
  UsuariosApi._internal();

  final _client = ApiClient();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'UsuariosApi',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS (Mapeo interno para limpieza)
  // ---------------------------------------------------------------------------

  // Perfil
  static String get _perfil => ApiConfig.usuariosPerfil;
  static String get _actualizarPerfil => ApiConfig.usuariosActualizarPerfil;
  static String get _estadisticas => ApiConfig.usuariosEstadisticas;
  static String _perfilPublico(int id) => ApiConfig.usuariosPerfilPublico(id);
  static String get _fotoPerfil => ApiConfig.usuariosFotoPerfil;

  // Notificaciones
  static String get _fcmToken => ApiConfig.usuariosFCMToken;
  static String get _eliminarFcmToken => ApiConfig.usuariosEliminarFCMToken;
  static String get _estadoNotificaciones =>
      ApiConfig.usuariosEstadoNotificaciones;
  static String get _preferenciasNotificaciones =>
      ApiConfig.actualizarPreferencias;

  // Direcciones
  static String get _direcciones => ApiConfig.usuariosDirecciones;
  static String _direccion(String id) => ApiConfig.usuariosDireccion(id);
  static String get _direccionPredeterminada =>
      ApiConfig.usuariosDireccionPredeterminada;

  // Metodos de Pago
  static String get _metodosPago => ApiConfig.usuariosMetodosPago;
  static String _metodoPago(String id) => ApiConfig.usuariosMetodoPago(id);
  static String get _metodoPagoPredeterminado =>
      ApiConfig.usuariosMetodoPagoPredeterminado;

  // Ubicacion
  static String get _ubicacionActualizar =>
      ApiConfig.usuariosUbicacionActualizar;
  static String get _ubicacionMia => ApiConfig.usuariosUbicacionMia;

  // ---------------------------------------------------------------------------
  // 1. PERFIL DE USUARIO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> obtenerPerfil() async {
    _log('GET: Obtener perfil');
    try {
      final response = await _client.get(_perfil);
      final perfil = response['perfil'];
      if (perfil is Map<String, dynamic> && perfil.containsKey('telefono')) {
        _log('Perfil telefono (GET): ${perfil['telefono']}');
      }
      return response;
    } catch (e, stackTrace) {
      _log('Error obteniendo perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerPerfilPublico(int userId) async {
    _log('GET: Obtener perfil publico $userId');
    try {
      return await _client.get(_perfilPublico(userId));
    } catch (e, stackTrace) {
      _log('Error obteniendo perfil publico', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarPerfil(
    Map<String, dynamic> data,
  ) async {
    _log('PATCH: Actualizar perfil - Campos: ${data.keys.join(", ")}');
    if (data.containsKey('telefono')) {
      _log('Payload telefono: ${data['telefono']}');
    }
    try {
      final response = await _client.patch(_actualizarPerfil, data);
      final perfil = response['perfil'];
      if (perfil is Map<String, dynamic> && perfil.containsKey('telefono')) {
        _log('Perfil telefono (PATCH): ${perfil['telefono']}');
      }
      _log('Perfil actualizado correctamente');
      return response;
    } catch (e, stackTrace) {
      _log('Error actualizando perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      return await _client.get(_estadisticas);
    } catch (e, stackTrace) {
      _log('Error obteniendo estadisticas', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> subirFotoPerfil(File imagen) async {
    _log('POST: Subir foto de perfil');
    try {
      // No se requieren campos adicionales, solo el archivo
      final response = await _client.multipart('POST', _fotoPerfil, {}, {
        'foto_perfil': imagen,
      });
      _log('Foto subida correctamente');
      return response;
    } catch (e, stackTrace) {
      _log('Error subiendo foto', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> eliminarFotoPerfil() async {
    _log('DELETE: Eliminar foto de perfil');
    try {
      return await _client.delete(_fotoPerfil);
    } catch (e, stackTrace) {
      _log('Error eliminando foto', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. NOTIFICACIONES FCM
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> registrarFCMToken(String token) async {
    _log('POST: Registrar token FCM');
    try {
      return await _client.post(_fcmToken, {'fcm_token': token});
    } catch (e, stackTrace) {
      if (e is ApiException && e.isNetworkError) {
        _log('Sin conexion registrando token FCM');
        rethrow;
      } else {
        _log('Error registrando token FCM', error: e, stackTrace: stackTrace);
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> eliminarFCMToken() async {
    _log('DELETE: Eliminar token FCM');
    try {
      return await _client.delete(_eliminarFcmToken);
    } catch (e, stackTrace) {
      _log('Error eliminando token FCM', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerEstadoNotificaciones() async {
    try {
      return await _client.get(_estadoNotificaciones);
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo estado notificaciones',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerPreferenciasNotificaciones() async {
    try {
      return await _client.get(_preferenciasNotificaciones);
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo preferencias de notificaciones',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarPreferenciasNotificaciones(
    Map<String, dynamic> data,
  ) async {
    try {
      return await _client.patch(_preferenciasNotificaciones, data);
    } catch (e, stackTrace) {
      _log(
        'Error actualizando preferencias de notificaciones',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. DIRECCIONES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> listarDirecciones() async {
    _log('GET: Listar direcciones');
    try {
      final response = await _client.get(_direcciones);
      _log('Direcciones obtenidas: ${response['total'] ?? 0}');
      return response;
    } catch (e, stackTrace) {
      _log('Error listando direcciones', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> crearDireccion(Map<String, dynamic> data) async {
    _log('POST: Crear direccion - ${data['etiqueta']}');
    try {
      return await _client.post(_direcciones, data);
    } on ApiException catch (e) {
      if (e.errors.containsKey('etiqueta')) {
        final msg = e.errors['etiqueta'].toString();
        if (msg.contains('Ya tienes una dirección')) {
          return {'duplicado': true, 'mensaje': msg, 'data': data};
        }
      }
      rethrow;
    } catch (e, stackTrace) {
      _log('Error creando direccion', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerDireccion(String id) async {
    try {
      return await _client.get(_direccion(id));
    } catch (e, stackTrace) {
      _log('Error obteniendo direccion $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarDireccion(
    String id,
    Map<String, dynamic> data,
  ) async {
    _log('PATCH: Actualizar direccion $id');
    try {
      return await _client.patch(_direccion(id), data);
    } catch (e, stackTrace) {
      _log('Error actualizando direccion', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> eliminarDireccion(String id) async {
    _log('DELETE: Eliminar direccion $id');
    try {
      return await _client.delete(_direccion(id));
    } catch (e, stackTrace) {
      _log('Error eliminando direccion', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerDireccionPredeterminada() async {
    try {
      return await _client.get(_direccionPredeterminada);
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo direccion default',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. METODOS DE PAGO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> listarMetodosPago() async {
    _log('GET: Listar metodos de pago');
    try {
      return await _client.get(_metodosPago);
    } catch (e, stackTrace) {
      _log('Error listando pagos', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerMetodoPago(String id) async {
    try {
      return await _client.get(_metodoPago(id));
    } catch (e, stackTrace) {
      _log('Error obteniendo pago $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> crearMetodoPago(
    Map<String, dynamic> data,
  ) async {
    // Metodo simple sin archivos
    _log('POST: Crear metodo pago (Simple)');
    try {
      return await _client.post(_metodosPago, data);
    } catch (e, stackTrace) {
      _log('Error creando pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarMetodoPago(
    String id,
    Map<String, dynamic> data,
  ) async {
    _log('PATCH: Actualizar metodo pago (Simple) $id');
    try {
      return await _client.patch(_metodoPago(id), data);
    } catch (e, stackTrace) {
      _log('Error actualizando pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> eliminarMetodoPago(String id) async {
    _log('DELETE: Eliminar metodo pago $id');
    try {
      return await _client.delete(_metodoPago(id));
    } catch (e, stackTrace) {
      _log('Error eliminando pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerMetodoPagoPredeterminado() async {
    try {
      return await _client.get(_metodoPagoPredeterminado);
    } catch (e, stackTrace) {
      _log('Error obteniendo pago default', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. METODOS DE PAGO CON COMPROBANTES (Multipart)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> crearMetodoPagoConComprobante({
    required String tipo,
    required String alias,
    File? comprobanteImagen,
    String? observaciones,
    bool esPredeterminado = false,
  }) async {
    _log('POST: Crear pago con comprobante - Tipo: $tipo');

    try {
      final fields = {
        'tipo': tipo,
        'alias': alias,
        'es_predeterminado': esPredeterminado.toString(),
      };

      if (observaciones != null && observaciones.isNotEmpty) {
        fields['observaciones'] = observaciones;
      }

      final files = <String, File>{};
      if (comprobanteImagen != null) {
        files['comprobante_pago'] = comprobanteImagen;
      }

      return await _client.multipart('POST', _metodosPago, fields, files);
    } catch (e, stackTrace) {
      _log('Error creando pago multipart', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarMetodoPagoConComprobante({
    required String metodoId,
    String? tipo,
    String? alias,
    File? comprobanteImagen,
    String? observaciones,
    bool? esPredeterminado,
  }) async {
    _log('PATCH: Actualizar pago multipart $metodoId');

    try {
      final fields = <String, String>{};
      if (tipo != null) fields['tipo'] = tipo;
      if (alias != null) fields['alias'] = alias;
      if (observaciones != null) fields['observaciones'] = observaciones;
      if (esPredeterminado != null) {
        fields['es_predeterminado'] = esPredeterminado.toString();
      }

      final files = <String, File>{};
      if (comprobanteImagen != null) {
        files['comprobante_pago'] = comprobanteImagen;
      }

      return await _client.multipart(
        'PATCH',
        _metodoPago(metodoId),
        fields,
        files,
      );
    } catch (e, stackTrace) {
      _log(
        'Error actualizando pago multipart',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 6. UBICACION
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> actualizarUbicacion(
    double lat,
    double lon,
  ) async {
    // No logueamos esto siempre para no saturar la consola si es en tiempo real
    try {
      final data = {'latitud': lat.toString(), 'longitud': lon.toString()};
      return await _client.post(_ubicacionActualizar, data);
    } catch (e) {
      // Error silencioso en update de ubicacion
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerMiUbicacion() async {
    try {
      return await _client.get(_ubicacionMia);
    } catch (e, stackTrace) {
      _log('Error obteniendo ubicacion', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES
  // ---------------------------------------------------------------------------

  bool get tieneConexion => _client.isAuthenticated;

  Future<void> limpiarCache() async {
    _log('Limpiando cache de usuarios...');
  }
}
