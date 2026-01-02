// lib/apis/rifas_api.dart

import 'dart:developer' as developer;
import 'package:mobile/services/core/api/http_client.dart';
import '../../config/network/api_config.dart';

class RifasApi {
  final _client = ApiClient();

  Future<Map<String, dynamic>> misParticipaciones({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConfig.rifasMisParticipaciones,
      ).replace(queryParameters: {'page': '$page', 'page_size': '$pageSize'});
      return await _client.get(uri.toString());
    } catch (e) {
      developer.log(
        'Error obteniendo participaciones de rifas: $e',
        name: 'RifasApi',
      );
      rethrow;
    }
  }
}
