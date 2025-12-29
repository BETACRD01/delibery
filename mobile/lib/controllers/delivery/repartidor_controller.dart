// lib/controllers/delivery/repartidor_controller.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../services/repartidor/repartidor_service.dart';
import '../../config/api_config.dart';
import '../../apis/subapis/http_client.dart';
import '../../apis/helpers/api_exception.dart';
import '../../models/repartidor.dart';
import '../../models/pedido_repartidor.dart';
import '../../models/entrega_historial.dart';
import 'dart:developer' as developer;
import '../../services/ubicacion/ubicacion_service.dart';

/// Controller para gestionar la lógica de negocio del repartidor
/// Separa completamente la lógica de la UI
class RepartidorController extends ChangeNotifier {
  // ============================================
  // SERVICIOS
  // ============================================
  final AuthService _authService;
  final RepartidorService _repartidorService;
  final ApiClient _apiClient;
  final UbicacionService _ubicacionService = UbicacionService();

  // ============================================
  // ESTADO
  // ============================================
  PerfilRepartidorModel? _perfil;
  EstadisticasRepartidorModel? _estadisticas;
  List<PedidoDisponible>? _pendientes;
  List<PedidoDetalladoRepartidor>? _pedidosActivos;
  HistorialEntregasResponse? _historialEntregas;
  bool _loadingHistorial = false;
  bool _loading = true;
  String? _error;
  bool _disposed = false;

  // Smart Polling
  Timer? _pollingTimer;
  DateTime? _lastPedidosUpdate;
  DateTime? _lastPedidosActivosUpdate;
  static const _pollingInterval = Duration(seconds: 30);
  static const _minUpdateInterval = Duration(seconds: 15);
  bool _isPollingActive = false;

  // ============================================
  // GETTERS
  // ============================================
  PerfilRepartidorModel? get perfil => _perfil;
  EstadisticasRepartidorModel? get estadisticas => _estadisticas;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _apiClient.isAuthenticated;
  List<PedidoDisponible>? get pendientes => _pendientes;
  List<PedidoDetalladoRepartidor>? get pedidosActivos => _pedidosActivos;
  HistorialEntregasResponse? get historialEntregas => _historialEntregas;
  bool get loadingHistorial => _loadingHistorial;
  List<EntregaHistorial> get entregas => _historialEntregas?.entregas ?? [];
  int get totalEntregasHistorial => _historialEntregas?.totalEntregas ?? 0;
  double get totalComisionesHistorial =>
      _historialEntregas?.totalComisiones ?? 0.0;

  EstadoRepartidor get estadoActual =>
      _perfil?.estado ?? EstadoRepartidor.fueraServicio;

  bool get estaDisponible => estadoActual == EstadoRepartidor.disponible;

  // Estadísticas calculadas
  int get totalEntregas => _perfil?.entregasCompletadas ?? 0;
  double get rating => _perfil?.calificacionPromedio ?? 0.0;
  double get gananciasEstimadas => totalEntregas * 5.0; // Ejemplo de cálculo

  // ============================================
  // CONSTRUCTOR
  // ============================================
  RepartidorController({
    AuthService? authService,
    RepartidorService? repartidorService,
    ApiClient? apiClient,
  }) : _authService = authService ?? AuthService(),
       _repartidorService = repartidorService ?? RepartidorService(),
       _apiClient = apiClient ?? ApiClient();

  // ============================================
  // VERIFICACIÓN DE ACCESO
  // ============================================

