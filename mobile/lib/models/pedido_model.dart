// pedido_model.dart
class Pedido {
  final int id;
  final String numeroPedido;
  final String? pedidoGrupo; // 🆕 UUID para pedidos agrupados (multi-proveedor)
  final String tipo;
  final String tipoDisplay;
  final String estado;
  final String estadoDisplay;
  final String estadoPago;
  final String estadoPagoDisplay;
  final String descripcion;
  final double total;
  final String metodoPago;
  final String metodoPagoDisplay;
  final int? pagoId;
  final String? transferenciaComprobanteUrl;
  final String? instruccionesEntrega;
  
  final ClienteInfo? cliente;
  final ProveedorInfo? proveedor;
  final List<ProveedorInfo> proveedores;
  final RepartidorInfo? repartidor;
  
  final List<ItemPedido> items;
  
  final String? direccionOrigen;
  final double? latitudOrigen;
  final double? longitudOrigen;
  final String direccionEntrega;
  final double? latitudDestino;
  final double? longitudDestino;
  
  final String? imagenEvidencia;
  
  final double comisionRepartidor;
  final double comisionProveedor;
  final double gananciaApp;
  
  final bool aceptadoPorRepartidor;
  final bool confirmadoPorProveedor;
  final String? canceladoPor;
  final String? motivoCancelacion;
  
  final String tiempoTranscurrido;
  final bool esPedidoActivo;
  final bool puedeSerCancelado;
  final DatosEnvio? datosEnvio;

  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final DateTime? fechaConfirmado;
  final DateTime? fechaEnPreparacion;
  final DateTime? fechaEnRuta;
  final DateTime? fechaEntregado;
  final DateTime? fechaCancelado;

