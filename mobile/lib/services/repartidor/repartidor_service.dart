// lib/services/repartidor/repartidor_service.dart

import 'dart:io';
import 'dart:developer' as developer;
import '../../apis/subapis/http_client.dart';
import '../../apis/helpers/api_exception.dart';
import '../../config/api_config.dart';
import '../../models/repartidor.dart';
import '../../models/pedido_repartidor.dart';

class RepartidorService {
  // Singleton
  static final RepartidorService _instance = RepartidorService._internal();
  factory RepartidorService() => _instance;
  RepartidorService._internal();

  final _client = ApiClient();

  // Cache
  PerfilRepartidorModel? _perfilCache;
  EstadisticasRepartidorModel? _estadisticasCache;
  List<VehiculoRepartidorModel>? _vehiculosCache;

  ApiClient get client => _client;

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'RepartidorService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // PERFIL
  // ---------------------------------------------------------------------------

  Future<PerfilRepartidorModel> obtenerPerfil({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _perfilCache != null) {
        return _perfilCache!;
      }

      final response = await _client.get(ApiConfig.repartidorPerfil);
      final perfil = PerfilRepartidorModel.fromJson(response);
      _perfilCache = perfil;

      return perfil;
    } catch (e, stackTrace) {
      if (e is ApiException && e.isNetworkError) {
        _log('Sin conexion al obtener perfil');
      } else {
        _log('Error al obtener perfil', error: e, stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  Future<PerfilRepartidorModel> actualizarPerfil({
    String? telefono,
    File? fotoPerfil,
  }) async {
    try {
      Map<String, dynamic> response;

      if (fotoPerfil != null) {
        final fields = <String, String>{};
        if (telefono != null && telefono.isNotEmpty) {
          fields['telefono'] = telefono;
        }

        response = await _client.multipart(
          'PATCH',
          ApiConfig.repartidorPerfilActualizar,
          fields,
          {'foto_perfil': fotoPerfil},
        );
      } else {
        final data = <String, dynamic>{};
        if (telefono != null && telefono.isNotEmpty) {
          data['telefono'] = telefono;
        }

        response = await _client.patch(
          ApiConfig.repartidorPerfilActualizar,
          data,
        );
      }

      final perfil = PerfilRepartidorModel.fromJson(response['perfil']);
      _perfilCache = perfil;

      return perfil;
    } catch (e, stackTrace) {
      _log('Error actualizando perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<EstadisticasRepartidorModel> obtenerEstadisticas({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _estadisticasCache != null) {
        return _estadisticasCache!;
      }

      final response = await _client.get(ApiConfig.repartidorEstadisticas);
      final estadisticas = EstadisticasRepartidorModel.fromJson(response);
      _estadisticasCache = estadisticas;

      return estadisticas;
    } catch (e, stackTrace) {
      _log('Error obteniendo estadisticas', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN DE ESTADO
  // ---------------------------------------------------------------------------

  Future<CambioEstadoResponse> cambiarEstado(
    EstadoRepartidor nuevoEstado,
  ) async {
    try {
      final response = await _client.patch(ApiConfig.repartidorEstado, {
        'estado': nuevoEstado.valor,
      });

      final cambioEstado = CambioEstadoResponse.fromJson(response);

      if (_perfilCache != null) {
        _perfilCache = _perfilCache!.copyWith(estado: nuevoEstado);
      }

      return cambioEstado;
    } catch (e, stackTrace) {
      _log('Error cambiando estado', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<EstadoLogModel>> obtenerHistorialEstados({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final url = _buildUrlWithParams(ApiConfig.repartidorEstadoHistorial, {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await _client.get(url);
      final results = response['results'] ?? response;

      return (results as List)
          .map((log) => EstadoLogModel.fromJson(log))
          .toList();
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo historial estados',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UBICACIÓN
  // ---------------------------------------------------------------------------

  Future<UbicacionActualizadaResponse> actualizarUbicacion({
    required double latitud,
    required double longitud,
  }) async {
    try {
      final response = await _client.patch(ApiConfig.repartidorUbicacion, {
        'latitud': latitud,
        'longitud': longitud,
      });

      final ubicacion = UbicacionActualizadaResponse.fromJson(response);

      if (_perfilCache != null) {
        _perfilCache = _perfilCache!.copyWith(
          latitud: latitud,
          longitud: longitud,
          ultimaLocalizacion: ubicacion.timestamp,
        );
      }

      return ubicacion;
    } catch (e, stackTrace) {
      if (e is ApiException && e.isNetworkError) {
        _log('Sin conexion al actualizar ubicacion, se reintentara luego');
      } else {
        // CORRECCIÓN 1: Se usa stackTrace para evitar 'unused_catch_stack'
        _log('Error actualizando ubicacion', error: e, stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  Future<List<UbicacionHistorialModel>> obtenerHistorialUbicaciones({
    String? fechaInicio,
    String? fechaFin,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (fechaInicio != null) params['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) params['fecha_fin'] = fechaFin;

      final url = _buildUrlWithParams(
        ApiConfig.repartidorUbicacionHistorial,
        params,
      );
      final response = await _client.get(url);
      final results = response['results'] ?? response;

      return (results as List)
          .map((ub) => UbicacionHistorialModel.fromJson(ub))
          .toList();
    } catch (e, stackTrace) {
      _log('Error historial ubicaciones', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PEDIDOS
  // ---------------------------------------------------------------------------

  Future<PedidosDisponiblesResponse> obtenerPedidosDisponibles({
    double radioKm = 15.0,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final params = {'radio': radioKm.toString()};
      if (latitud != null && longitud != null) {
        params['latitud'] = latitud.toString();
        params['longitud'] = longitud.toString();
      }

      final url = _buildUrlWithParams(
        ApiConfig.repartidorPedidosDisponibles,
        params,
      );
      final response = await _client.get(url);

      return PedidosDisponiblesResponse.fromJson(response);
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo pedidos disponibles',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene el detalle COMPLETO de un pedido (solo si está asignado al repartidor)
  /// Este endpoint devuelve datos sensibles del cliente (teléfono, dirección exacta)
  /// que solo están disponibles DESPUÉS de aceptar el pedido
  Future<PedidoDetalladoRepartidor> obtenerDetallePedido(int pedidoId) async {
    try {
      final response = await _client.get(
        ApiConfig.repartidorPedidoDetalle(pedidoId),
      );
      return PedidoDetalladoRepartidor.fromJson(response);
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo detalle pedido $pedidoId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene los pedidos ACTIVOS (asignados) del repartidor
  Future<List<PedidoDetalladoRepartidor>> obtenerMisPedidosActivos() async {
    try {
      final response = await _client.get(ApiConfig.repartidorMisPedidos);
      final pedidos = (response['pedidos'] as List)
          .map((p) => PedidoDetalladoRepartidor.fromJson(p))
          .toList();
      return pedidos;
    } catch (e, stackTrace) {
      if (e is ApiException && e.isNetworkError) {
        _log('Sin conexion al obtener pedidos activos');
      } else {
        _log(
          'Error obteniendo mis pedidos activos',
          error: e,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<PedidoDetalladoRepartidor> aceptarPedido(int pedidoId) async {
    try {
      final response = await _client.post(
        ApiConfig.repartidorPedidoAceptar(pedidoId),
        {},
      );
      // El backend ahora devuelve el objeto 'pedido' completo
      if (response['pedido'] != null) {
        return PedidoDetalladoRepartidor.fromJson(response['pedido']);
      }
      // Fallback si el backend no devuelve el pedido (versiones viejas?)
      return await obtenerDetallePedido(pedidoId);
    } catch (e, stackTrace) {
      _log(
        'Error aceptando pedido $pedidoId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rechazarPedido(
    int pedidoId, {
    String motivo = 'Muy lejos',
  }) async {
    try {
      return await _client.post(ApiConfig.repartidorPedidoRechazar(pedidoId), {
        'motivo': motivo,
      });
    } catch (e, stackTrace) {
      _log(
        'Error rechazando pedido $pedidoId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> calificarCliente({
    required int pedidoId,
    required double puntuacion,
    String? comentario,
  }) async {
    try {
      final data = <String, dynamic>{'puntuacion': puntuacion};
      if (comentario != null && comentario.isNotEmpty) {
        data['comentario'] = comentario;
      }

      return await _client.post(
        ApiConfig.repartidorCalificarCliente(pedidoId),
        data,
      );
    } catch (e, stackTrace) {
      _log('Error calificando cliente', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VEHÍCULOS
  // ---------------------------------------------------------------------------

  Future<List<VehiculoRepartidorModel>> listarVehiculos({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _vehiculosCache != null) {
        return _vehiculosCache!;
      }

      final response = await _client.get(ApiConfig.repartidorVehiculos);
      final vehiculosResponse = VehiculosResponse.fromJson(response);
      _vehiculosCache = vehiculosResponse.vehiculos;

      return vehiculosResponse.vehiculos;
    } catch (e, stackTrace) {
      _log('Error listando vehiculos', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<VehiculoRepartidorModel> crearVehiculo({
    required TipoVehiculo tipo,
    String? placa,
    bool activo = false,
  }) async {
    try {
      final data = {'tipo': tipo.valor, 'activo': activo};
      if (placa != null && placa.isNotEmpty) {
        data['placa'] = placa.toUpperCase();
      }

      final response = await _client.post(
        ApiConfig.repartidorVehiculosCrear,
        data,
      );
      final vehiculo = VehiculoRepartidorModel.fromJson(response['vehiculo']);
      _vehiculosCache = null;

      return vehiculo;
    } catch (e, stackTrace) {
      _log('Error creando vehiculo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<VehiculoRepartidorModel> obtenerVehiculo(int vehiculoId) async {
    try {
      final response = await _client.get(
        ApiConfig.repartidorVehiculo(vehiculoId),
      );
      return VehiculoRepartidorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo vehiculo $vehiculoId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<VehiculoRepartidorModel> actualizarDatosVehiculo({
    TipoVehiculo? tipo,
    String? placa,
    File? licenciaFoto,
  }) async {
    try {
      Map<String, dynamic> response;
      final endpoint = '${ApiConfig.repartidorVehiculos}/actualizar-datos/';

      if (licenciaFoto != null) {
        final fields = <String, String>{};
        if (tipo != null) fields['tipo'] = tipo.valor;
        if (placa != null && placa.isNotEmpty) {
          fields['placa'] = placa.toUpperCase();
        }

        response = await _client.multipart('PATCH', endpoint, fields, {
          'licencia_foto': licenciaFoto,
        });
      } else {
        final data = <String, dynamic>{};
        if (tipo != null) data['tipo'] = tipo.valor;
        if (placa != null && placa.isNotEmpty) {
          data['placa'] = placa.toUpperCase();
        }

        response = await _client.patch(endpoint, data);
      }

      final vehiculo = VehiculoRepartidorModel.fromJson(response['vehiculo']);
      _vehiculosCache = null;

      return vehiculo;
    } catch (e, stackTrace) {
      _log(
        'Error actualizando datos vehiculo',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<VehiculoRepartidorModel> actualizarVehiculo(
    int vehiculoId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.patch(
        ApiConfig.repartidorVehiculo(vehiculoId),
        data,
      );
      final vehiculo = VehiculoRepartidorModel.fromJson(response['vehiculo']);
      _vehiculosCache = null;

      return vehiculo;
    } catch (e, stackTrace) {
      _log('Error actualizando vehiculo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> eliminarVehiculo(int vehiculoId) async {
    try {
      await _client.delete(ApiConfig.repartidorVehiculo(vehiculoId));
      _vehiculosCache = null;
    } catch (e, stackTrace) {
      _log('Error eliminando vehiculo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<VehiculoRepartidorModel> activarVehiculo(int vehiculoId) async {
    try {
      final response = await _client.patch(
        ApiConfig.repartidorVehiculoActivar(vehiculoId),
        {},
      );
      final vehiculo = VehiculoRepartidorModel.fromJson(response['vehiculo']);
      _vehiculosCache = null;

      return vehiculo;
    } catch (e, stackTrace) {
      _log('Error activando vehiculo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // CALIFICACIONES
  // ---------------------------------------------------------------------------

  Future<List<CalificacionRepartidorModel>> listarCalificaciones({
    int? puntuacion,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (puntuacion != null) params['puntuacion'] = puntuacion.toString();

      final url = _buildUrlWithParams(
        ApiConfig.repartidorCalificaciones,
        params,
      );
      final response = await _client.get(url);
      final results = response['results'] ?? response;

      return (results as List)
          .map((c) => CalificacionRepartidorModel.fromJson(c))
          .toList();
    } catch (e, stackTrace) {
      _log('Error listando calificaciones', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<PerfilRepartidorModel> eliminarFotoPerfil() async {
    try {
      final response = await _client.patch(
        ApiConfig.repartidorPerfilActualizar,
        {'eliminar_foto_perfil': true},
      );
      final perfil = PerfilRepartidorModel.fromJson(response['perfil']);
      _perfilCache = perfil;

      return perfil;
    } catch (e, stackTrace) {
      _log('Error eliminando foto perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // MI REPARTIDOR & USUARIO
  // ---------------------------------------------------------------------------

  Future<PerfilRepartidorModel> obtenerMiRepartidor({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _perfilCache != null) {
        return _perfilCache!;
      }

      final response = await _client.get(ApiConfig.miRepartidor);
      final perfil = PerfilRepartidorModel.fromJson(response);
      _perfilCache = perfil;

      return perfil;
    } catch (e, stackTrace) {
      _log('Error obteniendo mi repartidor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<PerfilRepartidorModel> actualizarMiPerfil({
    String? cedula,
    String? telefono,
    String? vehiculo,
    File? fotoPerfil,
    bool eliminarFoto = false,
  }) async {
    try {
      Map<String, dynamic> response;

      if (eliminarFoto) {
        response = await _client.patch(ApiConfig.miRepartidorEditarPerfil, {
          'eliminar_foto_perfil': true,
        });
      } else if (fotoPerfil != null) {
        final fields = <String, String>{};
        if (cedula != null && cedula.isNotEmpty) fields['cedula'] = cedula;
        if (telefono != null && telefono.isNotEmpty) {
          fields['telefono'] = telefono;
        }
        if (vehiculo != null && vehiculo.isNotEmpty) {
          fields['vehiculo'] = vehiculo;
        }

        response = await _client.multipart(
          'PATCH',
          ApiConfig.miRepartidorEditarPerfil,
          fields,
          {'foto_perfil': fotoPerfil},
        );
      } else {
        final data = <String, dynamic>{};
        if (cedula != null && cedula.isNotEmpty) data['cedula'] = cedula;
        if (telefono != null && telefono.isNotEmpty) {
          data['telefono'] = telefono;
        }
        if (vehiculo != null && vehiculo.isNotEmpty) {
          data['vehiculo'] = vehiculo;
        }

        if (data.isEmpty) {
          throw ApiException(
            statusCode: 400,
            message: 'Sin datos para actualizar',
          );
        }

        response = await _client.patch(
          ApiConfig.miRepartidorEditarPerfil,
          data,
        );
      }

      PerfilRepartidorModel perfil;
      if (response.containsKey('repartidor')) {
        perfil = PerfilRepartidorModel.fromJson(response['repartidor']);
      } else if (response['id'] != null) {
        perfil = PerfilRepartidorModel.fromJson(response);
      } else {
        perfil = await obtenerMiRepartidor(forzarRecarga: true);
      }
      _perfilCache = perfil;

      return perfil;
    } catch (e, stackTrace) {
      _log('Error actualizando mi perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<PerfilRepartidorModel> actualizarMiContacto({
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (email != null && email.isNotEmpty) {
        data['email'] = email.trim().toLowerCase();
      }
      if (firstName != null && firstName.isNotEmpty) {
        data['first_name'] = firstName.trim();
      }
      if (lastName != null && lastName.isNotEmpty) {
        data['last_name'] = lastName.trim();
      }

      if (data.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'Sin datos para actualizar',
        );
      }

      final response = await _client.patch(
        ApiConfig.miRepartidorEditarContacto,
        data,
      );

      PerfilRepartidorModel perfil;
      if (response.containsKey('repartidor')) {
        perfil = PerfilRepartidorModel.fromJson(response['repartidor']);
      } else if (response['id'] != null) {
        perfil = PerfilRepartidorModel.fromJson(response);
      } else {
        perfil = await obtenerMiRepartidor(forzarRecarga: true);
      }
      _perfilCache = perfil;

      return perfil;
    } catch (e, stackTrace) {
      _log('Error actualizando contacto', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<PerfilRepartidorModel> actualizarPerfilCompleto({
    String? cedula,
    String? telefono,
    File? fotoPerfil,
    bool eliminarFoto = false,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      PerfilRepartidorModel? perfilActualizado;
      final hayDatosPerfil =
          cedula != null ||
          telefono != null ||
          fotoPerfil != null ||
          eliminarFoto;

      if (hayDatosPerfil) {
        perfilActualizado = await actualizarMiPerfil(
          cedula: cedula,
          telefono: telefono,
          fotoPerfil: fotoPerfil,
          eliminarFoto: eliminarFoto,
        );
      }

      final hayDatosContacto =
          email != null || firstName != null || lastName != null;
      if (hayDatosContacto) {
        perfilActualizado = await actualizarMiContacto(
          email: email,
          firstName: firstName,
          lastName: lastName,
        );
      }

      // CORRECCIÓN 2: Uso de asignación condicional (??=)
      perfilActualizado ??= await obtenerMiRepartidor(forzarRecarga: true);

      return perfilActualizado;
    } catch (e, stackTrace) {
      _log(
        'Error actualizando perfil completo',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // CACHE & UTILIDADES
  // ---------------------------------------------------------------------------

  void limpiarCache() {
    _perfilCache = null;
    _estadisticasCache = null;
    _vehiculosCache = null;
  }

  void limpiarCachePerfil() {
    _perfilCache = null;
    _estadisticasCache = null;
  }

  void limpiarCacheVehiculos() => _vehiculosCache = null;

  PerfilRepartidorModel? get perfilActual => _perfilCache;
  EstadisticasRepartidorModel? get estadisticasActuales => _estadisticasCache;
  List<VehiculoRepartidorModel>? get vehiculosActuales => _vehiculosCache;
  bool get tienePerfil => _perfilCache != null;
  bool get estaDisponible =>
      _perfilCache?.estado == EstadoRepartidor.disponible;
  bool get estaOcupado => _perfilCache?.estado == EstadoRepartidor.ocupado;
  bool get puedeRecibirPedidos => _perfilCache?.puedeRecibirPedidos ?? false;

  VehiculoRepartidorModel? get vehiculoActivo {
    return _perfilCache?.vehiculoActivo ??
        _vehiculosCache?.firstWhere(
          (v) => v.activo,
          orElse: () => _vehiculosCache!.first,
        );
  }

  String _buildUrlWithParams(String endpoint, Map<String, String>? params) {
    if (params == null || params.isEmpty) return endpoint;
    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    return endpoint.contains('?')
        ? '$endpoint&$queryString'
        : '$endpoint?$queryString';
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES
  // ---------------------------------------------------------------------------

  bool get estaAutenticado => _client.isAuthenticated;
  bool get estaVerificado => _perfilCache?.verificado ?? false;
  bool get estaActivo => _perfilCache?.activo ?? false;
  bool get tieneUbicacion => _perfilCache?.tieneUbicacion ?? false;

  int get totalEntregas => _perfilCache?.entregasCompletadas ?? 0;
  double get calificacionPromedio => _perfilCache?.calificacionPromedio ?? 5.0;
  int get totalCalificaciones => _perfilCache?.totalCalificaciones ?? 0;
  String get nivelExperiencia => _perfilCache?.nivelExperiencia ?? 'Sin datos';

  Future<CambioEstadoResponse> marcarDisponible() async =>
      await cambiarEstado(EstadoRepartidor.disponible);
  Future<CambioEstadoResponse> marcarOcupado() async =>
      await cambiarEstado(EstadoRepartidor.ocupado);
  Future<CambioEstadoResponse> marcarFueraServicio() async =>
      await cambiarEstado(EstadoRepartidor.fueraServicio);

  Future<CambioEstadoResponse> toggleDisponibilidad() async {
    final estadoActual = _perfilCache?.estado ?? EstadoRepartidor.fueraServicio;
    return estadoActual == EstadoRepartidor.disponible
        ? await marcarFueraServicio()
        : await marcarDisponible();
  }

  Future<void> recargarTodo() async {
    try {
      await Future.wait([
        obtenerPerfil(forzarRecarga: true),
        obtenerEstadisticas(forzarRecarga: true),
        listarVehiculos(forzarRecarga: true),
      ]);
    } catch (e, stackTrace) {
      _log('Error recargando todo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void imprimirEstado() {
    _log(
      'Estado Repartidor: Auth:$estaAutenticado, Perfil:$tienePerfil, Estado:${_perfilCache?.estado.nombre}',
    );
  }

  // CORRECCIÓN 3: Uso de llaves {} en estructuras de control
  bool validarDatosMinimos() {
    if (!estaAutenticado) {
      return false;
    }
    if (!tienePerfil) {
      return false;
    }
    if (!estaVerificado) {
      return false;
    }
    if (!estaActivo) {
      return false;
    }
    if (vehiculoActivo == null) {
      return false;
    }
    return true;
  }

  List<String> obtenerAdvertencias() {
    final advertencias = <String>[];
    if (!estaAutenticado) {
      advertencias.add('No autenticado');
    } else {
      if (!tienePerfil) {
        advertencias.add('Perfil no cargado');
      }
      if (!estaVerificado) {
        advertencias.add('Cuenta no verificada');
      }
      if (!estaActivo) {
        advertencias.add('Cuenta desactivada');
      }
      if (!tieneUbicacion) {
        advertencias.add('Sin ubicación registrada');
      }
      if (vehiculoActivo == null) {
        advertencias.add('Sin vehículo activo');
      }
    }
    return advertencias;
  }

  // ---------------------------------------------------------------------------
  // MARCAR PEDIDO COMO ENTREGADO
  // ---------------------------------------------------------------------------

  /// Marca un pedido como en camino
  /// El repartidor ya recogió el pedido y está en camino hacia el cliente
  Future<Map<String, dynamic>> marcarPedidoEnCamino(int pedidoId) async {
    try {
      _log('Marcando pedido $pedidoId como en camino');

      final url = ApiConfig.repartidorPedidoMarcarEnCamino(pedidoId);
      final response = await _client.post(url, {});

      _log('Pedido $pedidoId marcado como en camino exitosamente');
      return response;
    } catch (e, stackTrace) {
      _log(
        'Error al marcar pedido como en camino',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Marca un pedido como entregado
  /// Para pedidos con método de pago TRANSFERENCIA, requiere imagen del comprobante
  Future<Map<String, dynamic>> marcarPedidoEntregado({
    required int pedidoId,
    File? imagenEvidencia,
  }) async {
    try {
      _log('Marcando pedido $pedidoId como entregado');

      final url = ApiConfig.repartidorPedidoMarcarEntregado(pedidoId);

      Map<String, dynamic> response;

      // Si hay imagen de evidencia, usar multipart
      if (imagenEvidencia != null) {
        response = await _client.multipart(
          'POST',
          url,
          {}, // No hay campos adicionales
          {'imagen_evidencia': imagenEvidencia},
        );
      } else {
        // Sin imagen, usar POST normal
        response = await _client.post(url, {});
      }

      _log('Pedido $pedidoId marcado como entregado exitosamente');
      return response;
    } catch (e, stackTrace) {
      _log(
        'Error al marcar pedido como entregado',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Obtiene el historial de entregas completadas del repartidor
  /// Incluye información detallada: fechas, comisiones, comprobantes, etc.
  Future<Map<String, dynamic>> obtenerHistorialEntregas({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      _log('Obteniendo historial de entregas');

      final queryParams = <String, String>{};
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      final url = ApiConfig.repartidorHistorialEntregas;
      final urlWithParams = queryParams.isEmpty
          ? url
          : '$url?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await _client.get(urlWithParams);

      _log('Historial de entregas obtenido exitosamente');
      return response;
    } on ApiException catch (e, stackTrace) {
      _log(
        'Error al obtener historial de entregas (API)',
        error: e,
        stackTrace: stackTrace,
      );

      // Si el endpoint devuelve 404/403 cuando no hay historial o permisos,
      // respondemos con estructura vacía para no romper la UI.
      if (e.isNotFoundError || e.isForbiddenError) {
        return {
          'results': <dynamic>[],
          'total_entregas': 0,
          'total_comisiones': 0,
          'count': 0,
          'next': null,
          'previous': null,
        };
      }
      rethrow;
    } catch (e, stackTrace) {
      _log(
        'Error al obtener historial de entregas',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
