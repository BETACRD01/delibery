// lib/services/servicio_usuario.dart

import 'dart:io';
import 'dart:developer' as developer;
import '../apis/user/usuarios_api.dart';
import '../apis/user/rifas_api.dart';
import '../apis/user/rifas_usuarios_api.dart';
import '../models/usuario.dart';
import '../apis/helpers/api_exception.dart';

/// Servicio de Usuario: Capa de logica de negocio para la gestion de usuarios.
/// Conecta la API con la UI, maneja modelos, cache y errores.
class UsuarioService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final UsuarioService _instance = UsuarioService._internal();
  factory UsuarioService() => _instance;
  UsuarioService._internal();

  final _api = UsuariosApi();
  final _rifasApi = RifasApi();
  final _rifasUsuariosApi = RifasUsuariosApi();

  // ---------------------------------------------------------------------------
  // ESTADO / CACHE
  // ---------------------------------------------------------------------------

  PerfilModel? _perfilCache;
  List<DireccionModel>? _direccionesCache;
  List<MetodoPagoModel>? _metodosPagoCache;
  EstadisticasModel? _estadisticasCache;
  Map<String, dynamic>? _rifasCache;
  Map<String, dynamic>? _rifaActivaCache;
  Map<String, bool>? _preferenciasNotificacionesCache;

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'UsuarioService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // GESTION DE PERFIL
  // ---------------------------------------------------------------------------

  Future<PerfilModel> obtenerPerfil({bool forzarRecarga = false}) async {
    try {
      if (!forzarRecarga && _perfilCache != null) {
        _log('Retornando perfil desde cache');
        return _perfilCache!;
      }

      _log('Obteniendo perfil desde API...');
      final response = await _api.obtenerPerfil();
      final perfilData = response['perfil'] as Map<String, dynamic>;
      _perfilCache = PerfilModel.fromJson(perfilData);

      return _perfilCache!;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'Error inesperado obteniendo perfil',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener perfil',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<PerfilModel> obtenerPerfilPublico(int userId) async {
    try {
      _log('Obteniendo perfil publico de usuario $userId');
      final response = await _api.obtenerPerfilPublico(userId);
      final perfilData = response['perfil'] as Map<String, dynamic>;
      return PerfilModel.fromJson(perfilData);
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error obteniendo perfil publico', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener perfil publico',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<PerfilModel> actualizarPerfil(Map<String, dynamic> data) async {
    try {
      _log('Actualizando perfil...');
      final response = await _api.actualizarPerfil(data);
      final perfilData = response['perfil'] as Map<String, dynamic>;
      _perfilCache = PerfilModel.fromJson(perfilData);
      return _perfilCache!;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error actualizando perfil', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al actualizar perfil',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<EstadisticasModel> obtenerEstadisticas({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _estadisticasCache != null) {
        return _estadisticasCache!;
      }

      _log('Obteniendo estadisticas...');
      final response = await _api.obtenerEstadisticas();
      final estadisticasData = response['estadisticas'] as Map<String, dynamic>;
      _estadisticasCache = EstadisticasModel.fromJson(estadisticasData);
      return _estadisticasCache!;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error obteniendo estadisticas', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener estadisticas',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, bool> _normalizarPreferencias(Map<String, dynamic> data) {
    return {
      'notificaciones_push': data['notificaciones_push'] as bool? ?? true,
      'notificaciones_email': data['notificaciones_email'] as bool? ?? true,
      'notificaciones_marketing':
          data['notificaciones_marketing'] as bool? ?? true,
    };
  }

  Future<Map<String, bool>> obtenerPreferenciasNotificaciones({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _preferenciasNotificacionesCache != null) {
        return _preferenciasNotificacionesCache!;
      }

      final response = await _api.obtenerPreferenciasNotificaciones();
      final preferencias = _normalizarPreferencias(response);
      _preferenciasNotificacionesCache = preferencias;
      return preferencias;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo preferencias de notificaciones',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener preferencias',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<Map<String, bool>> actualizarPreferenciasNotificaciones(
    Map<String, bool> data,
  ) async {
    try {
      final response = await _api.actualizarPreferenciasNotificaciones(data);
      final payload = response['preferencias'] ?? response;
      final preferencias = _normalizarPreferencias(
        payload as Map<String, dynamic>,
      );
      _preferenciasNotificacionesCache = preferencias;
      return preferencias;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error actualizando preferencias', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al actualizar preferencias',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>> obtenerRifasParticipaciones({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _rifasCache != null) return _rifasCache!;

      final data = await _rifasApi.misParticipaciones();
      _rifasCache = data;
      return data;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo participaciones de rifas',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener rifas',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>?> obtenerRifaActiva({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _rifaActivaCache != null) return _rifaActivaCache;
      final data = await _rifasUsuariosApi.obtenerRifaActiva();
      _rifaActivaCache = data;
      return data;
    } on ApiException catch (e) {
      // Si no hay rifa activa o la ruta no está disponible, devolvemos null
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e, stackTrace) {
      _log('Error obteniendo rifa activa', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener rifa activa',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GESTION DE DIRECCIONES
  // ---------------------------------------------------------------------------

  Future<List<DireccionModel>> listarDirecciones({
    bool forzarRecarga = false,
  }) async {
    try {
      if (forzarRecarga) {
        _direccionesCache = null;
      }

      if (_direccionesCache != null && _direccionesCache!.isNotEmpty) {
        _log('Retornando ${_direccionesCache!.length} direcciones desde cache');
        return _direccionesCache!;
      }

      _log('Obteniendo direcciones desde API...');
      final response = await _api.listarDirecciones();
      _log('Payload direcciones: $response');

      // Soporte para diferentes estructuras de respuesta (paginacion o lista directa)
      final direccionesData = response['direcciones'] ?? response['results'];

      if (direccionesData == null || direccionesData is! List) {
        _log('Respuesta vacia o invalida para direcciones');
        _direccionesCache = [];
        return [];
      }

      final List<DireccionModel> direcciones = [];
      for (var i = 0; i < direccionesData.length; i++) {
        try {
          final json = direccionesData[i] as Map<String, dynamic>;
          direcciones.add(DireccionModel.fromJson(json));
        } catch (e) {
          _log('Error parseando direccion en indice $i: $e');
        }
      }

      _direccionesCache = direcciones;
      return direcciones;
    } on ApiException {
      _direccionesCache = null;
      rethrow;
    } catch (e, stackTrace) {
      _log('Error listando direcciones', error: e, stackTrace: stackTrace);
      _direccionesCache = null;
      throw ApiException(
        statusCode: 0,
        message: 'Error al listar direcciones',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<DireccionModel> crearDireccion(DireccionModel direccion) async {
    try {
      _log('Creando direccion: ${direccion.etiqueta}');
      final response = await _api.crearDireccion(direccion.toCreateJson());

      Map<String, dynamic>? data;
      if (response.containsKey('direccion')) {
        data = response['direccion'] as Map<String, dynamic>;
      } else if (response.containsKey('id')) {
        data = response;
      } else if (response.containsKey('data')) {
        data = response['data'] as Map<String, dynamic>;
      }

      if (data == null) {
        throw ApiException(
          statusCode: 0,
          message: 'Respuesta invalida del servidor',
          errors: {'error': 'Estructura de respuesta desconocida'},
          stackTrace: StackTrace.current,
        );
      }

      _direccionesCache = null; // Invalidar cache
      return DireccionModel.fromJson(data);
    } on ApiException catch (e) {
      _direccionesCache = null;

      // Deteccion de duplicados para auto-correccion
      final esDuplicada = e.errors.toString().contains(
        'Ya tienes una dirección',
      );

      if (esDuplicada) {
        _log(
          'Direccion duplicada detectada, intentando actualizar existente...',
        );
        final lista = await listarDirecciones(forzarRecarga: true);

        try {
          final existente = lista.firstWhere(
            (d) => d.etiqueta == direccion.etiqueta,
          );
          return await actualizarDireccion(
            existente.id,
            direccion.toCreateJson(),
          );
        } catch (_) {
          // Si no se encuentra, relanzar error original
          rethrow;
        }
      }
      rethrow;
    } catch (e, stackTrace) {
      _log('Error creando direccion', error: e, stackTrace: stackTrace);
      _direccionesCache = null;
      throw ApiException(
        statusCode: 0,
        message: 'Error al crear direccion',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<DireccionModel> obtenerDireccion(String id) async {
    try {
      final response = await _api.obtenerDireccion(id);
      return DireccionModel.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error obteniendo direccion', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener direccion',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<DireccionModel> actualizarDireccion(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      _direccionesCache = null;
      final response = await _api.actualizarDireccion(id, data);
      final direccionData = response['direccion'] as Map<String, dynamic>;
      return DireccionModel.fromJson(direccionData);
    } on ApiException {
      _direccionesCache = null;
      rethrow;
    } catch (e, stackTrace) {
      _log('Error actualizando direccion', error: e, stackTrace: stackTrace);
      _direccionesCache = null;
      throw ApiException(
        statusCode: 0,
        message: 'Error al actualizar direccion',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> eliminarDireccion(String id) async {
    try {
      await _api.eliminarDireccion(id);
      _direccionesCache = null;
    } on ApiException {
      _direccionesCache = null;
      rethrow;
    } catch (e, stackTrace) {
      _log('Error eliminando direccion', error: e, stackTrace: stackTrace);
      _direccionesCache = null;
      throw ApiException(
        statusCode: 0,
        message: 'Error al eliminar direccion',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<DireccionModel?> obtenerDireccionPredeterminada() async {
    try {
      final response = await _api.obtenerDireccionPredeterminada();
      final direccionData = response['direccion'] as Map<String, dynamic>;
      return DireccionModel.fromJson(direccionData);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo direccion default',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener direccion predeterminada',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GESTION DE METODOS DE PAGO
  // ---------------------------------------------------------------------------

  Future<List<MetodoPagoModel>> listarMetodosPago({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _metodosPagoCache != null) {
        return _metodosPagoCache!;
      }

      final response = await _api.listarMetodosPago();
      final metodosData = response['metodos_pago'] as List;

      final metodos = metodosData
          .map((json) => MetodoPagoModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _metodosPagoCache = metodos;
      return metodos;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error listando metodos de pago', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al listar metodos de pago',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<MetodoPagoModel> crearMetodoPago(MetodoPagoModel metodo) async {
    try {
      final response = await _api.crearMetodoPago(metodo.toCreateJson());
      final metodoData = response['metodo_pago'] as Map<String, dynamic>;
      _metodosPagoCache = null;
      return MetodoPagoModel.fromJson(metodoData);
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error creando metodo de pago', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al crear metodo de pago',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<MetodoPagoModel> crearMetodoPagoConComprobante({
    required String tipo,
    required String alias,
    File? comprobanteImagen,
    String? observaciones,
    bool esPredeterminado = false,
  }) async {
    try {
      // Validaciones de negocio
      if (tipo == 'transferencia' && comprobanteImagen == null) {
        throw ApiException(
          statusCode: 400,
          message: 'Las transferencias requieren comprobante',
          errors: {'comprobante_pago': 'Archivo requerido'},
          stackTrace: StackTrace.current,
        );
      }

      if (alias.trim().isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'El alias es requerido',
          errors: {'alias': 'Campo requerido'},
          stackTrace: StackTrace.current,
        );
      }

      if (comprobanteImagen != null && !await comprobanteImagen.exists()) {
        throw ApiException(
          statusCode: 400,
          message: 'El archivo de comprobante no existe',
          errors: {'comprobante_pago': 'Archivo invalido'},
          stackTrace: StackTrace.current,
        );
      }

      final response = await _api.crearMetodoPagoConComprobante(
        tipo: tipo,
        alias: alias,
        comprobanteImagen: comprobanteImagen,
        observaciones: observaciones,
        esPredeterminado: esPredeterminado,
      );

      final metodoData = response['metodo_pago'] as Map<String, dynamic>;
      _metodosPagoCache = null;
      return MetodoPagoModel.fromJson(metodoData);
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'Error creando metodo con comprobante',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        statusCode: 0,
        message: 'Error al crear metodo de pago',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<MetodoPagoModel> actualizarMetodoPago(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.actualizarMetodoPago(id, data);
      final metodoData = response['metodo_pago'] as Map<String, dynamic>;
      _metodosPagoCache = null;
      return MetodoPagoModel.fromJson(metodoData);
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'Error actualizando metodo de pago',
        error: e,
        stackTrace: stackTrace,
      );
      throw ApiException(
        statusCode: 0,
        message: 'Error al actualizar metodo de pago',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> eliminarMetodoPago(String id) async {
    try {
      await _api.eliminarMetodoPago(id);
      _metodosPagoCache = null;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error eliminando metodo de pago', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al eliminar metodo de pago',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<MetodoPagoModel?> obtenerMetodoPagoPredeterminado() async {
    try {
      final response = await _api.obtenerMetodoPagoPredeterminado();
      final metodoData = response['metodo_pago'] as Map<String, dynamic>;
      return MetodoPagoModel.fromJson(metodoData);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e, stackTrace) {
      _log('Error obteniendo pago default', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener metodo de pago predeterminado',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GESTION DE FOTO DE PERFIL
  // ---------------------------------------------------------------------------

  Future<PerfilModel> subirFotoPerfil(File imagen) async {
    try {
      final response = await _api.subirFotoPerfil(imagen);
      final perfilData = response['perfil'] as Map<String, dynamic>;
      _perfilCache = PerfilModel.fromJson(perfilData);
      return _perfilCache!;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error subiendo foto', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al subir foto de perfil',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<PerfilModel> eliminarFotoPerfil() async {
    try {
      final response = await _api.eliminarFotoPerfil();
      final perfilData = response['perfil'] as Map<String, dynamic>;
      _perfilCache = PerfilModel.fromJson(perfilData);
      return _perfilCache!;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error eliminando foto', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al eliminar foto',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES Y CACHE
  // ---------------------------------------------------------------------------

  void limpiarCache() {
    _log('Limpiando toda la cache del servicio');
    _perfilCache = null;
    _direccionesCache = null;
    _metodosPagoCache = null;
    _estadisticasCache = null;
  }

  void limpiarCachePerfil() {
    _perfilCache = null;
    _estadisticasCache = null;
  }

  void limpiarCacheDirecciones() {
    _log('Limpiando cache de direcciones');
    _direccionesCache = null;
  }

  void limpiarCacheMetodosPago() {
    _metodosPagoCache = null;
  }

  // Getters de estado cacheado
  PerfilModel? get perfilActual => _perfilCache;
  List<DireccionModel>? get direccionesActuales => _direccionesCache;
  List<MetodoPagoModel>? get metodosPagoActuales => _metodosPagoCache;
  EstadisticasModel? get estadisticasActuales => _estadisticasCache;

  // ---------------------------------------------------------------------------
  // DEBUG
  // ---------------------------------------------------------------------------

  void imprimirEstadoDebug() {
    _log('--- Estado UsuarioService ---');
    _log('Perfil: ${_perfilCache != null ? "OK" : "Null"}');
    _log('Estadisticas: ${_estadisticasCache != null ? "OK" : "Null"}');
    _log('Direcciones: ${_direccionesCache?.length ?? "Null"}');
    _log('Metodos Pago: ${_metodosPagoCache?.length ?? "Null"}');
  }
}