  Pedido({
    required this.id,
    required this.numeroPedido,
    this.pedidoGrupo, // 🆕 UUID del grupo (opcional)
    required this.tipo,
    required this.tipoDisplay,
    required this.estado,
    required this.estadoDisplay,
    required this.estadoPago,
    required this.estadoPagoDisplay,
    required this.descripcion,
    required this.total,
    required this.metodoPago,
    required this.metodoPagoDisplay,
    this.pagoId,
    this.transferenciaComprobanteUrl,
    this.instruccionesEntrega,
    this.cliente,
    this.proveedor,
    this.proveedores = const [],
    this.repartidor,
    required this.items,
    this.direccionOrigen,
    this.latitudOrigen,
    this.longitudOrigen,
    required this.direccionEntrega,
    this.latitudDestino,
    this.longitudDestino,
    this.imagenEvidencia,
    required this.comisionRepartidor,
    required this.comisionProveedor,
    required this.gananciaApp,
    required this.aceptadoPorRepartidor,
    required this.confirmadoPorProveedor,
    this.canceladoPor,
    this.motivoCancelacion,
    required this.tiempoTranscurrido,
    required this.esPedidoActivo,
    required this.puedeSerCancelado,
    this.datosEnvio,
    required this.creadoEn,
    required this.actualizadoEn,
    this.fechaConfirmado,
    this.fechaEnPreparacion,
    this.fechaEnRuta,
    this.fechaEntregado,
    this.fechaCancelado,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    String asString(dynamic v, [String fallback = '']) => (v ?? fallback).toString();
    double asDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    DateTime asDate(dynamic v) =>
        v != null ? DateTime.tryParse(v.toString()) ?? DateTime.now() : DateTime.now();

    final proveedorRaw = json['proveedor'];
    ProveedorInfo? proveedor;
    List<ProveedorInfo> proveedores = [];

    if (proveedorRaw is Map<String, dynamic>) {
      final prov = ProveedorInfo.fromJson(proveedorRaw);
      proveedor = prov;
      proveedores = [prov];
    } else if (proveedorRaw is List) {
      proveedores = proveedorRaw
          .whereType<Map<String, dynamic>>()
          .map((p) => ProveedorInfo.fromJson(p))
          .toList();
      if (proveedores.isNotEmpty) {
        proveedor = proveedores.first;
      }
    }

    return Pedido(
      id: json['id'],
      numeroPedido: asString(json['numero_pedido']),
      pedidoGrupo: json['pedido_grupo']?.toString(), // 🆕 UUID del grupo
      tipo: asString(json['tipo']),
      tipoDisplay: asString(json['tipo_display']),
      estado: asString(json['estado']),
      estadoDisplay: asString(json['estado_display']),
      estadoPago: asString(json['estado_pago']),
      estadoPagoDisplay: asString(json['estado_pago_display']),
      descripcion: asString(json['descripcion']),
      total: asDouble(json['total']),
      metodoPago: asString(json['metodo_pago']),
      metodoPagoDisplay: asString(json['metodo_pago_display']),
      pagoId: json['pago_id'] is int ? json['pago_id'] : int.tryParse(json['pago_id']?.toString() ?? ''),
      transferenciaComprobanteUrl: json['transferencia_comprobante_url']?.toString(),
      instruccionesEntrega: json['instrucciones_entrega']?.toString(),
      cliente: json['cliente'] != null 
          ? ClienteInfo.fromJson(json['cliente']) 
          : null,
      proveedor: proveedor,
      proveedores: proveedores,
      repartidor: json['repartidor'] != null 
          ? RepartidorInfo.fromJson(json['repartidor']) 
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ItemPedido.fromJson(item))
          .toList() ?? [],
      direccionOrigen: json['direccion_origen']?.toString(),
      latitudOrigen: json['latitud_origen'] != null 
          ? double.tryParse(json['latitud_origen'].toString()) 
          : null,
      longitudOrigen: json['longitud_origen'] != null 
          ? double.tryParse(json['longitud_origen'].toString()) 
          : null,
      direccionEntrega: asString(json['direccion_entrega']),
      latitudDestino: json['latitud_destino'] != null 
          ? double.tryParse(json['latitud_destino'].toString()) 
          : null,
      longitudDestino: json['longitud_destino'] != null 
          ? double.tryParse(json['longitud_destino'].toString()) 
          : null,
      imagenEvidencia: json['imagen_evidencia'],
      comisionRepartidor: asDouble(json['comision_repartidor']),
      comisionProveedor: asDouble(json['comision_proveedor']),
      gananciaApp: asDouble(json['ganancia_app']),
      aceptadoPorRepartidor: json['aceptado_por_repartidor'] ?? false,
      confirmadoPorProveedor: json['confirmado_por_proveedor'] ?? false,
      canceladoPor: json['cancelado_por'],
      motivoCancelacion: json['motivo_cancelacion'],
      tiempoTranscurrido: asString(json['tiempo_transcurrido']),
      esPedidoActivo: json['es_pedido_activo'] ?? false,
      puedeSerCancelado: json['puede_ser_cancelado'] ?? false,
      datosEnvio: json['datos_envio'] != null
          ? DatosEnvio.fromJson(json['datos_envio'] as Map<String, dynamic>)
          : null,
      creadoEn: asDate(json['creado_en']),
      actualizadoEn: asDate(json['actualizado_en']),
      fechaConfirmado: json['fecha_confirmado'] != null 
          ? DateTime.tryParse(json['fecha_confirmado'].toString()) 
          : null,
      fechaEnPreparacion: json['fecha_en_preparacion'] != null 
          ? DateTime.tryParse(json['fecha_en_preparacion'].toString()) 
          : null,
      fechaEnRuta: json['fecha_en_ruta'] != null 
          ? DateTime.tryParse(json['fecha_en_ruta'].toString()) 
          : null,
      fechaEntregado: json['fecha_entregado'] != null 
          ? DateTime.tryParse(json['fecha_entregado'].toString()) 
          : null,
      fechaCancelado: json['fecha_cancelado'] != null 
          ? DateTime.tryParse(json['fecha_cancelado'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_pedido': numeroPedido,
      'tipo': tipo,
      'estado': estado,
      'estado_pago': estadoPago,
      'descripcion': descripcion,
      'total': total,
      'metodo_pago': metodoPago,
      'direccion_origen': direccionOrigen,
      'latitud_origen': latitudOrigen,
      'longitud_origen': longitudOrigen,
      'direccion_entrega': direccionEntrega,
      'latitud_destino': latitudDestino,
      'longitud_destino': longitudDestino,
      'pago_id': pagoId,
      'transferencia_comprobante_url': transferenciaComprobanteUrl,
      'instrucciones_entrega': instruccionesEntrega,
      if (datosEnvio != null) 'datos_envio': datosEnvio!.toJson(),
    };
  }
}

class ClienteInfo {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;

  ClienteInfo({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
  });

  factory ClienteInfo.fromJson(Map<String, dynamic> json) {
    return ClienteInfo(
      id: json['id'],
      nombre: (json['nombre'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      telefono: json['telefono']?.toString(),
    );
  }
}

class ProveedorInfo {
  final int id;
  final String nombre;
  final String? telefono;
  final String? direccion;

  ProveedorInfo({
    required this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
  });

  factory ProveedorInfo.fromJson(Map<String, dynamic> json) {
    return ProveedorInfo(
      id: json['id'],
      nombre: (json['nombre'] ?? '').toString(),
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
    );
  }
}

class RepartidorInfo {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;

  RepartidorInfo({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
  });

  factory RepartidorInfo.fromJson(Map<String, dynamic> json) {
    return RepartidorInfo(
      id: json['id'],
      nombre: (json['nombre'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      telefono: json['telefono']?.toString(),
    );
  }
}

class ItemPedido {
  final int id;
  final int producto;
  final String productoNombre;
  final String? productoImagen;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? notas;

  ItemPedido({
    required this.id,
    required this.producto,
    required this.productoNombre,
    this.productoImagen,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.notas,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido(
      id: json['id'],
      producto: json['producto'],
      productoNombre: (json['producto_nombre'] ?? '').toString(),
      productoImagen: json['producto_imagen'],
      cantidad: json['cantidad'],
      precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'producto': producto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'notas': notas,
    };
  }
}

class PedidoListItem {
  final int id;
  final String numeroPedido;
  final String tipo;
  final String tipoDisplay;
  final String estado;
  final String estadoDisplay;
  final String estadoPago;
  final String estadoPagoDisplay;
  final String? clienteNombre;
  final String? proveedorNombre;
  final String? repartidorNombre;
  final double total;
  final String metodoPago;
  final String direccionEntrega;
  final String tiempoTranscurrido;
  final int cantidadItems;
  final String? primerProductoImagen;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  PedidoListItem({
    required this.id,
    required this.numeroPedido,
    required this.tipo,
    required this.tipoDisplay,
    required this.estado,
    required this.estadoDisplay,
    required this.estadoPago,
    required this.estadoPagoDisplay,
    this.clienteNombre,
    this.proveedorNombre,
    this.repartidorNombre,
    required this.total,
    required this.metodoPago,
    required this.direccionEntrega,
    required this.tiempoTranscurrido,
    required this.cantidadItems,
    this.primerProductoImagen,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  factory PedidoListItem.fromJson(Map<String, dynamic> json) {
    return PedidoListItem(
      id: json['id'],
      numeroPedido: (json['numero_pedido'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      tipoDisplay: (json['tipo_display'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      estadoDisplay: (json['estado_display'] ?? '').toString(),
      estadoPago: (json['estado_pago'] ?? '').toString(),
      estadoPagoDisplay: (json['estado_pago_display'] ?? '').toString(),
      clienteNombre: json['cliente_nombre']?.toString(),
      proveedorNombre: json['proveedor_nombre']?.toString(),
      repartidorNombre: json['repartidor_nombre']?.toString(),
      total: double.parse(json['total'].toString()),
      metodoPago: (json['metodo_pago'] ?? '').toString(),
      direccionEntrega: (json['direccion_entrega'] ?? '').toString(),
      tiempoTranscurrido: (json['tiempo_transcurrido'] ?? '').toString(),
      cantidadItems: int.tryParse(json['cantidad_items']?.toString() ?? '') ?? 0,
      primerProductoImagen: json['primer_producto_imagen']?.toString(),
      creadoEn: DateTime.parse(json['creado_en']),
      actualizadoEn: DateTime.parse(json['actualizado_en']),
    );
  }
}

class CrearPedidoRequest {
  final String tipo;
  final String descripcion;
  final int? proveedor;
  final String? direccionOrigen;
  final double? latitudOrigen;
  final double? longitudOrigen;
  final String direccionEntrega;
  final double? latitudDestino;
  final double? longitudDestino;
  final String metodoPago;
  final double total;
  final List<CrearItemPedido> items;

  CrearPedidoRequest({
    required this.tipo,
    required this.descripcion,
    this.proveedor,
    this.direccionOrigen,
    this.latitudOrigen,
    this.longitudOrigen,
    required this.direccionEntrega,
    this.latitudDestino,
    this.longitudDestino,
    required this.metodoPago,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'descripcion': descripcion,
      'proveedor': proveedor,
      'direccion_origen': direccionOrigen,
      'latitud_origen': latitudOrigen,
      'longitud_origen': longitudOrigen,
      'direccion_entrega': direccionEntrega,
      'latitud_destino': latitudDestino,
      'longitud_destino': longitudDestino,
      'metodo_pago': metodoPago,
      'total': total,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CrearItemPedido {
  final int producto;
  final int cantidad;
  final double precioUnitario;
  final String? notas;

  CrearItemPedido({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    this.notas,
  });

  Map<String, dynamic> toJson() {
    return {
      'producto': producto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'notas': notas,
    };
  }
}

class DatosEnvio {
  final double? distanciaKm;
  final int? tiempoEstimadoMins;
  final double? costoEnvio;
  final double? recargoNocturno;
  final bool recargoNocturnoAplicado;

  DatosEnvio({
    this.distanciaKm,
    this.tiempoEstimadoMins,
    this.costoEnvio,
    this.recargoNocturno,
    this.recargoNocturnoAplicado = false,
  });

  factory DatosEnvio.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());
    int? asInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
    return DatosEnvio(
      distanciaKm: asDouble(json['distancia_km']),
      tiempoEstimadoMins: asInt(json['tiempo_estimado_mins']),
      costoEnvio: asDouble(json['costo_envio']),
      recargoNocturno: asDouble(json['recargo_nocturno']),
      recargoNocturnoAplicado: json['recargo_nocturno_aplicado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distancia_km': distanciaKm,
      'tiempo_estimado_mins': tiempoEstimadoMins,
      'costo_envio': costoEnvio,
      'recargo_nocturno': recargoNocturno,
      'recargo_nocturno_aplicado': recargoNocturnoAplicado,
    };
  }
}
