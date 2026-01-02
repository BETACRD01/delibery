// lib/services/repartidor/repartidor_datos_bancarios_service.dart

import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';
import '../../models/payments/datos_bancarios.dart';
import 'dart:developer' as developer;

class RepartidorDatosBancariosService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final RepartidorDatosBancariosService _instance =
      RepartidorDatosBancariosService._internal();
  factory RepartidorDatosBancariosService() => _instance;
  RepartidorDatosBancariosService._internal();

  final _client = ApiClient();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message,
        name: 'RepartidorDatosBancariosService',
        error: error,
        stackTrace: stackTrace);
  }

  // ---------------------------------------------------------------------------
  // OBTENER DATOS BANCARIOS
  // ---------------------------------------------------------------------------

  /// Obtiene los datos bancarios del repartidor autenticado
  Future<DatosBancarios> obtenerDatosBancarios() async {
    try {
      _log('Obteniendo datos bancarios del repartidor');

      final response = await _client.get(
        ApiConfig.repartidorDatosBancarios,
      );

      _log('Datos bancarios obtenidos exitosamente');
      return DatosBancarios.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error al obtener datos bancarios',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTUALIZAR DATOS BANCARIOS
  // ---------------------------------------------------------------------------

  /// Actualiza los datos bancarios del repartidor (PUT - completo)
  Future<DatosBancarios> actualizarDatosBancarios({
    required String bancoNombre,
    required String bancoTipoCuenta,
    required String bancoNumeroCuenta,
    required String bancoTitular,
    required String bancoCedulaTitular,
  }) async {
    try {
      _log('Actualizando datos bancarios del repartidor');

      final data = {
        'banco_nombre': bancoNombre,
        'banco_tipo_cuenta': bancoTipoCuenta,
        'banco_numero_cuenta': bancoNumeroCuenta,
        'banco_titular': bancoTitular,
        'banco_cedula_titular': bancoCedulaTitular,
      };

      final response = await _client.put(
        ApiConfig.repartidorDatosBancarios,
        data,
      );

      _log('Datos bancarios actualizados exitosamente');
      return DatosBancarios.fromJson(response['datos_bancarios']);
    } catch (e, stackTrace) {
      _log('Error al actualizar datos bancarios',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTUALIZAR DATOS BANCARIOS PARCIALMENTE
  // ---------------------------------------------------------------------------

  /// Actualiza parcialmente los datos bancarios del repartidor (PATCH)
  Future<DatosBancarios> actualizarDatosBancariosParcial(
      Map<String, String> campos) async {
    try {
      _log('Actualizando parcialmente datos bancarios del repartidor');

      final response = await _client.patch(
        ApiConfig.repartidorDatosBancarios,
        campos,
      );

      _log('Datos bancarios actualizados parcialmente');
      return DatosBancarios.fromJson(response['datos_bancarios']);
    } catch (e, stackTrace) {
      _log('Error al actualizar datos bancarios parcialmente',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
