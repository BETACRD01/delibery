import 'package:flutter/foundation.dart';
import '../../apis/pedidos/envio_api.dart';

class EnviosService {
  final _api = EnvioApi();

  Future<Map<String, dynamic>> cotizarEnvio({
    required double latDestino,
    required double lngDestino,
    double? latOrigen,
    double? lngOrigen,
    String tipoServicio = 'delivery',
  }) async {
    try {
      final Map<String, dynamic> body = {
        'lat_destino': latDestino,
        'lng_destino': lngDestino,
        'tipo_servicio': tipoServicio,
      };

      if (latOrigen != null && lngOrigen != null) {
        body['lat_origen'] = latOrigen;
        body['lng_origen'] = lngOrigen;
      }

      final response = await _api.cotizarEnvio(body);
      return response;
    } catch (e) {
      debugPrint('Error en EnviosService.cotizarEnvio: $e');
      rethrow;
    }
  }

  /// Crea un pedido de tipo Courier
  ///
  /// [origen] Mapa con lat, lng, direccion del punto de recogida
  /// [destino] Mapa con lat, lng, direccion del punto de entrega
  /// [receptor] Mapa con nombre y telefono del receptor
  /// [paquete] Mapa con tipo y descripcion del paquete
  /// [pago] Mapa con metodo (EFECTIVO/TRANSFERENCIA) y total_estimado
  Future<Map<String, dynamic>> crearPedidoCourier({
    required Map<String, dynamic> origen,
    required Map<String, dynamic> destino,
    required Map<String, dynamic> receptor,
    required Map<String, dynamic> paquete,
    required Map<String, dynamic> pago,
  }) async {
    try {
      final body = {
        'origen': origen,
        'destino': destino,
        'receptor': receptor,
        'paquete': paquete,
        'pago': pago,
      };

      final response = await _api.crearPedidoCourier(body);
      return response;
    } catch (e) {
      debugPrint('Error en EnviosService.crearPedidoCourier: $e');
      rethrow;
    }
  }
}
