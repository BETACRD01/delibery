// lib/apis/repartidor/datos_bancarios_api.dart

import '../../config/network/api_config.dart';
import 'package:mobile/services/core/api/http_client.dart';

/// API para gestión de datos bancarios de repartidores
class DatosBancariosApi {
  static final DatosBancariosApi _instance = DatosBancariosApi._internal();
  factory DatosBancariosApi() => _instance;
  DatosBancariosApi._internal();

  final _client = ApiClient();

  /// Obtiene datos bancarios del repartidor
  Future<Map<String, dynamic>> getDatosBancarios() async {
    return await _client.get(ApiConfig.repartidorDatosBancarios);
  }

  /// Actualiza datos bancarios (PUT - completo)
  Future<Map<String, dynamic>> putDatosBancarios(
    Map<String, dynamic> data,
  ) async {
    return await _client.put(ApiConfig.repartidorDatosBancarios, data);
  }

  /// Actualiza datos bancarios parcialmente (PATCH)
  Future<Map<String, dynamic>> patchDatosBancarios(
    Map<String, String> campos,
  ) async {
    return await _client.patch(ApiConfig.repartidorDatosBancarios, campos);
  }
}
