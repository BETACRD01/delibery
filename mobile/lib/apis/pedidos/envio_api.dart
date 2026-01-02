// lib/apis/pedidos/envio_api.dart

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para cotización y creación de envíos
class EnvioApi {
  static final EnvioApi _instance = EnvioApi._internal();
  factory EnvioApi() => _instance;
  EnvioApi._internal();

  final _client = ApiClient();

  /// Cotiza un envío
  Future<Map<String, dynamic>> cotizarEnvio(Map<String, dynamic> body) async {
    return await _client.post(ApiConfig.enviosCotizar, body);
  }

  /// Crea un pedido de tipo Courier
  Future<Map<String, dynamic>> crearPedidoCourier(
    Map<String, dynamic> body,
  ) async {
    return await _client.post(ApiConfig.enviosCrearCourier, body);
  }
}
