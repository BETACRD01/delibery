// lib/screens/user/perfil/perfil_controller.dart

import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../models/auth/usuario.dart';
import '../../services/usuarios/usuarios_service.dart';
import '../../apis/helpers/api_exception.dart';

/// Controlador de Perfil: Maneja la logica de negocio y estado de la pantalla de perfil.
class PerfilController extends ChangeNotifier {
  
  // ---------------------------------------------------------------------------
  // DEPENDENCIAS
  // ---------------------------------------------------------------------------
  final UsuarioService _usuarioService = UsuarioService();

  // ---------------------------------------------------------------------------
  // ESTADO DE DATOS
  // ---------------------------------------------------------------------------
  PerfilModel? _perfil;
  List<DireccionModel>? _direcciones;
  EstadisticasModel? _estadisticas;
  int _rifasParticipadas = 0;
  int _rifasGanadas = 0;

  // ---------------------------------------------------------------------------
  // ESTADO DE CARGA
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  bool _isLoadingPerfil = false;
  bool _isLoadingDirecciones = false;
  bool _isLoadingEstadisticas = false;

  // ---------------------------------------------------------------------------
  // ESTADO DE ERRORES
  // ---------------------------------------------------------------------------
  String? _error;
  String? _errorPerfil;
  String? _errorDirecciones;
  String? _errorEstadisticas;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------
  PerfilModel? get perfil => _perfil;
  List<DireccionModel>? get direcciones => _direcciones;
  EstadisticasModel? get estadisticas => _estadisticas;
  int get rifasParticipadas => _rifasParticipadas;
  int get rifasGanadas => _rifasGanadas;

  bool get isLoading => _isLoading;
  bool get isLoadingPerfil => _isLoadingPerfil;
  bool get isLoadingDirecciones => _isLoadingDirecciones;
  bool get isLoadingEstadisticas => _isLoadingEstadisticas;

  String? get error => _error;
  String? get errorPerfil => _errorPerfil;
  String? get errorDirecciones => _errorDirecciones;
  String? get errorEstadisticas => _errorEstadisticas;

  bool get tieneError => _error != null;
  bool get tieneDatos => _perfil != null;
  bool get tieneDirecciones => _direcciones != null && _direcciones!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // LOGGING
  // ---------------------------------------------------------------------------
  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'PerfilController',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // CARGA INICIAL
  // ---------------------------------------------------------------------------

