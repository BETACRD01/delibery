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
  final double tarifaServicio;

  final bool aceptadoPorRepartidor;
  final bool confirmadoPorProveedor;
  final String? canceladoPor;
  final String? motivoCancelacion;

  final String tiempoTranscurrido;
  final bool esPedidoActivo;
  final bool puedeSerCancelado;
  final DatosEnvio? datosEnvio;
  final bool puedeCalificarRepartidor;
  final double? calificacionRepartidor;
  final bool puedeCalificarProveedor;
  final double? calificacionProveedor;

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
    required this.tarifaServicio,
    required this.aceptadoPorRepartidor,
    required this.confirmadoPorProveedor,
    this.canceladoPor,
    this.motivoCancelacion,
    required this.tiempoTranscurrido,
    required this.esPedidoActivo,
    required this.puedeSerCancelado,
    this.datosEnvio,
    this.puedeCalificarRepartidor = false,
    this.calificacionRepartidor,
    this.puedeCalificarProveedor = false,
    this.calificacionProveedor,
    required this.creadoEn,
    required this.actualizadoEn,
    this.fechaConfirmado,
    this.fechaEnPreparacion,
    this.fechaEnRuta,
    this.fechaEntregado,
    this.fechaCancelado,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    String asString(dynamic v, [String fallback = '']) =>
        (v ?? fallback).toString();
    double asDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;
    DateTime asDate(dynamic v) => v != null
        ? DateTime.tryParse(v.toString()) ?? DateTime.now()
        : DateTime.now();

    final proveedorRaw = json['proveedor'];
    ProveedorInfo? proveedor;
    List<ProveedorInfo> proveedores = [];

    if (proveedorRaw is Map<String, dynamic>) {
      final prov = ProveedorInfo.fromJson(proveedorRaw);
      proveedor = prov;
      proveedores = [prov];
    } else if (proveedorRaw is List) {
      proveedores = proveedorRaw
          .whereType<Map>()
          .map((p) => ProveedorInfo.fromJson(Map<String, dynamic>.from(p)))
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
      pagoId: json['pago_id'] is int
          ? json['pago_id']
          : int.tryParse(json['pago_id']?.toString() ?? ''),
      transferenciaComprobanteUrl: json['transferencia_comprobante_url']
          ?.toString(),
      instruccionesEntrega: json['instrucciones_entrega']?.toString(),
      cliente: json['cliente'] != null
          ? ClienteInfo.fromJson(json['cliente'])
          : null,
      proveedor: proveedor,
      proveedores: proveedores,
      repartidor: json['repartidor'] != null
          ? RepartidorInfo.fromJson(json['repartidor'])
          : null,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ItemPedido.fromJson(item))
              .toList() ??
          [],
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
      tarifaServicio: asDouble(json['tarifa_servicio']),
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
      puedeCalificarRepartidor: json['puede_calificar_repartidor'] ?? false,
      calificacionRepartidor: json['calificacion_repartidor'] is Map
          ? double.tryParse(
              (json['calificacion_repartidor']['estrellas'] ?? '').toString(),
            )
          : double.tryParse((json['calificacion_repartidor'] ?? '').toString()),
      puedeCalificarProveedor: json['puede_calificar_proveedor'] ?? false,
      calificacionProveedor: json['calificacion_proveedor'] is Map
          ? double.tryParse(
              (json['calificacion_proveedor']['estrellas'] ?? '').toString(),
            )
          : double.tryParse((json['calificacion_proveedor'] ?? '').toString()),
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
      'tarifa_servicio': tarifaServicio,
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
  final String? fotoPerfil;

  ProveedorInfo({
    required this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
    this.fotoPerfil,
  });

  factory ProveedorInfo.fromJson(Map<String, dynamic> json) {
    return ProveedorInfo(
      id: json['id'],
      nombre: (json['nombre'] ?? '').toString(),
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
      fotoPerfil: json['foto_perfil']?.toString() ?? json['foto']?.toString(),
    );
  }
}

class RepartidorInfo {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? fotoPerfil;
  final double? calificacionPromedio;
  final int totalCalificaciones;
  final Map<String, int>? desgloseCalificaciones;
  final double? porcentaje5Estrellas;
  final String? estado;
  final String? estadoDisplay;
  final double? latitud;
  final double? longitud;
  final DateTime? ultimaLocalizacion;
  final String? tipoVehiculoActivo;
  final String? placaVehiculoActiva;

  RepartidorInfo({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.fotoPerfil,
    this.calificacionPromedio,
    this.totalCalificaciones = 0,
    this.desgloseCalificaciones,
    this.porcentaje5Estrellas,
    this.estado,
    this.estadoDisplay,
    this.latitud,
    this.longitud,
    this.ultimaLocalizacion,
    this.tipoVehiculoActivo,
    this.placaVehiculoActiva,
  });

