// lib/apis/rifas_usuarios_api.dart

import 'dart:developer' as developer;

import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';

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

  Future<Map<String, dynamic>> obtenerRifasMesActual() async {
    try {
      return await _client.get(ApiConfig.rifasMesActual);
    } catch (e) {
      developer.log(
        'Error obteniendo rifas del mes: $e',
        name: 'RifasUsuariosApi',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> participarEnRifa(String rifaId) async {
    try {
      return await _client.post(ApiConfig.rifasParticipar(rifaId), {});
    } catch (e) {
      developer.log(
        'Error participando en rifa $rifaId: $e',
        name: 'RifasUsuariosApi',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleRifa(String rifaId) async {
    try {
      return await _client.get(ApiConfig.rifasDetalle(rifaId));
    } catch (e) {
      developer.log(
        'Error obteniendo detalle de rifa $rifaId: $e',
        name: 'RifasUsuariosApi',
      );
      rethrow;
    }
  }
}
