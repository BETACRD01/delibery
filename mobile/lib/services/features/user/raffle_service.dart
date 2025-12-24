// lib/services/features/user/raffle_service.dart

import 'dart:developer' as developer;
import '../../../apis/user/rifas_api.dart';
import '../../../apis/user/rifas_usuarios_api.dart';
import '../../../apis/helpers/api_exception.dart';

/// Servicio dedicado para gestión de rifas/sorteos del usuario
class RaffleService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final RaffleService _instance = RaffleService._internal();
  factory RaffleService() => _instance;
  RaffleService._internal();

  final _rifasApi = RifasApi();
  final _rifasUsuariosApi = RifasUsuariosApi();

  // ---------------------------------------------------------------------------
  // CACHE
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? _rifasCache;
  Map<String, dynamic>? _rifaActivaCache;
  Map<String, dynamic>? _rifasMesCache;

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'RaffleService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN DE RIFAS
  // ---------------------------------------------------------------------------

  /// Obtiene las rifas y participaciones del usuario
  Future<Map<String, dynamic>> obtenerRifasParticipaciones({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _rifasCache != null) {
        _log('Retornando rifas desde caché');
        return _rifasCache!;
      }

      _log('Obteniendo rifas desde API...');
      final data = await _rifasApi.misParticipaciones();
      _rifasCache = data;
      return data;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error al obtener rifas', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener rifas',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  /// Obtiene la rifa activa actual
  Future<Map<String, dynamic>?> obtenerRifaActiva({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _rifaActivaCache != null) {
        return _rifaActivaCache;
      }

      final data = await _rifasUsuariosApi.obtenerRifaActiva();
      _rifaActivaCache = data;
      return data;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error al obtener rifa activa', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Obtiene las rifas del mes actual
  Future<Map<String, dynamic>> obtenerRifasMesActual({
    bool forzarRecarga = false,
  }) async {
    try {
      if (!forzarRecarga && _rifasMesCache != null) {
        return _rifasMesCache!;
      }

      final data = await _rifasUsuariosApi.obtenerRifasMesActual();
      _rifasMesCache = data;
      return data;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error al obtener rifas del mes', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Inscribe al usuario en una rifa
  Future<Map<String, dynamic>> participarEnRifa(String rifaId) async {
    try {
      _log('Participando en rifa $rifaId...');
      final response = await _rifasUsuariosApi.participarEnRifa(rifaId);

      // Invalidar caché
      limpiarCache();

      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error al participar en rifa', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al participar en la rifa',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  /// Obtiene el detalle de una rifa específica
  Future<Map<String, dynamic>> obtenerDetalleRifa(String rifaId) async {
    try {
      _log('Obteniendo detalle de rifa $rifaId...');
      return await _rifasUsuariosApi.obtenerDetalleRifa(rifaId);
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      _log('Error al obtener detalle de rifa', error: e, stackTrace: stackTrace);
      throw ApiException(
        statusCode: 0,
        message: 'Error al obtener detalle de la rifa',
        errors: {'error': e.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CACHE
  // ---------------------------------------------------------------------------

  void limpiarCache() {
    _log('Limpiando caché de rifas');
    _rifasCache = null;
    _rifaActivaCache = null;
    _rifasMesCache = null;
  }
}