  factory RepartidorInfo.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) =>
        value != null ? double.tryParse(value.toString()) : null;

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    Map<String, int>? mapaDesglose;
    if (json['desglose_calificaciones'] is Map) {
      mapaDesglose = Map<String, dynamic>.from(
        json['desglose_calificaciones'],
      ).map((key, value) => MapEntry(key.toString(), parseInt(value)));
    }

    return RepartidorInfo(
      id: json['id'],
      nombre: (json['nombre'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      telefono: json['telefono']?.toString(),
      fotoPerfil: json['foto_perfil']?.toString(),
      calificacionPromedio: parseDouble(json['calificacion_promedio']),
      totalCalificaciones: parseInt(json['total_calificaciones']),
      desgloseCalificaciones: mapaDesglose,
      porcentaje5Estrellas: parseDouble(json['porcentaje_5_estrellas']),
      estado: json['estado']?.toString(),
      estadoDisplay: json['estado_display']?.toString(),
      latitud: parseDouble(json['latitud']),
      longitud: parseDouble(json['longitud']),
      ultimaLocalizacion: parseDate(json['ultima_localizacion']),
      tipoVehiculoActivo: json['tipo_vehiculo_activo']?.toString(),
      placaVehiculoActiva: json['placa_vehiculo_activa']?.toString(),
    );
  }
}

class CalificacionProductoInfo {
  final double estrellas;
  final String? comentario;
  final DateTime? fecha;

  CalificacionProductoInfo({
    required this.estrellas,
    this.comentario,
    this.fecha,
  });

  factory CalificacionProductoInfo.fromJson(Map<String, dynamic> json) {
    double parseEstrellas(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseFecha(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return CalificacionProductoInfo(
      estrellas: parseEstrellas(json['estrellas']),
      comentario: json['comentario']?.toString(),
      fecha: parseFecha(json['fecha']),
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
  final CalificacionProductoInfo? calificacionProductoInfo;
  final bool puedeCalificarProducto;

  ItemPedido({
    required this.id,
    required this.producto,
    required this.productoNombre,
    this.productoImagen,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.notas,
    this.calificacionProductoInfo,
    this.puedeCalificarProducto = false,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    CalificacionProductoInfo? calificacionInfo;
    if (json['calificacion_producto'] is Map) {
      calificacionInfo = CalificacionProductoInfo.fromJson(
        Map<String, dynamic>.from(json['calificacion_producto']),
      );
    }

    return ItemPedido(
      id: json['id'],
      producto: json['producto'],
      productoNombre: (json['producto_nombre'] ?? '').toString(),
      productoImagen: json['producto_imagen'],
      cantidad: json['cantidad'],
      precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      notas: json['notas'],
      calificacionProductoInfo: calificacionInfo,
      puedeCalificarProducto: json['puede_calificar_producto'] ?? false,
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
  // Campos opcionales para recargo nocturno
  final double? recargoNocturno;
  final bool recargoNocturnoAplicado;
  final double? costoEnvio; // Costo base del envío (sin recargo)

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
    this.recargoNocturno,
    this.recargoNocturnoAplicado = false,
    this.costoEnvio,
  });

  /// Total calculado incluyendo recargo nocturno si aplica
  /// Replica la lógica de PantallaDetalleCourier: Base + Recargo
  /// Total calculado incluyendo recargo nocturno si aplica
  double get totalConRecargo {
    try {
      // Lógica específica para ENCARGOS (Courier/Directo)
      // En estos casos, el total base a veces es solo el costo de envío base y necesitamos sumar el recargo explícitamente.
      final esEncargo =
          tipo.toLowerCase() == 'directo' || tipo.toLowerCase() == 'courier';

      if (recargoNocturno != null && recargoNocturno! > 0.01) {
        if (esEncargo) {
          // Encargo: La base es el costo de envío (si está disponible) o el total
          final base = costoEnvio ?? total;
          return base + recargoNocturno!;
        } else {
          // Pedido Normal: La base es el TOTAL (Productos + Envío Base).
          // El recargo nocturno se suma a este total.
          return total + recargoNocturno!;
        }
      }

      return total;
    } catch (_) {
      // Si ocurre un error de memoria (hot reload), retornamos total simple
      return total;
    }
  }

  factory PedidoListItem.fromJson(Map<String, dynamic> json) {
    // Parsear datos_envio si existe
    double? recargoNocturno;
    double? costoEnvio;
    bool recargoNocturnoAplicado = false;

    if (json['datos_envio'] is Map<String, dynamic>) {
      final datosEnvio = json['datos_envio'] as Map<String, dynamic>;
      recargoNocturnoAplicado = datosEnvio['recargo_nocturno_aplicado'] == true;

      if (datosEnvio['recargo_nocturno'] != null) {
        recargoNocturno = double.tryParse(
          datosEnvio['recargo_nocturno'].toString(),
        );
      }

      if (datosEnvio['costo_envio'] != null) {
        costoEnvio = double.tryParse(datosEnvio['costo_envio'].toString());
      }
    }

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
      cantidadItems:
          int.tryParse(json['cantidad_items']?.toString() ?? '') ?? 0,
      primerProductoImagen: json['primer_producto_imagen']?.toString(),
      creadoEn: DateTime.parse(json['creado_en']),
      actualizadoEn: DateTime.parse(json['actualizado_en']),
      recargoNocturno: recargoNocturno,
      recargoNocturnoAplicado: recargoNocturnoAplicado,
      costoEnvio: costoEnvio,
    );
  }
  @override
  String toString() {
    return 'PedidoListItem(id: $id, total: $total, recargo: $recargoNocturno, costoEnvio: $costoEnvio)';
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
    double? asDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
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
