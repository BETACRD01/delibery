// lib/apis/admin/dashboard_admin_api.dart

import 'dart:developer' as developer;

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

class DashboardAdminAPI {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      return await _client.get(ApiConfig.adminDashboard);
    } catch (e) {
      developer.log('Error obteniendo estadísticas admin: $e', name: 'DashboardAdminAPI');
      rethrow;
    }
  }
}
