// lib/apis/pago/pago_api.dart

import 'dart:io';

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de pagos
class PagoApi {
  static final PagoApi _instance = PagoApi._internal();
  factory PagoApi() => _instance;
  PagoApi._internal();

  final _client = ApiClient();

  /// Obtiene datos bancarios para un pago
  Future<Map<String, dynamic>> getDatosBancarios(int pagoId) async {
    return await _client.get(ApiConfig.obtenerDatosBancariosPago(pagoId));
  }

  /// Sube comprobante de pago
  Future<Map<String, dynamic>> subirComprobante(
    int pagoId,
    Map<String, String> fields,
    File imagen,
  ) async {
    return await _client.multipart(
      'POST',
      ApiConfig.subirComprobantePago(pagoId),
      fields,
      {'transferencia_comprobante': imagen},
    );
  }

  /// Ver comprobante (repartidor)
  Future<Map<String, dynamic>> getComprobante(int pagoId) async {
    return await _client.get(ApiConfig.verComprobanteRepartidor(pagoId));
  }

  /// Marcar comprobante como visto
  Future<Map<String, dynamic>> marcarComprobanteVisto(int pagoId) async {
    return await _client.post(ApiConfig.marcarComprobanteVisto(pagoId), {
      'visto': true,
    });
  }
}
