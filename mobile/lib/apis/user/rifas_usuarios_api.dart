// lib/apis/rifas_usuarios_api.dart

import 'dart:developer' as developer;

import '../subapis/http_client.dart';
import '../../config/api_config.dart';

class RifasUsuariosApi {
  final _client = ApiClient();

  Future<Map<String, dynamic>> obtenerRifaActiva() async {
    try {
      return await _client.get(ApiConfig.rifasActiva);
    } catch (e) {
      developer.log(
        'Error obteniendo rifa activa: $e',
        name: 'RifasUsuariosApi',
      );
      rethrow;
    }
  }
}
