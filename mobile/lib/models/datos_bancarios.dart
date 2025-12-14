// lib/models/datos_bancarios.dart

/// Modelo para los datos bancarios del repartidor
class DatosBancarios {
  final String? bancoNombre;
  final String? bancoTipoCuenta;
  final String? tipoCuentaDisplay;
  final String? bancoNumeroCuenta;
  final String? bancoTitular;
  final String? bancoCedulaTitular;
  final bool bancoVerificado;
  final DateTime? bancoFechaVerificacion;

  DatosBancarios({
    this.bancoNombre,
    this.bancoTipoCuenta,
    this.tipoCuentaDisplay,
    this.bancoNumeroCuenta,
    this.bancoTitular,
    this.bancoCedulaTitular,
    this.bancoVerificado = false,
    this.bancoFechaVerificacion,
  });

  factory DatosBancarios.fromJson(Map<String, dynamic> json) {
    return DatosBancarios(
      bancoNombre: json['banco_nombre']?.toString(),
      bancoTipoCuenta: json['banco_tipo_cuenta']?.toString(),
      tipoCuentaDisplay: json['tipo_cuenta_display']?.toString(),
      bancoNumeroCuenta: json['banco_numero_cuenta']?.toString(),
      bancoTitular: json['banco_titular']?.toString(),
      bancoCedulaTitular: json['banco_cedula_titular']?.toString(),
      bancoVerificado: json['banco_verificado'] ?? false,
      bancoFechaVerificacion: json['banco_fecha_verificacion'] != null
          ? DateTime.tryParse(json['banco_fecha_verificacion'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'banco_nombre': bancoNombre,
      'banco_tipo_cuenta': bancoTipoCuenta,
      'banco_numero_cuenta': bancoNumeroCuenta,
      'banco_titular': bancoTitular,
      'banco_cedula_titular': bancoCedulaTitular,
    };
  }

  /// Verifica si los datos bancarios están completos
  bool get estanCompletos {
    return bancoNombre != null &&
        bancoNombre!.isNotEmpty &&
        bancoTipoCuenta != null &&
        bancoTipoCuenta!.isNotEmpty &&
        bancoNumeroCuenta != null &&
        bancoNumeroCuenta!.isNotEmpty &&
        bancoTitular != null &&
        bancoTitular!.isNotEmpty &&
        bancoCedulaTitular != null &&
        bancoCedulaTitular!.isNotEmpty;
  }

  /// Crea una copia con campos actualizados
  DatosBancarios copyWith({
    String? bancoNombre,
    String? bancoTipoCuenta,
    String? tipoCuentaDisplay,
    String? bancoNumeroCuenta,
    String? bancoTitular,
    String? bancoCedulaTitular,
    bool? bancoVerificado,
    DateTime? bancoFechaVerificacion,
  }) {
    return DatosBancarios(
      bancoNombre: bancoNombre ?? this.bancoNombre,
      bancoTipoCuenta: bancoTipoCuenta ?? this.bancoTipoCuenta,
      tipoCuentaDisplay: tipoCuentaDisplay ?? this.tipoCuentaDisplay,
      bancoNumeroCuenta: bancoNumeroCuenta ?? this.bancoNumeroCuenta,
      bancoTitular: bancoTitular ?? this.bancoTitular,
      bancoCedulaTitular: bancoCedulaTitular ?? this.bancoCedulaTitular,
      bancoVerificado: bancoVerificado ?? this.bancoVerificado,
      bancoFechaVerificacion:
          bancoFechaVerificacion ?? this.bancoFechaVerificacion,
    );
  }
}

/// Datos bancarios para transferencia al repartidor (vista del cliente)
class DatosBancariosParaPago {
  final String banco;
  final String tipoCuenta;
  final String tipoCuentaDisplay;
  final String numeroCuenta;
  final String titular;
  final String cedulaTitular;
  final bool verificado;
  final String montoATransferir;
  final String referenciaPago;

  DatosBancariosParaPago({
    required this.banco,
    required this.tipoCuenta,
    required this.tipoCuentaDisplay,
    required this.numeroCuenta,
    required this.titular,
    required this.cedulaTitular,
    required this.verificado,
    required this.montoATransferir,
    required this.referenciaPago,
  });

  factory DatosBancariosParaPago.fromJson(Map<String, dynamic> json) {
    return DatosBancariosParaPago(
      banco: json['banco']?.toString() ?? '',
      tipoCuenta: json['tipo_cuenta']?.toString() ?? '',
      tipoCuentaDisplay: json['tipo_cuenta_display']?.toString() ?? '',
      numeroCuenta: json['numero_cuenta']?.toString() ?? '',
      titular: json['titular']?.toString() ?? '',
      cedulaTitular: json['cedula_titular']?.toString() ?? '',
      verificado: json['verificado'] ?? false,
      montoATransferir: json['monto_a_transferir']?.toString() ?? '0',
      referenciaPago: json['referencia_pago']?.toString() ?? '',
    );
  }
}
