// Modelo para pedidos disponibles en el mapa (RESUMIDO - sin datos sensibles)
class PedidoDisponible {
  final int id;
  final String numeroPedido;
  final String tipo;
  final String tipoDisplay;
  final String estado;
  final String estadoDisplay;
  final String proveedorNombre;
  final double total;
  final String metodoPago;
  final double? comisionRepartidor;
  final String? descripcion;
  final String zonaEntrega;
  final double? latitudDestino;
  final double? longitudDestino;
  final DateTime? creadoEn;

  // Campos calculados del backend
  final double distanciaKm;
  final int tiempoEstimadoMin;

  // Datos de envío para calcular total con recargo nocturno
  final double? costoEnvio;
  final double? recargoNocturno;
  final bool recargoNocturnoAplicado;

  /// Total calculado incluyendo recargo nocturno si aplica
  double get totalConRecargo {
    if (recargoNocturno != null && recargoNocturno! > 0.01) {
      return total + recargoNocturno!;
    }
    return total;
  }

  /// Ganancia total estimada para el repartidor (Comisión base + Recargos)
  double get gananciaTotal {
    return comisionRepartidor ?? 0.0;
  }

  PedidoDisponible({
    required this.id,
    required this.numeroPedido,
    required this.tipo,
    required this.tipoDisplay,
    required this.estado,
    required this.estadoDisplay,
    required this.proveedorNombre,
    required this.total,
    required this.metodoPago,
    this.comisionRepartidor,
    this.descripcion,
    required this.zonaEntrega,
    this.latitudDestino,
    this.longitudDestino,
    this.creadoEn,
    required this.distanciaKm,
    required this.tiempoEstimadoMin,
    this.costoEnvio,
    this.recargoNocturno,
    this.recargoNocturnoAplicado = false,
  });

