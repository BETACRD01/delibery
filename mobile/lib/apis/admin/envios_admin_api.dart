// lib/apis/admin/envios_admin_api.dart

import 'dart:developer' as developer;

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

class EnviosAdminApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> obtenerConfiguracion() async {
    try {
      return await _client.get(ApiConfig.adminEnviosConfiguracion);
    } catch (e) {
      developer.log('Error obteniendo config de envíos: $e', name: 'EnviosAdminApi');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarConfiguracion(Map<String, dynamic> payload) async {
      return await _client.patch(ApiConfig.adminEnviosConfiguracion, payload);
  }

  Future<List<dynamic>> listarZonas() async {
    try {
      final data = await _client.get(ApiConfig.adminEnviosZonas);
      return data['results'] ?? data;
    } catch (e) {
      developer.log('Error listando zonas: $e', name: 'EnviosAdminApi');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> crearZona(Map<String, dynamic> payload) async {
    return await _client.post(ApiConfig.adminEnviosZonas, payload);
  }

  Future<Map<String, dynamic>> actualizarZona(int id, Map<String, dynamic> payload) async {
    final url = '${ApiConfig.adminEnviosZonas}$id/';
    return await _client.patch(url, payload);
  }

  Future<void> eliminarZona(int id) async {
    final url = '${ApiConfig.adminEnviosZonas}$id/';
    await _client.delete(url);
  }

  Future<List<dynamic>> listarCiudades() async {
    try {
      final data = await _client.get(ApiConfig.adminEnviosCiudades);
      return data['results'] ?? data;
    } catch (e) {
      developer.log('Error listando ciudades: $e', name: 'EnviosAdminApi');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> crearCiudad(Map<String, dynamic> payload) async {
    return await _client.post(ApiConfig.adminEnviosCiudades, payload);
  }

  Future<Map<String, dynamic>> actualizarCiudad(int id, Map<String, dynamic> payload) async {
    final url = '${ApiConfig.adminEnviosCiudades}$id/';
    return await _client.patch(url, payload);
  }

  Future<void> eliminarCiudad(int id) async {
    final url = '${ApiConfig.adminEnviosCiudades}$id/';
    await _client.delete(url);
  }
}