  /// Verifica el acceso del usuario y carga los datos iniciales
  /// Retorna true si el acceso es válido, false si debe redirigir
  Future<bool> verificarAccesoYCargarDatos() async {
    _setLoading(true);
    _setError(null);

    try {
      developer.log(
        'Iniciando verificación de acceso...',
        name: 'RepartidorController',
      );

      // 1. Verificar autenticación básica
      if (!_apiClient.isAuthenticated) {
        developer.log('Sin autenticación', name: 'RepartidorController');
        return false;
      }

      // 2. Verificar Rol (Lógica Robusta: Cache -> Servidor)
      final rolCacheado = _apiClient.userRole;
      bool esRepartidor = rolCacheado?.toUpperCase() == ApiConfig.rolRepartidor;

      // Si el caché dice que NO es repartidor (o es null), o dice otra cosa (ej. PROVEEDOR),
      // preguntamos al servidor para estar 100% seguros y corregir si es necesario.
      if (!esRepartidor) {
        developer.log(
          'Rol en caché ($rolCacheado) no coincide. Verificando con servidor...',
          name: 'RepartidorController',
        );

        try {
          // Llamamos al endpoint que verifica roles
          final info = await _apiClient.get(ApiConfig.infoRol);

          // El backend puede devolver 'rol' o 'rol_activo'
          final rolServidorRaw = (info['rol'] ?? info['rol_activo']);
          final rolServidor = rolServidorRaw?.toString().toUpperCase();

          if (rolServidor == ApiConfig.rolRepartidor) {
            developer.log(
              'Servidor confirma: ES REPARTIDOR. Acceso concedido.',
              name: 'RepartidorController',
            );
            esRepartidor = true;

            // NOTA: Aquí idealmente deberías actualizar _apiClient.userRole si tienes un setter,
            // para que el Drawer y otras partes de la UI se enteren del cambio.
            // _apiClient.setRole(ApiConfig.rolRepartidor);
          } else {
            developer.log(
              'Servidor confirma: NO ES REPARTIDOR (Es $rolServidor)',
              name: 'RepartidorController',
            );
          }
        } catch (e) {
          developer.log(
            'Falló la verificación con servidor',
            name: 'RepartidorController',
            error: e,
          );
          // Si falla la conexión, nos quedamos con la decisión del caché (false)
        }
      }

      // 3. Decisión Final
      if (!esRepartidor) {
        _setError('Acceso denegado: Rol incorrecto o permisos insuficientes.');
        _setLoading(false);
        return false;
      }

      developer.log(
        'Acceso verificado - Cargando datos...',
        name: 'RepartidorController',
      );

      // 4. Cargar datos del perfil
      await cargarDatos();

      // 5. Validación post-carga (Doble seguridad)
      // Si cargamos el perfil pero viene vacío o con datos extraños, bloqueamos.
      if (_perfil == null) {
        _setError('No se pudo cargar el perfil de repartidor.');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error crítico en verificación',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );

      _setError('Error al verificar acceso');
      _setLoading(false);

      // Si es error de autenticación (401), devolvemos false para redirigir
      return !(e is ApiException && e.isAuthError);
    }
  }

  // ============================================
  // CARGAR DATOS
  // ============================================

  /// Carga el perfil y estadísticas del repartidor
  Future<void> cargarDatos({bool forzarRecarga = true}) async {
    try {
      developer.log(
        'Cargando perfil y estadísticas...',
        name: 'RepartidorController',
      );

      // Perfil es obligatorio; estadísticas son best-effort
      _perfil = await _repartidorService.obtenerPerfil(
        forzarRecarga: forzarRecarga,
      );

      try {
        _estadisticas = await _repartidorService.obtenerEstadisticas(
          forzarRecarga: forzarRecarga,
        );
      } catch (e, stack) {
        developer.log(
          'Error obteniendo estadísticas (se continúa sin bloquear)',
          name: 'RepartidorController',
          error: e,
          stackTrace: stack,
        );
        _estadisticas = null;
      }

      developer.log(
        '[DEBUG] Perfil cargado - Estado actual: ${_perfil?.estado.nombre ?? "null"}',
        name: 'RepartidorController',
      );

      // Intenta sincronizar la ubicación apenas se cargan datos
      await _sincronizarUbicacion();

      // Si el repartidor ya está disponible, asegurar ubicación inicial
      if (_perfil?.estado == EstadoRepartidor.disponible) {
        developer.log(
          '[DEBUG] Repartidor ya está disponible al cargar - verificando ubicación inicial',
          name: 'RepartidorController',
        );
        await _asegurarUbicacionInicial();
      }

      // Cargar pedidos disponibles y esperar a que termine
      await cargarPedidosDisponibles(forzarRecarga: forzarRecarga);

      _setError(null);
      _setLoading(false);

      developer.log(
        'Datos cargados correctamente',
        name: 'RepartidorController',
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 &&
          (e.errors['action'] == 'ROLE_RESET' ||
              e.details?['action'] == 'ROLE_RESET')) {
        developer.log(
          'Detectado ROLE_RESET - Cerrando sesión para limpiar estado',
          name: 'RepartidorController',
        );
        _setError(
          'Tu perfil de repartidor ha sido desactivado. Inicia sesión nuevamente como Cliente.',
        );
        _setLoading(false);
        await cerrarSesion(); // Forzar logout para limpiar cache de rol
        return;
      }

      developer.log(
        'API Exception: ${e.message}',
        name: 'RepartidorController',
      );

      _setError(e.getUserFriendlyMessage());
      _setLoading(false);

      if (e.isAuthError) {
        rethrow; // Propagar para que la UI maneje el logout si expiró el token
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error cargando datos',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );

      _setError('Error al cargar información');
      _setLoading(false);
    }
  }

  // ============================================
  // CAMBIAR ESTADO (DISPONIBILIDAD)
  // ============================================

  /// Cambia el estado de disponibilidad del repartidor
  Future<bool> cambiarEstado(EstadoRepartidor nuevoEstado) async {
    try {
      developer.log(
        'Cambiando estado a: ${nuevoEstado.nombre}',
        name: 'RepartidorController',
      );

      await _repartidorService.cambiarEstado(nuevoEstado);

      // Actualizar perfil local con el nuevo estado
      _perfil = _perfil?.copyWith(estado: nuevoEstado);
      _notifySafely();

      // Gestionar ubicación inicial según estado
      if (nuevoEstado == EstadoRepartidor.disponible) {
        developer.log(
          '[DEBUG] Repartidor cambió a DISPONIBLE - verificando ubicación inicial',
          name: 'RepartidorController',
        );
        await _asegurarUbicacionInicial();
        developer.log(
          '[DEBUG] Ubicación inicial verificada',
          name: 'RepartidorController',
        );
      } else {
        developer.log(
          '[DEBUG] Repartidor cambió a ${nuevoEstado.nombre} - sin acción de ubicación',
          name: 'RepartidorController',
        );
      }

      developer.log(
        'Estado cambiado exitosamente',
        name: 'RepartidorController',
      );

      return true;
    } on ApiException catch (e) {
      developer.log(
        'Error cambiando estado: ${e.message}',
        name: 'RepartidorController',
      );
      _setError(e.getUserFriendlyMessage());
      return false;
    } catch (e) {
      developer.log(
        'Error inesperado cambiando estado',
        name: 'RepartidorController',
        error: e,
      );
      _setError('Error al cambiar estado');
      return false;
    }
  }

  // ============================================
  // PEDIDOS: ACEPTAR / RECHAZAR
  // ============================================

  /// Acepta un pedido disponible y recarga datos para reflejar el nuevo estado.
  /// Retorna el detalle completo del pedido con datos sensibles del cliente
  Future<PedidoDetalladoRepartidor?> aceptarPedido(int pedidoId) async {
    try {
      developer.log('Aceptando pedido $pedidoId', name: 'RepartidorController');

      // 1. Aceptar el pedido
      await _repartidorService.aceptarPedido(pedidoId);

      // 2. Obtener el detalle COMPLETO del pedido (con datos sensibles)
      final detalle = await _repartidorService.obtenerDetallePedido(pedidoId);

      // 3. Recargar datos del perfil para actualizar estado
      await cargarDatos(forzarRecarga: true);

      // 4. Cargar pedidos activos para mostrar en la UI
      await cargarPedidosActivos();

      return detalle;
    } on ApiException catch (e) {
      _setError(e.getUserFriendlyMessage());
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Error inesperado aceptando pedido',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Error al aceptar pedido');
      return null;
    }
  }

  /// Rechaza un pedido disponible (ej. por distancia).
  Future<bool> rechazarPedido(
    int pedidoId, {
    String motivo = 'No puedo tomarlo',
  }) async {
    try {
      developer.log(
        'Rechazando pedido $pedidoId',
        name: 'RepartidorController',
      );
      await _repartidorService.rechazarPedido(pedidoId, motivo: motivo);
      await cargarDatos(forzarRecarga: true);
      return true;
    } on ApiException catch (e) {
      _setError(e.getUserFriendlyMessage());
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error inesperado rechazando pedido',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Error al rechazar pedido');
      return false;
    }
  }

