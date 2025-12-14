// lib/services/pedido_grupo_service.dart

import '../apis/subapis/http_client.dart';
import '../config/api_config.dart';
import '../models/pedido_grupo.dart';
import 'dart:developer' as developer;

class PedidoGrupoService {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final PedidoGrupoService _instance = PedidoGrupoService._internal();
  factory PedidoGrupoService() => _instance;
  PedidoGrupoService._internal();

  final _client = ApiClient();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message,
        name: 'PedidoGrupoService', error: error, stackTrace: stackTrace);
  }

  // ---------------------------------------------------------------------------
  // LISTAR PEDIDOS DE UN GRUPO
  // ---------------------------------------------------------------------------

  /// Obtiene todos los pedidos que pertenecen a un grupo específico
  Future<PedidoGrupoDetalle> listarPedidosGrupo(String pedidoGrupo) async {
    try {
      _log('Listando pedidos del grupo: $pedidoGrupo');

      final response = await _client.get(
        ApiConfig.listarPedidosGrupo(pedidoGrupo),
      );

      _log('Pedidos del grupo obtenidos exitosamente');
      return PedidoGrupoDetalle.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error al listar pedidos del grupo',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // LISTAR MIS GRUPOS DE PEDIDOS
  // ---------------------------------------------------------------------------

  /// Obtiene todos los grupos de pedidos del cliente autenticado
  Future<MisGruposPedidos> listarMisGrupos() async {
    try {
      _log('Listando mis grupos de pedidos');

      final response = await _client.get(
        ApiConfig.misGruposPedidos,
      );

      _log('Grupos de pedidos obtenidos exitosamente');
      return MisGruposPedidos.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error al listar grupos de pedidos',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
