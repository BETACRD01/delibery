// lib/services/pago/pago_service.dart

import 'dart:io';
import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';
import '../../models/payments/pago_model.dart';
import '../../models/payments/datos_bancarios.dart';
import 'dart:developer' as developer;

class PagoService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final PagoService _instance = PagoService._internal();
  factory PagoService() => _instance;
  PagoService._internal();

  final _client = ApiClient();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message,
        name: 'PagoService', error: error, stackTrace: stackTrace);
  }

  // ---------------------------------------------------------------------------
  // OBTENER DATOS BANCARIOS PARA TRANSFERENCIA
  // ---------------------------------------------------------------------------

  /// Obtiene los datos bancarios del repartidor para realizar la transferencia
  Future<DatosBancariosParaPago> obtenerDatosBancariosPago(int pagoId) async {
    try {
      _log('Obteniendo datos bancarios para pago $pagoId');

      final response = await _client.get(
        ApiConfig.obtenerDatosBancariosPago(pagoId),
      );

      _log('Datos bancarios obtenidos exitosamente');
      return DatosBancariosParaPago.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error al obtener datos bancarios', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // SUBIR COMPROBANTE DE PAGO
  // ---------------------------------------------------------------------------

  /// Sube el comprobante de transferencia (imagen)
  Future<PagoConComprobante> subirComprobante({
    required int pagoId,
    required File imagenComprobante,
    String? bancoOrigen,
    String? numeroOperacion,
  }) async {
    try {
      _log('Subiendo comprobante para pago $pagoId');

      // Preparar campos para multipart
      final fields = <String, String>{};
      if (bancoOrigen != null && bancoOrigen.isNotEmpty) {
        fields['transferencia_banco_origen'] = bancoOrigen;
      }
      if (numeroOperacion != null && numeroOperacion.isNotEmpty) {
        fields['transferencia_numero_operacion'] = numeroOperacion;
      }

      // Usar el método multipart de ApiClient
      final response = await _client.multipart(
        'POST',
        ApiConfig.subirComprobantePago(pagoId),
        fields,
        {'transferencia_comprobante': imagenComprobante},
      );

      _log('Comprobante subido exitosamente');
      return PagoConComprobante.fromJson(response['pago']);
    } catch (e, stackTrace) {
      _log('Error al subir comprobante', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VER COMPROBANTE (REPARTIDOR)
  // ---------------------------------------------------------------------------

  /// Permite al repartidor ver el comprobante de pago
  Future<ComprobanteRepartidor> verComprobante(int pagoId) async {
    try {
      _log('Obteniendo comprobante para pago $pagoId');

      final response = await _client.get(
        ApiConfig.verComprobanteRepartidor(pagoId),
      );

      _log('Comprobante obtenido exitosamente');
      return ComprobanteRepartidor.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error al obtener comprobante', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // MARCAR COMPROBANTE COMO VISTO (REPARTIDOR)
  // ---------------------------------------------------------------------------

  /// Marca el comprobante como visto por el repartidor
  Future<ComprobanteRepartidor> marcarComprobanteVisto(int pagoId) async {
    try {
      _log('Marcando comprobante como visto para pago $pagoId');

      final response = await _client.post(
        ApiConfig.marcarComprobanteVisto(pagoId),
        {'visto': true},
      );

      _log('Comprobante marcado como visto');
      return ComprobanteRepartidor.fromJson(response['pago']);
    } catch (e, stackTrace) {
      _log('Error al marcar comprobante como visto',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
