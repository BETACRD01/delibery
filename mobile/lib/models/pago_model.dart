// lib/models/pago_model.dart

import 'datos_bancarios.dart';

/// Modelo para un pago con comprobante
class PagoConComprobante {
  final int id;
  final String referencia;
  final String? pedidoNumero;
  final String? metodoPagoNombre;
  final String monto;
  final String estado;
  final String? estadoDisplay;
  final String? transferenciaComprobante;
  final String? comprobanteUrl;
  final String? transferenciaBancoOrigen;
  final String? transferenciaNumeroOperacion;
  final int? repartidorAsignado;
  final String? repartidorNombre;
  final DatosBancariosParaPago? datosBancariosRepartidor;
  final bool comprobanteVisibleRepartidor;
  final DateTime? fechaVisualizacionRepartidor;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  PagoConComprobante({
    required this.id,
    required this.referencia,
    this.pedidoNumero,
    this.metodoPagoNombre,
    required this.monto,
    required this.estado,
    this.estadoDisplay,
    this.transferenciaComprobante,
    this.comprobanteUrl,
    this.transferenciaBancoOrigen,
    this.transferenciaNumeroOperacion,
    this.repartidorAsignado,
    this.repartidorNombre,
    this.datosBancariosRepartidor,
    this.comprobanteVisibleRepartidor = false,
    this.fechaVisualizacionRepartidor,
    required this.creadoEn,
    this.actualizadoEn,
  });

  factory PagoConComprobante.fromJson(Map<String, dynamic> json) {
    return PagoConComprobante(
      id: json['id'],
      referencia: json['referencia']?.toString() ?? '',
      pedidoNumero: json['pedido_numero']?.toString(),
      metodoPagoNombre: json['metodo_pago_nombre']?.toString(),
      monto: json['monto']?.toString() ?? '0',
      estado: json['estado']?.toString() ?? '',
      estadoDisplay: json['estado_display']?.toString(),
      transferenciaComprobante: json['transferencia_comprobante']?.toString(),
      comprobanteUrl: json['comprobante_url']?.toString(),
      transferenciaBancoOrigen: json['transferencia_banco_origen']?.toString(),
      transferenciaNumeroOperacion:
          json['transferencia_numero_operacion']?.toString(),
      repartidorAsignado: json['repartidor_asignado'],
      repartidorNombre: json['repartidor_nombre']?.toString(),
      datosBancariosRepartidor: json['datos_bancarios_repartidor'] != null
          ? DatosBancariosParaPago.fromJson(
              json['datos_bancarios_repartidor'])
          : null,
      comprobanteVisibleRepartidor:
          json['comprobante_visible_repartidor'] ?? false,
      fechaVisualizacionRepartidor:
          json['fecha_visualizacion_repartidor'] != null
              ? DateTime.tryParse(
                  json['fecha_visualizacion_repartidor'].toString())
              : null,
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.tryParse(json['actualizado_en'].toString())
          : null,
    );
  }

  /// Verifica si tiene comprobante subido
  bool get tieneComprobante =>
      transferenciaComprobante != null && transferenciaComprobante!.isNotEmpty;

  /// Verifica si el repartidor ya vio el comprobante
  bool get repartidorVioComprobante => fechaVisualizacionRepartidor != null;
}

/// Modelo para ver comprobante (vista del repartidor)
class ComprobanteRepartidor {
  final int id;
  final String referencia;
  final String? pedidoNumero;
  final String? clienteNombre;
  final String monto;
  final String estado;
  final String? estadoDisplay;
  final String? transferenciaComprobante;
  final String? comprobanteUrl;
  final String? transferenciaBancoOrigen;
  final String? transferenciaNumeroOperacion;
  final bool comprobanteVisibleRepartidor;
  final DateTime? fechaVisualizacionRepartidor;
  final DateTime creadoEn;

  ComprobanteRepartidor({
    required this.id,
    required this.referencia,
    this.pedidoNumero,
    this.clienteNombre,
    required this.monto,
    required this.estado,
    this.estadoDisplay,
    this.transferenciaComprobante,
    this.comprobanteUrl,
    this.transferenciaBancoOrigen,
    this.transferenciaNumeroOperacion,
    this.comprobanteVisibleRepartidor = false,
    this.fechaVisualizacionRepartidor,
    required this.creadoEn,
  });

  factory ComprobanteRepartidor.fromJson(Map<String, dynamic> json) {
    return ComprobanteRepartidor(
      id: json['id'],
      referencia: json['referencia']?.toString() ?? '',
      pedidoNumero: json['pedido_numero']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString(),
      monto: json['monto']?.toString() ?? '0',
      estado: json['estado']?.toString() ?? '',
      estadoDisplay: json['estado_display']?.toString(),
      transferenciaComprobante: json['transferencia_comprobante']?.toString(),
      comprobanteUrl: json['comprobante_url']?.toString(),
      transferenciaBancoOrigen: json['transferencia_banco_origen']?.toString(),
      transferenciaNumeroOperacion:
          json['transferencia_numero_operacion']?.toString(),
      comprobanteVisibleRepartidor:
          json['comprobante_visible_repartidor'] ?? false,
      fechaVisualizacionRepartidor:
          json['fecha_visualizacion_repartidor'] != null
              ? DateTime.tryParse(
                  json['fecha_visualizacion_repartidor'].toString())
              : null,
      creadoEn: DateTime.tryParse(json['creado_en']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Verifica si tiene comprobante para mostrar
  bool get tieneComprobante =>
      comprobanteUrl != null && comprobanteUrl!.isNotEmpty;
}
