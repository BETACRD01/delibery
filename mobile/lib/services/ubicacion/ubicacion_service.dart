// lib/services/ubicacion/ubicacion_service.dart

import 'dart:async';
import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';

import 'package:mobile/services/core/api/api_exception.dart';
import '../repartidor/repartidor_service.dart';

/// Servicio de Ubicación para Repartidores
/// Maneja el rastreo en segundo plano, modos periodico y tiempo real.
class UbicacionService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final UbicacionService _instance = UbicacionService._internal();
  factory UbicacionService() => _instance;
  UbicacionService._internal();

  final _repartidorService = RepartidorService();

  // ---------------------------------------------------------------------------
  // ESTADO
  // ---------------------------------------------------------------------------

  Timer? _timer;
  StreamSubscription<Position>? _streamSubscription;
  Position? _ultimaUbicacion;
  Position? _ultimaUbicacionEnviada;
  DateTime? _ultimoEnvio;
  bool _estaActivo = false;
  ModoUbicacion _modoActual = ModoUbicacion.ninguno;

  // ---------------------------------------------------------------------------
  // CONFIGURACION DEFAULT
  // ---------------------------------------------------------------------------

  Duration intervaloPeriodico = const Duration(seconds: 30);
  Duration intervaloMinimoEnvio = const Duration(seconds: 20);
  int distanciaMinima = 5; // Metros
  LocationAccuracy precision = LocationAccuracy.high;

  // ---------------------------------------------------------------------------
  // CALLBACKS
  // ---------------------------------------------------------------------------

  Function(Position)? onUbicacionActualizada;
  Function(String)? onError;
  Function(bool)? onEstadoCambiado;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  bool get estaActivo => _estaActivo;
  ModoUbicacion get modoActual => _modoActual;
  Position? get ultimaUbicacion => _ultimaUbicacion;
  Future<bool> get tienePermisos async => await _verificarPermisos();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'UbicacionService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // VALIDACION DE ESTADO
  // ---------------------------------------------------------------------------

  Future<bool> _verificarAutenticacion() async {
    try {
      // Carga perezosa de tokens solo si es necesario
      if (!_repartidorService.client.tokensLoaded) {
        _log('Cargando tokens desde almacenamiento...');
        await _repartidorService.client.loadTokens();
      }

      final isAuth = _repartidorService.client.isAuthenticated;
      if (!isAuth) {
        _log('Usuario no autenticado, deteniendo envio de ubicacion');
        onError?.call('No estas autenticado');
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      _log('Error verificando autenticacion', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> _verificarServiciosActivos() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _log('Servicios de ubicacion desactivados');
        onError?.call('Los servicios de ubicacion estan desactivados');
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      _log('Error verificando servicios', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> _verificarPermisos() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _log('Permisos denegados permanentemente');
        onError?.call('Permisos de ubicacion bloqueados permanentemente');
        return false;
      }

      if (permission == LocationPermission.denied) {
        _log('Permisos denegados');
        onError?.call('Se requieren permisos de ubicacion');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      _log('Error verificando permisos', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> solicitarPermisos() async {
    final serviciosOk = await _verificarServiciosActivos();
    if (!serviciosOk) return false;
    return await _verificarPermisos();
  }

  // ---------------------------------------------------------------------------
  // OBTENCION DE UBICACION (SINGLE)
  // ---------------------------------------------------------------------------

  Future<Position?> obtenerUbicacionActual() async {
    try {
      if (!await solicitarPermisos()) return null;

      _log('Obteniendo ubicacion actual...');
      Position? position;

      // Reusar ubicación reciente si fue obtenida hace poco.
      if (_ultimaUbicacion?.timestamp != null) {
        final age = DateTime.now().difference(_ultimaUbicacion!.timestamp);
        if (age.inSeconds <= 10) {
          _log('Usando ubicacion cacheada (${age.inSeconds}s)');
          return _ultimaUbicacion;
        }
      }

      try {
        position =
            await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(accuracy: precision),
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Timeout obteniendo ubicacion');
              },
            );
      } catch (e) {
        // Fallback a última conocida si no se puede obtener la actual
        _log(
          'Fallo al obtener ubicacion en vivo, intentando ultima conocida',
          error: e,
        );
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _log('No se pudo obtener ninguna ubicacion (actual ni cacheada)');
        return null;
      }

      _ultimaUbicacion = position;
      _log('Ubicacion obtenida: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e, stackTrace) {
      _log('Error obteniendo ubicacion', error: e, stackTrace: stackTrace);
      onError?.call('Error al obtener ubicacion: $e');
      return null;
    }
  }

  Future<Position?> obtenerYEnviarUbicacion() async {
    try {
      final position = await obtenerUbicacionActual();
      if (position == null) return null;

      await _enviarUbicacionAlServidor(position);
      return position;
    } catch (e) {
      _log('Error en flujo obtenerYEnviar', error: e);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // MODO PERIODICO
  // ---------------------------------------------------------------------------

  Future<bool> iniciarEnvioPeriodico({Duration? intervalo}) async {
    try {
      _log('Iniciando envio periodico de ubicacion');

      if (!await _verificarAutenticacion()) return false;
      if (!await solicitarPermisos()) return false;

      detener(); // Limpiar estado previo

      if (intervalo != null) intervaloPeriodico = intervalo;

      // Envio inicial inmediato
      await obtenerYEnviarUbicacion();

      _timer = Timer.periodic(intervaloPeriodico, (_) async {
        await _enviarUbicacionPeriodica();
      });

      _estaActivo = true;
      _modoActual = ModoUbicacion.periodico;
      onEstadoCambiado?.call(true);

      _log(
        'Envio periodico iniciado (Intervalo: ${intervaloPeriodico.inSeconds}s)',
      );
      return true;
    } catch (e, stackTrace) {
      _log('Error iniciando envio periodico', error: e, stackTrace: stackTrace);
      onError?.call('Error al iniciar servicio: $e');
      return false;
    }
  }

  Future<void> _enviarUbicacionPeriodica() async {
    try {
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(accuracy: precision),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout en ubicacion periodica');
            },
          );

      _ultimaUbicacion = position;
      await _enviarUbicacionAlServidor(position);
    } catch (e) {
      _log('Error en ciclo periodico', error: e);
      // No notificamos onError aqui para no spammear al usuario en background
    }
  }

  // ---------------------------------------------------------------------------
  // MODO TIEMPO REAL
  // ---------------------------------------------------------------------------

  Future<bool> iniciarRastreoTiempoReal({
    int? distanciaMinima,
    LocationAccuracy? precision,
  }) async {
    try {
      _log('Iniciando rastreo en tiempo real');

      if (!await _verificarAutenticacion()) return false;
      if (!await solicitarPermisos()) return false;

      detener();

      if (distanciaMinima != null) this.distanciaMinima = distanciaMinima;
      if (precision != null) this.precision = precision;

      final settings = LocationSettings(
        accuracy: this.precision,
        distanceFilter: this.distanciaMinima,
      );

      _streamSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(_onNuevaUbicacionTiempoReal, onError: _onErrorTiempoReal);

      _estaActivo = true;
      _modoActual = ModoUbicacion.tiempoReal;
      onEstadoCambiado?.call(true);

      _log('Rastreo tiempo real iniciado');
      return true;
    } catch (e, stackTrace) {
      _log('Error iniciando tiempo real', error: e, stackTrace: stackTrace);
      onError?.call('Error al iniciar rastreo: $e');
      return false;
    }
  }

  void _onNuevaUbicacionTiempoReal(Position position) async {
    _ultimaUbicacion = position;
    await _enviarUbicacionAlServidor(position);
  }

  void _onErrorTiempoReal(Object error) {
    _log('Error en stream de ubicacion', error: error);
    onError?.call('Error en rastreo GPS');
  }

  // ---------------------------------------------------------------------------
  // ENVIO AL SERVIDOR
  // ---------------------------------------------------------------------------

  Future<void> _enviarUbicacionAlServidor(Position position) async {
    try {
      if (!await _verificarAutenticacion()) return;

      if (!_debeEnviarUbicacion(position)) {
        _log('[DEBUG] Ubicacion ignorada (muy frecuente o sin cambio)');
        return;
      }

      _log(
        '[DEBUG] Enviando ubicacion al backend: ${position.latitude}, ${position.longitude}',
      );

      if (!_latitudEnEcuador(position.latitude)) {
        _log(
          '[DEBUG] Latitud fuera de Ecuador (${position.latitude}), no se envía al backend',
        );
        return;
      }

      await _repartidorService.actualizarUbicacion(
        latitud: position.latitude,
        longitud: position.longitude,
      );

      _ultimaUbicacionEnviada = position;
      _ultimoEnvio = DateTime.now();
      _log('[DEBUG] Ubicacion enviada exitosamente al backend');
      onUbicacionActualizada?.call(position);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _log('Token invalido, deteniendo servicio');
        detener();
        onError?.call('Sesion expirada');
      } else {
        if (e.isNetworkError) {
          _log(
            'Sin conexion, ubicacion no enviada (se reintentara automaticamente)',
          );
          return;
        }
        _log('Error API enviando ubicacion: ${e.message}');
      }
    } catch (e) {
      _log('Error de conexion enviando ubicacion', error: e);
    }
  }

  bool _latitudEnEcuador(double lat) => lat >= -5.0 && lat <= 2.0;

  bool _debeEnviarUbicacion(Position position) {
    if (_ultimoEnvio == null || _ultimaUbicacionEnviada == null) {
      return true;
    }

    final elapsed = DateTime.now().difference(_ultimoEnvio!);
    if (elapsed < intervaloMinimoEnvio) {
      final last = _ultimaUbicacionEnviada!;
      final distance = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < distanciaMinima.toDouble()) {
        return false;
      }
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // CONTROL Y GESTION
  // ---------------------------------------------------------------------------

  void detener() {
    _log('Deteniendo servicio de ubicacion');
    _timer?.cancel();
    _timer = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;

    _estaActivo = false;
    _modoActual = ModoUbicacion.ninguno;
    onEstadoCambiado?.call(false);
  }

  void pausar() {
    if (!_estaActivo) return;
    _log('Pausando servicio');
    _timer?.cancel();
    _streamSubscription?.pause();
    _estaActivo = false;
    onEstadoCambiado?.call(false);
  }

  void reanudar() {
    if (_estaActivo) return;
    _log('Reanudando servicio');

    if (_modoActual == ModoUbicacion.periodico && _timer == null) {
      _timer = Timer.periodic(intervaloPeriodico, (_) async {
        await _enviarUbicacionPeriodica();
      });
    } else if (_modoActual == ModoUbicacion.tiempoReal) {
      _streamSubscription?.resume();
    }

    _estaActivo = true;
    onEstadoCambiado?.call(true);
  }

  // ---------------------------------------------------------------------------
  // CONFIGURACION DINAMICA
  // ---------------------------------------------------------------------------

  void cambiarIntervalo(Duration nuevoIntervalo) {
    intervaloPeriodico = nuevoIntervalo;
    if (_estaActivo && _modoActual == ModoUbicacion.periodico) {
      _log('Reiniciando con nuevo intervalo: ${nuevoIntervalo.inSeconds}s');
      iniciarEnvioPeriodico(intervalo: nuevoIntervalo);
    }
  }

  void cambiarDistanciaMinima(int nuevaDistancia) {
    distanciaMinima = nuevaDistancia;
    if (_estaActivo && _modoActual == ModoUbicacion.tiempoReal) {
      _log('Reiniciando con nueva distancia: ${nuevaDistancia}m');
      iniciarRastreoTiempoReal(distanciaMinima: nuevaDistancia);
    }
  }

  // ---------------------------------------------------------------------------
  // DEBUG & LIMPIEZA
  // ---------------------------------------------------------------------------

  void imprimirEstado() {
    _log('--- Estado UbicacionService ---');
    _log('Activo: $_estaActivo');
    _log('Modo: ${_modoActual.nombre}');
    _log(
      'Lat/Lon: ${_ultimaUbicacion?.latitude ?? "N/A"}, ${_ultimaUbicacion?.longitude ?? "N/A"}',
    );
  }

  Map<String, dynamic> obtenerEstadoResumen() {
    return {
      'activo': _estaActivo,
      'modo': _modoActual.nombre,
      'tiene_ubicacion': _ultimaUbicacion != null,
      'lat': _ultimaUbicacion?.latitude,
      'lng': _ultimaUbicacion?.longitude,
      'timestamp': _ultimaUbicacion?.timestamp.toIso8601String(),
    };
  }

  void dispose() {
    detener();
    onUbicacionActualizada = null;
    onError = null;
    onEstadoCambiado = null;
    _ultimaUbicacion = null;
  }
}

enum ModoUbicacion {
  ninguno,
  periodico,
  tiempoReal;

  String get nombre {
    switch (this) {
      case ModoUbicacion.ninguno:
        return 'Ninguno';
      case ModoUbicacion.periodico:
        return 'Periodico';
      case ModoUbicacion.tiempoReal:
        return 'Tiempo Real';
    }
  }
}
