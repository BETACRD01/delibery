// lib/models/pedido_grupo.dart

/// Modelo para un pedido dentro de un grupo (resumen)
class PedidoGrupoResumen {
  final int id;
  final String? numeroPedido;
  final String? proveedorNombre;
  final String total;
  final String estado;
  final String? estadoDisplay;
  final String? repartidorNombre;
  final int itemsCount;
  final DateTime creadoEn;

  PedidoGrupoResumen({
    required this.id,
    this.numeroPedido,
    this.proveedorNombre,
    required this.total,
    required this.estado,
    this.estadoDisplay,
    this.repartidorNombre,
    required this.itemsCount,
    required this.creadoEn,
  });

  factory PedidoGrupoResumen.fromJson(Map<String, dynamic> json) {
    return PedidoGrupoResumen(
      id: json['id'],
      numeroPedido: json['numero_pedido']?.toString(),
      proveedorNombre: json['proveedor_nombre']?.toString(),
      total: json['total']?.toString() ?? '0',
      estado: json['estado']?.toString() ?? '',
      estadoDisplay: json['estado_display']?.toString(),
      repartidorNombre: json['repartidor_nombre']?.toString(),
      itemsCount: json['items_count'] ?? 0,
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Modelo para el detalle completo de un grupo de pedidos
class PedidoGrupoDetalle {
  final String? pedidoGrupo;
  final int totalPedidos;
  final String totalGeneral;
  final String? direccionEntrega;
  final String estadoGeneral;
  final List<PedidoGrupoResumen> pedidos;
  final DateTime? creadoEn;

  PedidoGrupoDetalle({
    this.pedidoGrupo,
    required this.totalPedidos,
    required this.totalGeneral,
    this.direccionEntrega,
    required this.estadoGeneral,
    required this.pedidos,
    this.creadoEn,
  });

  factory PedidoGrupoDetalle.fromJson(Map<String, dynamic> json) {
    return PedidoGrupoDetalle(
      pedidoGrupo: json['pedido_grupo']?.toString(),
      totalPedidos: json['total_pedidos'] ?? 0,
      totalGeneral: json['total_general']?.toString() ?? '0',
      direccionEntrega: json['direccion_entrega']?.toString(),
      estadoGeneral: json['estado_general']?.toString() ?? '',
      pedidos: (json['pedidos'] as List<dynamic>?)
              ?.map((p) => PedidoGrupoResumen.fromJson(p))
              .toList() ??
          [],
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
          : null,
    );
  }

  /// Verifica si todos los pedidos están entregados
  bool get todosEntregados => estadoGeneral == 'Todos entregados';

  /// Verifica si todos los pedidos están cancelados
  bool get todosCancelados => estadoGeneral == 'Todos cancelados';

  /// Verifica si al menos un pedido está en camino
  bool get algunoEnCamino => estadoGeneral == 'En camino';

  /// Verifica si es un pedido multi-proveedor
  bool get esMultiProveedor => totalPedidos > 1;

  /// Obtiene la cantidad de proveedores diferentes
  int get cantidadProveedores {
    final proveedoresUnicos =
        pedidos.map((p) => p.proveedorNombre).toSet().length;
    return proveedoresUnicos;
  }
}

/// Respuesta de la lista de grupos de pedidos
class MisGruposPedidos {
  final int totalGrupos;
  final List<PedidoGrupoDetalle> grupos;

  MisGruposPedidos({
    required this.totalGrupos,
    required this.grupos,
  });

  factory MisGruposPedidos.fromJson(Map<String, dynamic> json) {
    return MisGruposPedidos(
      totalGrupos: json['total_grupos'] ?? 0,
      grupos: (json['grupos'] as List<dynamic>?)
              ?.map((g) => PedidoGrupoDetalle.fromJson(g))
              .toList() ??
          [],
    );
  }
}