  /// Factory para crear desde JSON del backend (RESUMIDO)
  factory PedidoDisponible.fromJson(Map<String, dynamic> json) {
    // Helper para parsear números que pueden venir como String o num
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Parsear datos_envio si existe
    double? recargoNocturno;
    double? costoEnvio;
    bool recargoNocturnoAplicado = false;

    if (json['datos_envio'] is Map<String, dynamic>) {
      final datosEnvio = json['datos_envio'] as Map<String, dynamic>;
      recargoNocturnoAplicado = datosEnvio['recargo_nocturno_aplicado'] == true;
      if (datosEnvio['recargo_nocturno'] != null) {
        recargoNocturno = parseDouble(datosEnvio['recargo_nocturno']);
      }
      if (datosEnvio['costo_envio'] != null) {
        costoEnvio = parseDouble(datosEnvio['costo_envio']);
      }
    }

    return PedidoDisponible(
      id: _asInt(json['id']),
      numeroPedido: (json['numero_pedido'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      tipoDisplay: (json['tipo_display'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      estadoDisplay: (json['estado_display'] ?? '').toString(),
      proveedorNombre: (json['proveedor_nombre'] ?? 'Proveedor').toString(),
      total: parseDouble(json['total']),
      metodoPago: (json['metodo_pago'] ?? '').toString(),
      comisionRepartidor: json['comision_repartidor'] != null
          ? parseDouble(json['comision_repartidor'])
          : null,
      descripcion: json['descripcion']?.toString(),
      zonaEntrega: (json['zona_entrega'] ?? 'Zona no especificada').toString(),
      latitudDestino: json['latitud_destino'] != null
          ? parseDouble(json['latitud_destino'])
          : null,
      longitudDestino: json['longitud_destino'] != null
          ? parseDouble(json['longitud_destino'])
          : null,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
          : null,
      distanciaKm: parseDouble(json['distancia_km']),
      tiempoEstimadoMin: _asInt(json['tiempo_estimado_min']),
      costoEnvio: costoEnvio,
      recargoNocturno: recargoNocturno,
      recargoNocturnoAplicado: recargoNocturnoAplicado,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_pedido': numeroPedido,
      'tipo': tipo,
      'tipo_display': tipoDisplay,
      'estado': estado,
      'estado_display': estadoDisplay,
      'proveedor_nombre': proveedorNombre,
      'total': total,
      'metodo_pago': metodoPago,
      'comision_repartidor': comisionRepartidor,
      'descripcion': descripcion,
      'zona_entrega': zonaEntrega,
      'latitud_destino': latitudDestino,
      'longitud_destino': longitudDestino,
      'creado_en': creadoEn?.toIso8601String(),
      'distancia_km': distanciaKm,
      'tiempo_estimado_min': tiempoEstimadoMin,
    };
  }

  /// Copia con modificaciones
  PedidoDisponible copyWith({
    int? id,
    String? numeroPedido,
    String? tipo,
    String? tipoDisplay,
    String? estado,
    String? estadoDisplay,
    String? proveedorNombre,
    double? total,
    String? metodoPago,
    double? comisionRepartidor,
    String? descripcion,
    String? zonaEntrega,
    double? latitudDestino,
    double? longitudDestino,
    DateTime? creadoEn,
    double? distanciaKm,
    int? tiempoEstimadoMin,
  }) {
    return PedidoDisponible(
      id: id ?? this.id,
      numeroPedido: numeroPedido ?? this.numeroPedido,
      tipo: tipo ?? this.tipo,
      tipoDisplay: tipoDisplay ?? this.tipoDisplay,
      estado: estado ?? this.estado,
      estadoDisplay: estadoDisplay ?? this.estadoDisplay,
      proveedorNombre: proveedorNombre ?? this.proveedorNombre,
      total: total ?? this.total,
      metodoPago: metodoPago ?? this.metodoPago,
      comisionRepartidor: comisionRepartidor ?? this.comisionRepartidor,
      descripcion: descripcion ?? this.descripcion,
      zonaEntrega: zonaEntrega ?? this.zonaEntrega,
      latitudDestino: latitudDestino ?? this.latitudDestino,
      longitudDestino: longitudDestino ?? this.longitudDestino,
      creadoEn: creadoEn ?? this.creadoEn,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      tiempoEstimadoMin: tiempoEstimadoMin ?? this.tiempoEstimadoMin,
    );
  }

  @override
  String toString() {
    return 'PedidoDisponible(id: $id, #$numeroPedido, $proveedorNombre, zona: $zonaEntrega, distancia: ${distanciaKm}km, total: \$$total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PedidoDisponible && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Respuesta completa del endpoint de pedidos disponibles
class PedidosDisponiblesResponse {
  final UbicacionRepartidor repartidorUbicacion;
  final double radioKm;
  final int totalPedidos;
  final List<PedidoDisponible> pedidos;

  PedidosDisponiblesResponse({
    required this.repartidorUbicacion,
    required this.radioKm,
    required this.totalPedidos,
    required this.pedidos,
  });

  factory PedidosDisponiblesResponse.fromJson(Map<String, dynamic> json) {
    return PedidosDisponiblesResponse(
      repartidorUbicacion: json['repartidor_ubicacion'] is Map<String, dynamic>
          ? UbicacionRepartidor.fromJson(
              json['repartidor_ubicacion'] as Map<String, dynamic>,
            )
          : UbicacionRepartidor(latitud: 0, longitud: 0),
      radioKm: (json['radio_km'] is num)
          ? (json['radio_km'] as num).toDouble()
          : 0,
      totalPedidos: _asInt(json['total_pedidos']),
      pedidos: (json['pedidos'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PedidoDisponible.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repartidor_ubicacion': repartidorUbicacion.toJson(),
      'radio_km': radioKm,
      'total_pedidos': totalPedidos,
      'pedidos': pedidos.map((p) => p.toJson()).toList(),
    };
  }
}

// Helpers generales para parseo defensivo
int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Ubicación del repartidor
class UbicacionRepartidor {
  final double latitud;
  final double longitud;

  UbicacionRepartidor({required this.latitud, required this.longitud});

  factory UbicacionRepartidor.fromJson(Map<String, dynamic> json) {
    return UbicacionRepartidor(
      latitud: _asDouble(json['latitud']),
      longitud: _asDouble(json['longitud']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitud': latitud, 'longitud': longitud};
  }
}

/// Modelo DETALLADO del pedido (solo disponible después de aceptar)
/// Incluye datos sensibles del cliente que no se muestran en la lista
class PedidoDetalladoRepartidor {
  final int id;
  final String numeroPedido;
  final String tipo;
  final String tipoDisplay;
  final String estado;
  final String estadoDisplay;

  // Información completa del cliente (solo para pedidos ASIGNADOS)
  final ClienteDetalle cliente;

  // Información del proveedor
  final ProveedorDetalle proveedor;

  // Pago/Transferencia
  final int? pagoId;
  final String? estadoPagoActual;
  final String? transferenciaComprobanteUrl;
  final String? instruccionesEntrega;

  // Detalles del pedido
  final double total;
  final String metodoPago;
  final double? comisionRepartidor;
  final double? costoEnvioCalculado;
  final double? descuentoAplicado;
  final String? descripcion;

  // Dirección COMPLETA
  final String? direccionOrigen;
  final double? latitudOrigen;
  final double? longitudOrigen;
  final String direccionEntrega;
  final double? latitudDestino;
  final double? longitudDestino;

  // Items del pedido
  final List<ItemPedido>? items;

  // Datos de envío con información de zona
  final DatosEnvio? datosEnvio;

  // Fechas
  final DateTime creadoEn;
  final DateTime? confirmadoEn;
  final DateTime? entregadoEn;

  PedidoDetalladoRepartidor({
    required this.id,
    required this.numeroPedido,
    required this.tipo,
    required this.tipoDisplay,
    required this.estado,
    required this.estadoDisplay,
    this.pagoId,
    this.estadoPagoActual,
    this.transferenciaComprobanteUrl,
    this.instruccionesEntrega,
    required this.cliente,
    required this.proveedor,
    required this.total,
    required this.metodoPago,
    this.comisionRepartidor,
    this.costoEnvioCalculado,
    this.descuentoAplicado,
    this.descripcion,
    this.direccionOrigen,
    this.latitudOrigen,
    this.longitudOrigen,
    required this.direccionEntrega,
    this.latitudDestino,
    this.longitudDestino,
    this.items,
    this.datosEnvio,
    required this.creadoEn,
    this.confirmadoEn,
    this.entregadoEn,
  });

  // Getters calculados desde items
  double get subtotal {
    if (items == null || items!.isEmpty) return total;
    return items!.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get costoEnvio {
    // Prioridad 1: Usar datos de envío completos si existen
    if (datosEnvio != null) return datosEnvio!.costoTotal;

    // Prioridad 2: Usar el valor calculado del backend
    if (costoEnvioCalculado != null) return costoEnvioCalculado!;

    // Prioridad 3: Calcular como la diferencia entre el total y el subtotal de items
    if (items != null && items!.isNotEmpty) {
      final subtotalItems = items!.fold(
        0.0,
        (sum, item) => sum + item.subtotal,
      );
      final envio = total - subtotalItems;
      return envio > 0 ? envio : 0.0;
    }

    // Si no hay items, retornar 0 (no se puede calcular)
    return 0.0;
  }

  double? get descuento => descuentoAplicado;

  /// Total incluyendo recargo nocturno si aplica
  /// NOTA: El backend ya envía el campo 'total' con el recargo incluido,
  /// por lo que simplemente retornamos el total directamente.
  /// Este getter existe por compatibilidad con PedidoListItem.
  double get totalConRecargo {
    // El backend ya incluye el recargo en el total, retornamos directo
    return total;
  }

  /// Ganancia total estimada (Comisión + Recargos)
  double get gananciaTotal {
    return comisionRepartidor ?? 0.0;
  }

  factory PedidoDetalladoRepartidor.fromJson(Map<String, dynamic> json) {
    // Helpers de parseo defensivo
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    Map<String, dynamic>? asMap(dynamic value) =>
        value is Map<String, dynamic> ? value : null;

    List<Map<String, dynamic>> asMapList(dynamic value) {
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
      return const [];
    }

    Map<String, dynamic>? pickFirstMap(dynamic value) {
      final list = asMapList(value);
      if (list.isNotEmpty) return list.first;
      return asMap(value);
    }

    return PedidoDetalladoRepartidor(
      id: _asInt(json['id']),
      numeroPedido: (json['numero_pedido'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      tipoDisplay: (json['tipo_display'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      estadoDisplay: (json['estado_display'] ?? '').toString(),
      pagoId: json['pago_id'] != null ? _asInt(json['pago_id']) : null,
      estadoPagoActual: json['estado_pago_actual']?.toString(),
      transferenciaComprobanteUrl: json['transferencia_comprobante_url']
          ?.toString(),
      instruccionesEntrega: json['instrucciones_entrega']?.toString(),
      cliente: ClienteDetalle.fromJson(
        asMap(json['cliente']) ?? const <String, dynamic>{},
      ),
      proveedor: ProveedorDetalle.fromJson(
        pickFirstMap(json['proveedor']) ?? const <String, dynamic>{},
      ),
      total: parseDouble(json['total']),
      metodoPago: json['metodo_pago'] as String? ?? '',
      comisionRepartidor: json['comision_repartidor'] != null
          ? parseDouble(json['comision_repartidor'])
          : null,
      costoEnvioCalculado: json['costo_envio'] != null
          ? parseDouble(json['costo_envio'])
          : null,
      descuentoAplicado: json['descuento'] != null
          ? parseDouble(json['descuento'])
          : null,
      descripcion: json['descripcion'] as String?,
      direccionOrigen: json['direccion_origen'] as String?,
      latitudOrigen: json['latitud_origen'] != null
          ? parseDouble(json['latitud_origen'])
          : null,
      longitudOrigen: json['longitud_origen'] != null
          ? parseDouble(json['longitud_origen'])
          : null,
      direccionEntrega: json['direccion_entrega'] as String? ?? '',
      latitudDestino: json['latitud_destino'] != null
          ? parseDouble(json['latitud_destino'])
          : null,
      longitudDestino: json['longitud_destino'] != null
          ? parseDouble(json['longitud_destino'])
          : null,
      items: json['items'] != null
          ? asMapList(json['items']).map((i) => ItemPedido.fromJson(i)).toList()
          : null,
      datosEnvio: asMap(json['datos_envio']) != null
          ? DatosEnvio.fromJson(asMap(json['datos_envio'])!)
          : null,
      creadoEn:
          DateTime.tryParse(json['creado_en'] as String? ?? '') ??
          DateTime.now(),
      confirmadoEn: json['confirmado_en'] != null
          ? DateTime.tryParse(json['confirmado_en'] as String)
          : null,
      entregadoEn: json['entregado_en'] != null
          ? DateTime.tryParse(json['entregado_en'] as String)
          : null,
    );
  }
}

/// Información del cliente (SOLO visible para pedidos asignados)
class ClienteDetalle {
  final int id;
  final String nombre;
  final String? telefono; // DATO SENSIBLE
  final String? foto;

  ClienteDetalle({
    required this.id,
    required this.nombre,
    this.telefono,
    this.foto,
  });

  factory ClienteDetalle.fromJson(Map<String, dynamic> json) {
    return ClienteDetalle(
      id: _asInt(json['id']),
      nombre: (json['nombre'] ?? 'Cliente').toString(),
      telefono: json['telefono'] as String?,
      foto: json['foto'] as String?,
    );
  }

  factory ClienteDetalle.vacio() => ClienteDetalle(id: 0, nombre: 'Cliente');
}

/// Información del proveedor
class ProveedorDetalle {
  final int id;
  final String nombre;
  final String? telefono;
  final String? direccion;
  final double? latitud;
  final double? longitud;

  ProveedorDetalle({
    required this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
    this.latitud,
    this.longitud,
  });

  factory ProveedorDetalle.fromJson(Map<String, dynamic> json) {
    double? parseDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ProveedorDetalle(
      id: _asInt(json['id']),
      nombre: (json['nombre'] ?? 'Proveedor').toString(),
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      latitud: parseDoubleNullable(json['latitud']),
      longitud: parseDoubleNullable(json['longitud']),
    );
  }

  factory ProveedorDetalle.vacio() =>
      ProveedorDetalle(id: 0, nombre: 'Proveedor');
}

/// Item individual del pedido
class ItemPedido {
  final int id;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? notas;

  ItemPedido({
    required this.id,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.notas,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    // Helper para parsear números que pueden venir como String o num
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return ItemPedido(
      id: _asInt(json['id']),
      productoNombre: (json['producto_nombre'] ?? '').toString(),
      cantidad: _asInt(json['cantidad']),
      precioUnitario: parseDouble(json['precio_unitario']),
      subtotal: parseDouble(json['subtotal']),
      notas: json['notas'] as String?,
    );
  }
}

/// Datos completos del envío incluyendo información de zona
class DatosEnvio {
  final String? ciudadOrigen;
  final String? zonaDestino;
  final String? zonaNombre;
  final double distanciaKm;
  final int tiempoEstimadoMins;
  final double costoBase;
  final double costoKmAdicional;
  final double recargoNocturno;
  final double costoTotal;
  final bool enCamino;
  final bool recargoNocturnoAplicado;

  DatosEnvio({
    this.ciudadOrigen,
    this.zonaDestino,
    this.zonaNombre,
    required this.distanciaKm,
    required this.tiempoEstimadoMins,
    required this.costoBase,
    required this.costoKmAdicional,
    required this.recargoNocturno,
    required this.costoTotal,
    required this.enCamino,
    required this.recargoNocturnoAplicado,
  });

  factory DatosEnvio.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return DatosEnvio(
      ciudadOrigen: json['ciudad_origen'] as String?,
      zonaDestino: json['zona_destino'] as String?,
      zonaNombre: json['zona_nombre'] as String?,
      distanciaKm: parseDouble(json['distancia_km']),
      tiempoEstimadoMins: json['tiempo_estimado_mins'] as int? ?? 0,
      costoBase: parseDouble(json['costo_base']),
      costoKmAdicional: parseDouble(json['costo_km_adicional']),
      recargoNocturno: parseDouble(json['recargo_nocturno']),
      costoTotal: parseDouble(json['costo_envio']),
      enCamino: json['en_camino'] as bool? ?? false,
      recargoNocturnoAplicado:
          json['recargo_nocturno_aplicado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ciudad_origen': ciudadOrigen,
      'zona_destino': zonaDestino,
      'zona_nombre': zonaNombre,
      'distancia_km': distanciaKm,
      'tiempo_estimado_mins': tiempoEstimadoMins,
      'costo_base': costoBase,
      'costo_km_adicional': costoKmAdicional,
      'recargo_nocturno': recargoNocturno,
      'costo_envio': costoTotal,
      'en_camino': enCamino,
      'recargo_nocturno_aplicado': recargoNocturnoAplicado,
    };
  }

  /// Retorna un texto legible de la zona
  String get zonaTexto => zonaNombre ?? zonaDestino ?? 'Zona no especificada';

  /// Indica si la zona es rural (más costosa)
  bool get esZonaRural => zonaDestino == 'rural';

  /// Indica si la zona es centro (más económica)
  bool get esZonaCentro => zonaDestino == 'centro';

  @override
  String toString() {
    return 'DatosEnvio(ciudad: $ciudadOrigen, zona: $zonaTexto, ${distanciaKm}km, \$$costoTotal)';
  }
}
