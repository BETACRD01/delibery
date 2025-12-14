// lib/models/entrega_historial.dart

/// Modelo para representar una entrega completada en el historial del repartidor
class EntregaHistorial {
  final int id;
  final String fechaEntregado;
  final double comisionRepartidor;
  final String clienteNombre;
  final String clienteDireccion;
  final String? clienteTelefono;
  final String? urlComprobante;
  final double montoTotal;
  final String metodoPago;

  EntregaHistorial({
    required this.id,
    required this.fechaEntregado,
    required this.comisionRepartidor,
    required this.clienteNombre,
    required this.clienteDireccion,
    this.clienteTelefono,
    this.urlComprobante,
    required this.montoTotal,
    required this.metodoPago,
  });

  factory EntregaHistorial.fromJson(Map<String, dynamic> json) {
    return EntregaHistorial(
      id: json['id'] ?? 0,
      fechaEntregado: json['fecha_entregado'] ?? '',
      comisionRepartidor: _parseDouble(json['comision_repartidor']),
      clienteNombre: json['cliente_nombre'] ?? 'Cliente desconocido',
      clienteDireccion: json['cliente_direccion'] ?? 'Dirección no disponible',
      clienteTelefono: json['cliente_telefono'],
      urlComprobante: json['url_comprobante'],
      montoTotal: _parseDouble(json['monto_total']),
      metodoPago: json['metodo_pago'] ?? 'efectivo',
    );
  }

  /// Helper para parsear números que pueden venir como String o int/double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha_entregado': fechaEntregado,
      'comision_repartidor': comisionRepartidor,
      'cliente_nombre': clienteNombre,
      'cliente_direccion': clienteDireccion,
      'cliente_telefono': clienteTelefono,
      'url_comprobante': urlComprobante,
      'monto_total': montoTotal,
      'metodo_pago': metodoPago,
    };
  }

  /// Retorna la fecha de entrega formateada de manera legible
  String get fechaFormateada {
    try {
      final fecha = DateTime.parse(fechaEntregado);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaEntregado;
    }
  }

  /// Indica si la entrega tiene comprobante adjunto
  bool get tieneComprobante => urlComprobante != null && urlComprobante!.isNotEmpty;
}

/// Respuesta del endpoint de historial de entregas
class HistorialEntregasResponse {
  final List<EntregaHistorial> entregas;
  final int totalEntregas;
  final double totalComisiones;
  final int count;
  final String? next;
  final String? previous;

  HistorialEntregasResponse({
    required this.entregas,
    required this.totalEntregas,
    required this.totalComisiones,
    required this.count,
    this.next,
    this.previous,
  });

  factory HistorialEntregasResponse.fromJson(Map<String, dynamic> json) {
    return HistorialEntregasResponse(
      entregas: (json['results'] as List<dynamic>?)
              ?.map((e) => EntregaHistorial.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalEntregas: json['total_entregas'] ?? 0,
      totalComisiones: EntregaHistorial._parseDouble(json['total_comisiones']),
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
    );
  }
}