  /// Lista pedidos disponibles cercanos
  Future<void> cargarPedidosDisponibles({
    bool forzarRecarga = true,
    double? latitud,
    double? longitud,
    bool actualizarUbicacionBackend = false,
  }) async {
    try {
      double? lat = latitud;
      double? lng = longitud;

      final ubicacionService = UbicacionService();

      if (lat == null || lng == null) {
        // Obtiene ubicación local (sin enviar) para usar en el request
        final posicion = await ubicacionService.obtenerUbicacionActual();
        if (posicion != null) {
          lat = posicion.latitude;
          lng = posicion.longitude;
        } else {
          // Reutiliza última ubicación conocida o la guardada en el perfil
          lat = ubicacionService.ultimaUbicacion?.latitude ?? _perfil?.latitud;
          lng =
              ubicacionService.ultimaUbicacion?.longitude ?? _perfil?.longitud;
        }

        // Si seguimos sin coordenadas, avisamos y evitamos llamar a la API
        if (lat == null || lng == null) {
          _pendientes = [];
          _setError('Activa tu ubicación para ver pedidos cercanos.');
          return;
        }
      } else if (actualizarUbicacionBackend) {
        try {
          await _repartidorService.actualizarUbicacion(
            latitud: lat,
            longitud: lng,
          );
        } catch (e, stackTrace) {
          developer.log(
            'No se pudo actualizar la ubicacion antes de listar pedidos',
            name: 'RepartidorController',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      final resp = await _repartidorService.obtenerPedidosDisponibles(
        latitud: lat,
        longitud: lng,
      );
      _pendientes = resp.pedidos;
      _notifySafely();
    } on ApiException catch (e, stackTrace) {
      developer.log(
        'Error obteniendo pedidos disponibles',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );
      // Manejo amigable: dejar lista vacía y mensaje, no reventar el flujo
      _pendientes = [];
      _setError(e.getUserFriendlyMessage());
      _notifySafely();
    } catch (e, stackTrace) {
      developer.log(
        'Error obteniendo pedidos disponibles',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );
      _pendientes = [];
      _setError('No se pudieron cargar pedidos disponibles');
      _notifySafely();
    }
  }

  /// Obtiene los pedidos ACTIVOS (asignados) del repartidor
  Future<void> cargarPedidosActivos() async {
    try {
      final pedidos = await _repartidorService.obtenerMisPedidosActivos();
      _pedidosActivos = pedidos;
      _notifySafely();
      developer.log(
        'Pedidos activos cargados: ${pedidos.length}',
        name: 'RepartidorController',
      );
    } on ApiException catch (e, stackTrace) {
      if (e.isNetworkError) {
        developer.log(
          'Sin conexion al obtener pedidos activos',
          name: 'RepartidorController',
        );
      } else {
        developer.log(
          'Error obteniendo pedidos activos',
          name: 'RepartidorController',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error obteniendo pedidos activos',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Remueve un pedido de la lista de disponibles (cuando otro repartidor lo acepta)
  void removerPedidoDisponible(int pedidoId) {
    // Verificar que la lista no sea null antes de usar force unwrap
    final pendientes = _pendientes;
    if (pendientes == null) return;

    final index = pendientes.indexWhere((p) => p.id == pedidoId);
    if (index != -1) {
      pendientes.removeAt(index);
      _notifySafely();
      developer.log(
        'Pedido #$pedidoId removido de disponibles (aceptado por otro repartidor)',
        name: 'RepartidorController',
      );
    }
  }

  // ============================================
  // MARCAR PEDIDO COMO EN CAMINO
  // ============================================

  /// Marca un pedido como en camino (repartidor ya lo recogió y va hacia el cliente)
  /// Retorna true si fue exitoso, false si hubo error
  Future<bool> marcarPedidoEnCamino(
    int pedidoId, {
    bool mostrarLoading = true,
  }) async {
    try {
      if (mostrarLoading) {
        _setLoading(true);
      }
      _setError(null);

      developer.log(
        'Intentando marcar pedido #$pedidoId como en camino',
        name: 'RepartidorController',
      );

      await _repartidorService.marcarPedidoEnCamino(pedidoId);

      // Recargar listas de pedidos en paralelo
      await Future.wait([cargarPedidosActivos(), cargarPedidosDisponibles()]);

      developer.log(
        'Pedido #$pedidoId marcado como en camino exitosamente',
        name: 'RepartidorController',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error al marcar pedido como en camino',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );

      // Extraer mensaje de error más específico
      String errorMsg = 'Error al marcar el pedido como en camino';

      if (e.toString().contains('no está asignado')) {
        errorMsg = 'Este pedido no está asignado a ti';
      } else if (e.toString().contains('ya está finalizado')) {
        errorMsg = 'Este pedido ya fue finalizado';
      } else if (e.toString().contains('Estado inválido')) {
        errorMsg =
            'El pedido no puede ser marcado como en camino en su estado actual';
      }

      _setError(errorMsg);
      return false;
    } finally {
      if (mostrarLoading) {
        _setLoading(false);
      }
    }
  }

  // ============================================
  // MARCAR PEDIDO COMO ENTREGADO
  // ============================================

  /// Marca un pedido como entregado
  /// Retorna true si fue exitoso, false si hubo error
  Future<bool> marcarPedidoEntregado({
    required int pedidoId,
    File? imagenEvidencia,
    bool mostrarLoading = true,
  }) async {
    try {
      if (mostrarLoading) {
        _setLoading(true);
      }
      _setError(null);

      developer.log(
        'Intentando marcar pedido #$pedidoId como entregado',
        name: 'RepartidorController',
      );

      await _repartidorService.marcarPedidoEntregado(
        pedidoId: pedidoId,
        imagenEvidencia: imagenEvidencia,
      );

      // Recargar listas de pedidos en paralelo
      await Future.wait([cargarPedidosActivos(), cargarPedidosDisponibles()]);

      developer.log(
        'Pedido #$pedidoId marcado como entregado exitosamente',
        name: 'RepartidorController',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error al marcar pedido como entregado',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );

      // Extraer mensaje de error más específico
      String errorMsg = 'Error al marcar el pedido como entregado';

      if (e.toString().contains('Comprobante requerido')) {
        errorMsg = 'Debes adjuntar el comprobante de transferencia';
      } else if (e.toString().contains('no está asignado')) {
        errorMsg = 'Este pedido no está asignado a ti';
      } else if (e.toString().contains('ya está finalizado')) {
        errorMsg = 'Este pedido ya fue finalizado';
      }

      _setError(errorMsg);
      return false;
    } finally {
      if (mostrarLoading) {
        _setLoading(false);
      }
    }
  }

  // ============================================
  // HISTORIAL DE ENTREGAS
  // ============================================

  /// Obtiene el historial de entregas del repartidor
  /// Opcionalmente puede filtrar por rango de fechas
  Future<void> cargarHistorialEntregas({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      _loadingHistorial = true;
      _error = null; // Limpiar error anterior
      _notifySafely();

      developer.log(
        'Cargando historial de entregas...',
        name: 'RepartidorController',
      );

      final respuesta = await _repartidorService.obtenerHistorialEntregas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      _historialEntregas = HistorialEntregasResponse.fromJson(respuesta);
      _error = null; // Asegurar que no hay error

      developer.log(
        'Historial cargado: ${_historialEntregas?.entregas.length ?? 0} entregas',
        name: 'RepartidorController',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error al cargar historial de entregas',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );

      // Extraer mensaje de error específico
      String errorMsg = 'Error al cargar el historial de entregas';

      if (e.toString().contains('No tienes perfil de repartidor')) {
        errorMsg = 'No tienes perfil de repartidor asociado';
      } else if (e.toString().contains('Network') ||
          e.toString().contains('SocketException')) {
        errorMsg = 'Error de conexión. Verifica tu internet';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMsg = 'Sesión expirada. Inicia sesión nuevamente';
      } else if (e.toString().contains('403') ||
          e.toString().contains('Forbidden')) {
        errorMsg = 'No tienes permisos para ver el historial';
      }

      _setError(errorMsg);
    } finally {
      _loadingHistorial = false;
      _notifySafely();
    }
  }

  /// Recarga el historial (útil para pull-to-refresh)
  Future<void> recargarHistorial() async {
    await cargarHistorialEntregas();
  }

  // ============================================
  // CERRAR SESIÓN
  // ============================================

  /// Cierra la sesión del usuario
  Future<void> cerrarSesion() async {
    try {
      developer.log('Cerrando sesión...', name: 'RepartidorController');
      await _authService.logout();
      _limpiarEstado();
    } catch (e) {
      developer.log(
        'Error cerrando sesión',
        name: 'RepartidorController',
        error: e,
      );
    }
  }

  void limpiar() {
    _limpiarEstado();
  }

  // ============================================
  // HELPERS PRIVADOS
  // ============================================

  void _setLoading(bool value) {
    _loading = value;
    _notifySafely();
  }

  void _setError(String? value) {
    _error = value;
    _notifySafely();
  }

  void _limpiarEstado() {
    stopSmartPolling();
    _ubicacionService.detener();
    _perfil = null;
    _estadisticas = null;
    _pendientes = null;
    _pedidosActivos = null;
    _historialEntregas = null;
    _loadingHistorial = false;
    _error = null;
    _loading = false;
    _notifySafely();
  }

  void _notifySafely() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Intenta guardar la ubicación actual en el backend y reflejarla en el perfil local
  Future<void> _sincronizarUbicacion() async {
    try {
      developer.log(
        '[DEBUG] Iniciando sincronización de ubicación única',
        name: 'RepartidorController',
      );
      final posicion = await _ubicacionService.obtenerYEnviarUbicacion();
      if (posicion != null) {
        developer.log(
          '[DEBUG] Ubicación obtenida y enviada: ${posicion.latitude}, ${posicion.longitude}',
          name: 'RepartidorController',
        );
        _perfil = _perfil?.copyWith(
          latitud: posicion.latitude,
          longitud: posicion.longitude,
        );
      } else {
        developer.log(
          '[DEBUG] No se pudo obtener ubicación para sincronizar',
          name: 'RepartidorController',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'No se pudo sincronizar la ubicacion inicial',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Asegura que el repartidor tenga ubicación inicial guardada
  Future<void> _asegurarUbicacionInicial() async {
    try {
      // Verificar si ya tiene ubicación guardada
      if (_perfil?.latitud != null && _perfil?.longitud != null) {
        developer.log(
          '[DEBUG] Repartidor ya tiene ubicación guardada: ${_perfil?.latitud}, ${_perfil?.longitud}',
          name: 'RepartidorController',
        );
        return; // Ya tiene ubicación, no hacer nada
      }

      developer.log(
        '[DEBUG] Repartidor no tiene ubicación - obteniendo ubicación inicial',
        name: 'RepartidorController',
      );

      // Obtener y enviar ubicación inicial
      final posicion = await _ubicacionService.obtenerYEnviarUbicacion();
      if (posicion != null) {
        developer.log(
          '[DEBUG] Ubicación inicial guardada: ${posicion.latitude}, ${posicion.longitude}',
          name: 'RepartidorController',
        );
        // Actualizar perfil local
        _perfil = _perfil?.copyWith(
          latitud: posicion.latitude,
          longitud: posicion.longitude,
        );
        _notifySafely();
      } else {
        developer.log(
          '[DEBUG] No se pudo obtener ubicación inicial',
          name: 'RepartidorController',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error asegurando ubicación inicial',
        name: 'RepartidorController',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================
  // SMART POLLING (Actualización Inteligente)
  // ============================================

  /// Inicia el polling inteligente de pedidos
  /// Solo actualiza cuando es necesario (cada 30s) y si pasó el intervalo mínimo
  void startSmartPolling() {
    if (_isPollingActive) {
      developer.log('Polling ya está activo', name: 'RepartidorController');
      return;
    }

    developer.log('Iniciando smart polling', name: 'RepartidorController');
    _isPollingActive = true;

    // Cancelar timer existente si hay
    _pollingTimer?.cancel();

    // Crear nuevo timer que se ejecuta cada 30 segundos
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (!_disposed && _isPollingActive) {
        _actualizacionInteligente();
      }
    });
  }

  /// Detiene el polling inteligente
  void stopSmartPolling() {
    if (!_isPollingActive) return;

    developer.log('Deteniendo smart polling', name: 'RepartidorController');
    _isPollingActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Pausa temporalmente el polling (cuando app va a background)
  void pausePolling() {
    _pollingTimer?.cancel();
    developer.log('Polling pausado', name: 'RepartidorController');
  }

  /// Reanuda el polling (cuando app vuelve a foreground)
  void resumePolling() {
    if (_isPollingActive && _pollingTimer == null) {
      startSmartPolling();
      developer.log('Polling reanudado', name: 'RepartidorController');
    }
  }

  /// Actualización inteligente - solo carga si pasó el intervalo mínimo
  Future<void> _actualizacionInteligente() async {
    try {
      final ahora = DateTime.now();

      // Verificar si debe actualizar pedidos disponibles
      final debeActualizarPendientes =
          _lastPedidosUpdate == null ||
          ahora.difference(_lastPedidosUpdate!) >= _minUpdateInterval;

      // Verificar si debe actualizar pedidos activos
      final debeActualizarActivos =
          _lastPedidosActivosUpdate == null ||
          ahora.difference(_lastPedidosActivosUpdate!) >= _minUpdateInterval;

      // Solo actualizar si pasó el intervalo mínimo
      if (!debeActualizarPendientes && !debeActualizarActivos) {
        developer.log(
          'Skipping update - intervalo mínimo no alcanzado',
          name: 'RepartidorController',
        );
        return;
      }

      developer.log(
        'Actualización inteligente - Pendientes: $debeActualizarPendientes, Activos: $debeActualizarActivos',
        name: 'RepartidorController',
      );

      // Actualizar pedidos disponibles si corresponde
      if (debeActualizarPendientes && estaDisponible) {
        await cargarPedidosDisponibles(forzarRecarga: false);
        _lastPedidosUpdate = DateTime.now();
      }

      // Actualizar pedidos activos si corresponde
      if (debeActualizarActivos) {
        await cargarPedidosActivos();
        _lastPedidosActivosUpdate = DateTime.now();
      }
    } catch (e) {
      developer.log(
        'Error en actualización inteligente: $e',
        name: 'RepartidorController',
        error: e,
      );
      // No propagar el error - es solo una actualización en background
    }
  }

  /// Fuerza una actualización inmediata (sin esperar intervalo)
  Future<void> forzarActualizacion() async {
    developer.log(
      'Forzando actualización inmediata',
      name: 'RepartidorController',
    );

    // Resetear timestamps para permitir actualización
    _lastPedidosUpdate = null;
    _lastPedidosActivosUpdate = null;

    // Ejecutar actualización
    await _actualizacionInteligente();
  }

  // ============================================
  // UTILIDADES UI
  // ============================================

  IconData getIconoEstado(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.disponible:
        return Icons.check_circle;
      case EstadoRepartidor.ocupado:
        return Icons.delivery_dining;
      case EstadoRepartidor.fueraServicio:
        return Icons.pause_circle;
    }
  }

  Color getColorEstado(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.disponible:
        return const Color(0xFF4CAF50); // Verde
      case EstadoRepartidor.ocupado:
        return const Color(0xFF2196F3); // Azul
      case EstadoRepartidor.fueraServicio:
        return Colors.grey[700]!;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopSmartPolling(); // Detener polling antes de dispose
    _ubicacionService.dispose();
    _limpiarEstado();
    super.dispose();
  }
}
