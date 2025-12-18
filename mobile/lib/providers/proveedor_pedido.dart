// pedido_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/pedido_model.dart';
import '../services/pedido_service.dart';

class PedidoProvider extends ChangeNotifier {
  final PedidoService _service;

  PedidoProvider(this._service);

  /// AHORA FINAL ✔
  final List<PedidoListItem> _pedidos = [];

  Pedido? _pedidoActual;
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  bool _hasMore = true;

  List<PedidoListItem> get pedidos => _pedidos;
  Pedido? get pedidoActual => _pedidoActual;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // ───────────────────────────────────────────────────────────────
  // Cargar lista de pedidos
  // ───────────────────────────────────────────────────────────────
  Future<void> cargarPedidos({
    String? estado,
    String? tipo,
    bool refresh = false,
  }) async {
    const int pageSize = 20;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _pedidos.clear(); // sigue funcionando ✔
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nuevosPedidos = await _service.listarPedidos(
        estado: estado,
        tipo: tipo,
        page: _currentPage,
        pageSize: pageSize,
      );

      if (nuevosPedidos.isEmpty) {
        _hasMore = false;
      } else {
        _pedidos.addAll(nuevosPedidos);
        // Si vino menos que el pageSize, ya no hay más páginas
        if (nuevosPedidos.length < pageSize) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Cargar detalle del pedido
  // ───────────────────────────────────────────────────────────────
  Future<void> cargarDetalle(int pedidoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pedidoActual = await _service.obtenerDetalle(pedidoId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Crear pedido
  // ───────────────────────────────────────────────────────────────
  Future<bool> crearPedido(CrearPedidoRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pedido = await _service.crearPedido(request);
      _pedidoActual = pedido;

      _pedidos.insert(
        0,
        PedidoListItem(
          id: pedido.id,
          numeroPedido: pedido.numeroPedido,
          tipo: pedido.tipo,
          tipoDisplay: pedido.tipoDisplay,
          estado: pedido.estado,
          estadoDisplay: pedido.estadoDisplay,
          estadoPago: pedido.estadoPago,
          estadoPagoDisplay: pedido.estadoPagoDisplay,
          clienteNombre: pedido.cliente?.nombre,
          proveedorNombre: pedido.proveedor?.nombre,
          repartidorNombre: pedido.repartidor?.nombre,
          total: pedido.total,
          metodoPago: pedido.metodoPago,
          direccionEntrega: pedido.direccionEntrega,
          tiempoTranscurrido: pedido.tiempoTranscurrido,
          cantidadItems: pedido.items.length,
          creadoEn: pedido.creadoEn,
          actualizadoEn: pedido.actualizadoEn,
        ),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Aceptar pedido (repartidor)
  // ───────────────────────────────────────────────────────────────
  Future<bool> aceptarPedido({
    required int pedidoId,
    required int repartidorId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pedido = await _service.aceptarPedidoRepartidor(
        pedidoId: pedidoId,
        repartidorId: repartidorId,
      );

      _pedidoActual = pedido;
      _actualizarPedidoEnLista(pedido);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Confirmar pedido (proveedor)
  // ───────────────────────────────────────────────────────────────
  Future<bool> confirmarPedido({
    required int pedidoId,
    required int proveedorId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pedido = await _service.confirmarPedidoProveedor(
        pedidoId: pedidoId,
        proveedorId: proveedorId,
      );

      _pedidoActual = pedido;
      _actualizarPedidoEnLista(pedido);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Cambiar estado del pedido
  // ───────────────────────────────────────────────────────────────
  Future<bool> cambiarEstado({
    required int pedidoId,
    required String nuevoEstado,
    File? imagenEvidencia,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pedido = await _service.cambiarEstado(
        pedidoId: pedidoId,
        nuevoEstado: nuevoEstado,
        imagenEvidencia: imagenEvidencia,
      );

      _pedidoActual = pedido;
      _actualizarPedidoEnLista(pedido);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Cancelar pedido
  // ───────────────────────────────────────────────────────────────
  Future<bool> cancelarPedido({
    required int pedidoId,
    required String motivo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pedido = await _service.cancelarPedido(
        pedidoId: pedidoId,
        motivo: motivo,
      );

      _pedidoActual = pedido;
      _actualizarPedidoEnLista(pedido);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Calificar repartidor (cliente)
  // ───────────────────────────────────────────────────────────────
  Future<bool> calificarRepartidor({
    required int pedidoId,
    required int estrellas,
    String? comentario,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.calificarRepartidor(
        pedidoId: pedidoId,
        estrellas: estrellas,
        comentario: comentario,
      );

      // Refrescar detalle para reflejar cambio
      _pedidoActual = await _service.obtenerDetalle(pedidoId);
      _actualizarPedidoEnLista(_pedidoActual!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> calificarProveedor({
    required int pedidoId,
    required int estrellas,
    String? comentario,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.calificarProveedor(
        pedidoId: pedidoId,
        estrellas: estrellas,
        comentario: comentario,
      );

      _pedidoActual = await _service.obtenerDetalle(pedidoId);
      _actualizarPedidoEnLista(_pedidoActual!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> calificarProducto({
    required int pedidoId,
    required int productoId,
    int? itemId,
    required int estrellas,
    String? comentario,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.calificarProducto(
        pedidoId: pedidoId,
        productoId: productoId,
        itemId: itemId,
        estrellas: estrellas,
        comentario: comentario,
      );

      _pedidoActual = await _service.obtenerDetalle(pedidoId);
      _actualizarPedidoEnLista(_pedidoActual!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Obtener ganancias
  // ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> obtenerGanancias(int pedidoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ganancias = await _service.obtenerGanancias(pedidoId);
      _isLoading = false;
      notifyListeners();
      return ganancias;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Actualizar pedido en la lista
  // ───────────────────────────────────────────────────────────────
  void _actualizarPedidoEnLista(Pedido pedido) {
    final index = _pedidos.indexWhere((p) => p.id == pedido.id);
    if (index != -1) {
      _pedidos[index] = PedidoListItem(
        id: pedido.id,
        numeroPedido: pedido.numeroPedido,
        tipo: pedido.tipo,
        tipoDisplay: pedido.tipoDisplay,
        estado: pedido.estado,
        estadoDisplay: pedido.estadoDisplay,
        estadoPago: pedido.estadoPago,
        estadoPagoDisplay: pedido.estadoPagoDisplay,
        clienteNombre: pedido.cliente?.nombre,
        proveedorNombre: pedido.proveedor?.nombre,
        repartidorNombre: pedido.repartidor?.nombre,
        total: pedido.total,
        metodoPago: pedido.metodoPago,
        direccionEntrega: pedido.direccionEntrega,
        tiempoTranscurrido: pedido.tiempoTranscurrido,
        cantidadItems: pedido.items.length,
        creadoEn: pedido.creadoEn,
        actualizadoEn: pedido.actualizadoEn,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Limpiar
  // ───────────────────────────────────────────────────────────────
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void limpiarPedidoActual() {
    _pedidoActual = null;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────
  // Actualizar estado de pedido (desde push notification)
  // ───────────────────────────────────────────────────────────────
  void actualizarEstadoPedidoPush({
    required int pedidoId,
    required String nuevoEstado,
    required String estadoDisplay,
  }) {
    // Actualizar en la lista de pedidos
    final index = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (index != -1) {
      _pedidos[index] = PedidoListItem(
        id: _pedidos[index].id,
        numeroPedido: _pedidos[index].numeroPedido,
        tipo: _pedidos[index].tipo,
        tipoDisplay: _pedidos[index].tipoDisplay,
        estado: nuevoEstado,
        estadoDisplay: estadoDisplay,
        estadoPago: _pedidos[index].estadoPago,
        estadoPagoDisplay: _pedidos[index].estadoPagoDisplay,
        clienteNombre: _pedidos[index].clienteNombre,
        proveedorNombre: _pedidos[index].proveedorNombre,
        repartidorNombre: _pedidos[index].repartidorNombre,
        total: _pedidos[index].total,
        metodoPago: _pedidos[index].metodoPago,
        direccionEntrega: _pedidos[index].direccionEntrega,
        tiempoTranscurrido: _pedidos[index].tiempoTranscurrido,
        cantidadItems: _pedidos[index].cantidadItems,
        creadoEn: _pedidos[index].creadoEn,
        actualizadoEn: DateTime.now(),
      );
      notifyListeners();
    }

    // Si es el pedido actual, también actualizarlo
    if (_pedidoActual != null && _pedidoActual!.id == pedidoId) {
      // Recargar el detalle para obtener la información completa actualizada
      cargarDetalle(pedidoId);
    }
  }
}
