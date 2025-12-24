// lib/services/pedidos/envio_service.dart

import '../../config/api_config.dart';
import '../../apis/subapis/http_client.dart';
import '../../apis/helpers/api_exception.dart';

class EnvioService {
  final _client = ApiClient();

  /// Cotiza un envío usando coordenadas y cantidad de proveedores.
  Future<Map<String, dynamic>> cotizarEnvio({
    required double latOrigen,
    required double lngOrigen,
    required double latDestino,
    required double lngDestino,
    int proveedores = 1,
    String tipoServicio = 'delivery',
  }) async {
    try {
      final body = {
        'lat_origen': latOrigen,
        'lng_origen': lngOrigen,
        'lat_destino': latDestino,
        'lng_destino': lngDestino,
        'proveedores': proveedores,
        'tipo_servicio': tipoServicio,
      };
      return await _client.post(ApiConfig.enviosCotizar, body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error al cotizar envío',
        errors: {'error': e.toString()},
      );
    }
  }
}
