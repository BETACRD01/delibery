// lib/apis/admin/usuarios_admin_api.dart

import 'dart:developer' as developer;

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

class UsuariosAdminAPI {
  final ApiClient _client = ApiClient();

  /// Busca usuarios por término (email, nombre, etc.)
  Future<Map<String, dynamic>> buscarUsuarios({String? search, int page = 1, int pageSize = 20}) async {
    try {
      final url = ApiConfig.buildAdminUsuariosUrl(search: search);
      final uri = Uri.parse(url).replace(
        queryParameters: {
          'page': '$page',
          'page_size': '$pageSize',
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = await _client.get(uri.toString());
      return data;
    } catch (e) {
      developer.log('Error buscando usuarios: $e', name: 'UsuariosAdminAPI');
      rethrow;
    }
  }

  /// Resetea la contraseña de un usuario (cliente, proveedor o repartidor)
  Future<void> resetearPassword({required int usuarioId, required String nuevaPassword}) async {
    try {
      final url = ApiConfig.adminUsuarioResetPassword(usuarioId);
      await _client.post(url, {
        'nueva_password': nuevaPassword,
        'confirmar_password': nuevaPassword,
      });
    } catch (e) {
      developer.log('Error reseteando password: $e', name: 'UsuariosAdminAPI');
      rethrow;
    }
  }
}