  /// Carga todos los datos del perfil secuencialmente.
  Future<void> cargarDatosCompletos({bool forzarRecarga = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cargarPerfil(forzarRecarga: forzarRecarga);
      await _cargarDirecciones(forzarRecarga: forzarRecarga);
      await _cargarEstadisticas(forzarRecarga: forzarRecarga);

      if (_perfil == null && _estadisticas == null && (_direcciones == null || _direcciones!.isEmpty)) {
        _error = 'No se pudo cargar ningun dato del perfil';
      }
    } catch (e, stackTrace) {
      _log('Error en carga completa', error: e, stackTrace: stackTrace);
      _error = 'Error al cargar los datos del perfil';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // GESTION DE PERFIL
  // ---------------------------------------------------------------------------

  Future<void> _cargarPerfil({bool forzarRecarga = false}) async {
    _isLoadingPerfil = true;
    _errorPerfil = null;
    notifyListeners();

    try {
      _perfil = await _usuarioService.obtenerPerfil(forzarRecarga: forzarRecarga);
    } on ApiException catch (e) {
      _errorPerfil = e.getUserFriendlyMessage();
    } catch (e, stackTrace) {
      _log('Error cargando perfil', error: e, stackTrace: stackTrace);
      _errorPerfil = 'Error al cargar el perfil';
    } finally {
      _isLoadingPerfil = false;
      notifyListeners();
    }
  }

  Future<void> recargarPerfil() async {
    await _cargarPerfil(forzarRecarga: true);
  }

  // ---------------------------------------------------------------------------
  // GESTION DE DIRECCIONES
  // ---------------------------------------------------------------------------

  Future<void> _cargarDirecciones({bool forzarRecarga = false}) async {
    _isLoadingDirecciones = true;
    _errorDirecciones = null;

    if (forzarRecarga) {
      _usuarioService.limpiarCacheDirecciones();
      _direcciones = null;
    }

    notifyListeners();

    try {
      _direcciones = await _usuarioService.listarDirecciones(forzarRecarga: forzarRecarga);
    } on ApiException catch (e) {
      _errorDirecciones = e.getUserFriendlyMessage();
      _direcciones = [];
    } catch (e, stackTrace) {
      _log('Error cargando direcciones', error: e, stackTrace: stackTrace);
      _errorDirecciones = 'Error al cargar las direcciones';
      _direcciones = [];
    } finally {
      _isLoadingDirecciones = false;
      notifyListeners();
    }
  }

  Future<void> recargarDirecciones() async {
    await _cargarDirecciones(forzarRecarga: true);
  }

  Future<bool> eliminarDireccion(String direccionId) async {
    try {
      await _usuarioService.eliminarDireccion(direccionId);
      
      if (_direcciones != null) {
        _direcciones!.removeWhere((d) => d.id == direccionId);
      }
      
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorDirecciones = e.getUserFriendlyMessage();
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _log('Error eliminando direccion', error: e, stackTrace: stackTrace);
      _errorDirecciones = 'Error al eliminar la direccion';
      notifyListeners();
      return false;
    }
  }

  Future<bool> establecerDireccionPredeterminada(String direccionId) async {
    try {
      await _usuarioService.actualizarDireccion(direccionId, {'es_predeterminada': true});

      if (_direcciones != null) {
        for (var i = 0; i < _direcciones!.length; i++) {
          final direccion = _direcciones![i];
          if (direccion.id == direccionId) {
            _direcciones![i] = direccion.copyWith(esPredeterminada: true);
          } else if (direccion.esPredeterminada) {
            _direcciones![i] = direccion.copyWith(esPredeterminada: false);
          }
        }
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorDirecciones = e.getUserFriendlyMessage();
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      _log('Error actualizando direccion default', error: e, stackTrace: stackTrace);
      _errorDirecciones = 'Error al actualizar la direccion';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // GESTION DE ESTADISTICAS
  // ---------------------------------------------------------------------------

  Future<void> _cargarEstadisticas({bool forzarRecarga = false}) async {
    _isLoadingEstadisticas = true;
    _errorEstadisticas = null;
    notifyListeners();

    try {
      _estadisticas = await _usuarioService.obtenerEstadisticas(forzarRecarga: forzarRecarga);
      final rifas = await _usuarioService.obtenerRifasParticipaciones(forzarRecarga: forzarRecarga);
      _rifasParticipadas = (rifas['total'] as num?)?.toInt() ?? 0;
      _rifasGanadas = (rifas['victorias'] as num?)?.toInt() ?? 0;
    } on ApiException catch (e) {
      _errorEstadisticas = e.getUserFriendlyMessage();
    } catch (e, stackTrace) {
      _log('Error cargando estadisticas', error: e, stackTrace: stackTrace);
      _errorEstadisticas = 'Error al cargar las estadisticas';
    } finally {
      _isLoadingEstadisticas = false;
      notifyListeners();
    }
  }

  Future<void> recargarEstadisticas() async {
    await _cargarEstadisticas(forzarRecarga: true);
  }

  // ---------------------------------------------------------------------------
  // PREFERENCIAS Y NOTIFICACIONES
  // ---------------------------------------------------------------------------

  Future<bool> actualizarNotificaciones({
    bool? notificacionesPedido,
    bool? notificacionesPromociones,
  }) async {
    try {
      final datos = <String, dynamic>{};
      if (notificacionesPedido != null) {
        datos['notificaciones_pedido'] = notificacionesPedido;
      }
      if (notificacionesPromociones != null) {
        datos['notificaciones_promociones'] = notificacionesPromociones;
      }

      await _usuarioService.actualizarPerfil(datos);

      if (_perfil != null) {
        _perfil = _perfil!.copyWith(
          notificacionesPedido: notificacionesPedido ?? _perfil!.notificacionesPedido,
          notificacionesPromociones: notificacionesPromociones ?? _perfil!.notificacionesPromociones,
        );
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _log('Error actualizando notificaciones: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      _log('Error inesperado en notificaciones', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES Y HELPERS
  // ---------------------------------------------------------------------------

  bool get perfilCompleto {
    if (_perfil == null) return false;
    return _perfil!.tieneTelefono && _perfil!.fechaNacimiento != null;
  }

  int get porcentajeCompletitud {
    if (_perfil == null) return 0;
    int completados = 2; // Email y nombre base
    if (_perfil!.tieneTelefono) completados++;
    if (_perfil!.fechaNacimiento != null) completados++;
    return ((completados / 4) * 100).round();
  }

  String get mensajeCompletitud {
    final p = porcentajeCompletitud;
    if (p == 100) return 'Perfil completo';
    if (p >= 75) return 'Casi listo';
    if (p >= 50) return 'Completa tu perfil';
    return 'Informacion incompleta';
  }

  // Helpers de Estadisticas
  double get progresoRifa => _estadisticas?.progresoRifa ?? 0.0;
  String get mensajeRifa => _estadisticas?.mensajeRifa ?? 'Cargando...';
  bool get puedeParticiparRifa => _estadisticas?.puedeParticiparRifa ?? false;
  String get nivelCliente => _estadisticas?.nivelCliente ?? 'Cliente';


  // ---------------------------------------------------------------------------
  // LIMPIEZA Y DEBUG
  // ---------------------------------------------------------------------------

  void limpiar() {
    _perfil = null;
    _direcciones = null;
    _estadisticas = null;
    _error = null;
    _errorPerfil = null;
    _errorDirecciones = null;
    _errorEstadisticas = null;
    _isLoading = false;
    notifyListeners();
  }

  void imprimirEstado() {
    _log('--- Estado PerfilController ---');
    _log('Carga General: $_isLoading');
    _log('Perfil: ${_perfil != null ? "OK" : "Null"}');
    _log('Direcciones: ${_direcciones?.length ?? "Null"}');
    _log('Estadisticas: ${_estadisticas != null ? "OK" : "Null"}');
    if (_error != null) _log('Error General: $_error');
  }
}
