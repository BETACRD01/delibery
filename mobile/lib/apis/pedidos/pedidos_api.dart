// lib/apis/pedidos/pedidos_api.dart

import 'dart:io';

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de pedidos
class PedidosApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final PedidosApi _instance = PedidosApi._internal();
  factory PedidosApi() => _instance;
  PedidosApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // LISTADO Y DETALLE
  // ---------------------------------------------------------------------------

  /// Lista pedidos con filtros
  Future<Map<String, dynamic>> getPedidos({
    String? estado,
    String? tipo,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = ApiConfig.buildPedidosUrl(
      estado: estado,
      tipo: tipo,
      page: page,
      pageSize: pageSize,
    );
    return await _client.get(url);
  }

  /// Obtiene detalle de un pedido
  Future<Map<String, dynamic>> getPedido(int pedidoId) async {
    return await _client.get(ApiConfig.pedidoDetalle(pedidoId));
  }

  /// Crea un nuevo pedido
  Future<Map<String, dynamic>> createPedido(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.pedidos, data);
  }

  // ---------------------------------------------------------------------------
  // ACCIONES DE ESTADO
  // ---------------------------------------------------------------------------

  /// Repartidor acepta un pedido
  Future<Map<String, dynamic>> aceptarPedidoRepartidor(
    int pedidoId,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(
      ApiConfig.pedidoAceptarRepartidor(pedidoId),
      data,
    );
  }

  /// Proveedor confirma un pedido
  Future<Map<String, dynamic>> confirmarPedidoProveedor(
    int pedidoId,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(
      ApiConfig.pedidoConfirmarProveedor(pedidoId),
      data,
    );
  }

  /// Cambia el estado de un pedido
  Future<Map<String, dynamic>> cambiarEstado(
    int pedidoId,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.pedidoCambiarEstado(pedidoId), data);
  }

  /// Cambia el estado con imagen de evidencia
  Future<Map<String, dynamic>> cambiarEstadoConImagen(
    int pedidoId,
    String nuevoEstado,
    File imagen,
  ) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.pedidoCambiarEstado(pedidoId),
      {'nuevo_estado': nuevoEstado},
      {'imagen_evidencia': imagen},
    );
  }

  /// Cancela un pedido
  Future<Map<String, dynamic>> cancelarPedido(
    int pedidoId,
    Map<String, dynamic> data,
  ) async {
    return await _client.post(ApiConfig.pedidoCancelar(pedidoId), data);
  }

  /// Obtiene información de ganancias
  Future<Map<String, dynamic>> getGanancias(int pedidoId) async {
    return await _client.get(ApiConfig.pedidoGanancias(pedidoId));
  }

  // ---------------------------------------------------------------------------
  // CALIFICACIONES
  // ---------------------------------------------------------------------------

  /// Envía una calificación rápida
  Future<Map<String, dynamic>> enviarCalificacion(
    Map<String, dynamic> data,
  ) async {
    return await _client.post(ApiConfig.calificacionesRapida, data);
  }
}
