// lib/apis/admin/proveedores_admin_api.dart

import 'dart:developer' as developer;

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

class ProveedoresAdminAPI {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> listar({String? search, bool? verificado, bool? activo, int page = 1}) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (verificado != null) params['verificado'] = verificado.toString();
      if (activo != null) params['activo'] = activo.toString();

      final url = ApiConfig.adminProveedores;
      final uri = Uri.parse(url).replace(queryParameters: params.isEmpty ? null : params);
      return await _client.get(uri.toString());
    } catch (e) {
      developer.log('Error listando proveedores: $e', name: 'ProveedoresAdminAPI');
      rethrow;
    }
  }

  Future<void> verificar(int proveedorId) async {
    try {
      await _client.post(ApiConfig.adminProveedorVerificar(proveedorId), {});
    } catch (e) {
      developer.log('Error verificando proveedor: $e', name: 'ProveedoresAdminAPI');
      rethrow;
    }
  }

  Future<void> activar(int proveedorId) async {
    try {
      await _client.post(ApiConfig.adminProveedorActivar(proveedorId), {});
    } catch (e) {
      developer.log('Error activando proveedor: $e', name: 'ProveedoresAdminAPI');
      rethrow;
    }
  }

  Future<void> desactivar(int proveedorId) async {
    try {
      await _client.post(ApiConfig.adminProveedorDesactivar(proveedorId), {});
    } catch (e) {
      developer.log('Error desactivando proveedor: $e', name: 'ProveedoresAdminAPI');
      rethrow;
    }
  }
}
