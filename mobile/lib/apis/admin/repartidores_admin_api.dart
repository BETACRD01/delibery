// lib/apis/admin/repartidores_admin_api.dart

import 'dart:developer' as developer;

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

class RepartidoresAdminAPI {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> listar({
    String? search,
    bool? verificado,
    bool? activo,
    String? estado,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'page_size': '$pageSize',
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (verificado != null) params['verificado'] = verificado.toString();
      if (activo != null) params['activo'] = activo.toString();
      if (estado != null && estado.isNotEmpty) params['estado'] = estado;

      final url = ApiConfig.adminRepartidores;
      final uri = Uri.parse(url).replace(queryParameters: params.isEmpty ? null : params);
      return await _client.get(uri.toString());
    } catch (e) {
      developer.log('Error listando repartidores: $e', name: 'RepartidoresAdminAPI');
      rethrow;
    }
  }

  Future<void> verificar(int repartidorId) async {
    try {
      await _client.post(ApiConfig.adminRepartidorVerificar(repartidorId), {});
    } catch (e) {
      developer.log('Error verificando repartidor: $e', name: 'RepartidoresAdminAPI');
      rethrow;
    }
  }

  Future<void> activar(int repartidorId) async {
    try {
      await _client.post(ApiConfig.adminRepartidorActivar(repartidorId), {});
    } catch (e) {
      developer.log('Error activando repartidor: $e', name: 'RepartidoresAdminAPI');
      rethrow;
    }
  }

  Future<void> desactivar(int repartidorId) async {
    try {
      await _client.post(ApiConfig.adminRepartidorDesactivar(repartidorId), {});
    } catch (e) {
      developer.log('Error desactivando repartidor: $e', name: 'RepartidoresAdminAPI');
      rethrow;
    }
  }
}
