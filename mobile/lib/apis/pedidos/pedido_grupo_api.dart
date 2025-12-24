// lib/apis/pedidos/pedido_grupo_api.dart

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de grupos de pedidos
class PedidoGrupoApi {
  static final PedidoGrupoApi _instance = PedidoGrupoApi._internal();
  factory PedidoGrupoApi() => _instance;
  PedidoGrupoApi._internal();

  final _client = ApiClient();

  /// Lista pedidos de un grupo
  Future<Map<String, dynamic>> getPedidosGrupo(String pedidoGrupo) async {
    return await _client.get(ApiConfig.listarPedidosGrupo(pedidoGrupo));
  }

  /// Lista mis grupos de pedidos
  Future<Map<String, dynamic>> getMisGrupos() async {
    return await _client.get(ApiConfig.misGruposPedidos);
  }
}
