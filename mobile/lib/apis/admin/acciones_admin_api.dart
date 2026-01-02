// lib/apis/admin/acciones_admin_api.dart

import 'dart:developer' as developer;

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

class AccionesAdminAPI {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> listar({int page = 1, int pageSize = 20}) async {
    try {
      final params = {
        'page': '$page',
        'page_size': '$pageSize',
      };
      final uri = Uri.parse(ApiConfig.adminAcciones).replace(queryParameters: params);
      return await _client.get(uri.toString());
    } catch (e) {
      developer.log('Error listando acciones admin: $e', name: 'AccionesAdminAPI');
      rethrow;
    }
  }
}
