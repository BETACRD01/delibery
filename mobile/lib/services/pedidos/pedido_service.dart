// lib/services/pedidos/pedido_service.dart

import 'dart:io';

import '../../apis/pedidos/pedidos_api.dart';
import '../../models/pedido_model.dart';

/// Servicio para gestión de pedidos
/// Delegación: Usa PedidosApi para llamadas HTTP
class PedidoService {
  final _pedidosApi = PedidosApi();

  /// Lista pedidos con paginación y filtros
  Future<List<PedidoListItem>> listarPedidos({
    String? estado,
    String? tipo,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _pedidosApi.getPedidos(
        estado: estado,
        tipo: tipo,
        page: page,
        pageSize: pageSize,
      );

      final results = response['results'] as List;
      return results.map((json) => PedidoListItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al listar pedidos: $e');
    }
  }

  /// Obtiene el detalle completo de un pedido
  Future<Pedido> obtenerDetalle(int pedidoId) async {
    try {
      final response = await _pedidosApi.getPedido(pedidoId);
      return Pedido.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener detalle: $e');
    }
  }

  /// Crea un nuevo pedido
  Future<Pedido> crearPedido(CrearPedidoRequest request) async {
    try {
      final response = await _pedidosApi.createPedido(request.toJson());
      return Pedido.fromJson(response['pedido']);
    } catch (e) {
      throw Exception('Error al crear pedido: $e');
    }
  }

  /// Repartidor acepta un pedido
  Future<Pedido> aceptarPedidoRepartidor({
    required int pedidoId,
    required int repartidorId,
  }) async {
    try {
      final response = await _pedidosApi.aceptarPedidoRepartidor(pedidoId, {
        'repartidor_id': repartidorId,
      });
      return Pedido.fromJson(response['pedido']);
    } catch (e) {
      throw Exception('Error al aceptar pedido: $e');
    }
  }

  /// Proveedor confirma el pedido
  Future<Pedido> confirmarPedidoProveedor({
    required int pedidoId,
    required int proveedorId,
  }) async {
    try {
      final response = await _pedidosApi.confirmarPedidoProveedor(pedidoId, {
        'proveedor_id': proveedorId,
      });
      return Pedido.fromJson(response['pedido']);
    } catch (e) {
      throw Exception('Error al confirmar pedido: $e');
    }
  }

  /// Cambia el estado de un pedido (con o sin imagen)
  Future<Pedido> cambiarEstado({
    required int pedidoId,
    required String nuevoEstado,
    File? imagenEvidencia,
  }) async {
    try {
      if (imagenEvidencia != null) {
        return await _cambiarEstadoConImagen(
          pedidoId: pedidoId,
          nuevoEstado: nuevoEstado,
          imagen: imagenEvidencia,
        );
      }

      final response = await _pedidosApi.cambiarEstado(pedidoId, {
        'nuevo_estado': nuevoEstado,
      });
      return Pedido.fromJson(response['pedido']);
    } catch (e) {
      throw Exception('Error al cambiar estado: $e');
    }
  }

  /// Cambia el estado con imagen de evidencia
  Future<Pedido> _cambiarEstadoConImagen({
    required int pedidoId,
    required String nuevoEstado,
    required File imagen,
  }) async {
    try {
      final response = await _pedidosApi.cambiarEstadoConImagen(
        pedidoId,
        nuevoEstado,
        imagen,
      );
      return Pedido.fromJson(response['pedido']);
    } catch (e) {
      throw Exception('Error al cambiar estado con imagen: $e');
    }
  }

  /// Cancela un pedido
  Future<Pedido> cancelarPedido({
    required int pedidoId,
    required String motivo,
  }) async {
    try {
      final response = await _pedidosApi.cancelarPedido(pedidoId, {
        'motivo': motivo,
      });
      return Pedido.fromJson(response['pedido']);
    } catch (e) {
      throw Exception('Error al cancelar pedido: $e');
    }
  }

  /// Obtiene información de ganancias de un pedido
  Future<Map<String, dynamic>> obtenerGanancias(int pedidoId) async {
    try {
      return await _pedidosApi.getGanancias(pedidoId);
    } catch (e) {
      throw Exception('Error al obtener ganancias: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Calificación rápida (cliente → repartidor)
  // ---------------------------------------------------------------------------
  Future<void> calificarRepartidor({
    required int pedidoId,
    required int estrellas,
    String? comentario,
  }) async {
    try {
      await _pedidosApi.enviarCalificacion({
        'pedido_id': pedidoId,
        'tipo': 'cliente_a_repartidor',
        'estrellas': estrellas,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario,
      });
    } catch (e) {
      throw Exception('No se pudo enviar la calificación: $e');
    }
  }

  // Calificación rápida (cliente → proveedor)
  Future<void> calificarProveedor({
    required int pedidoId,
    required int estrellas,
    String? comentario,
  }) async {
    try {
      await _pedidosApi.enviarCalificacion({
        'pedido_id': pedidoId,
        'tipo': 'cliente_a_proveedor',
        'estrellas': estrellas,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario,
      });
    } catch (e) {
      throw Exception('No se pudo enviar la calificación: $e');
    }
  }

  Future<void> calificarProducto({
    required int pedidoId,
    required int productoId,
    int? itemId,
    required int estrellas,
    String? comentario,
  }) async {
    try {
      await _pedidosApi.enviarCalificacion({
        'pedido_id': pedidoId,
        'tipo': 'cliente_a_producto',
        'producto_id': productoId,
        if (itemId != null) 'item_id': itemId,
        'estrellas': estrellas,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario,
      });
    } catch (e) {
      throw Exception('No se pudo enviar la calificación: $e');
    }
  }
}
