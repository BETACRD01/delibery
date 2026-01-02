// lib/models/dto/user/responses/payment_method_response.dart

import 'package:json_annotation/json_annotation.dart';

part 'payment_method_response.g.dart';

/// DTO para la respuesta de método de pago de usuario.
@JsonSerializable()
class PaymentMethodResponse {
  final String id;
  final String tipo;

  @JsonKey(name: 'tipo_display')
  final String tipoDisplay;

  final String alias;

  @JsonKey(name: 'comprobante_pago')
  final String? comprobantePago;

  final String? observaciones;

  @JsonKey(name: 'tiene_comprobante')
  final bool tieneComprobante;

  @JsonKey(name: 'requiere_verificacion')
  final bool requiereVerificacion;

  @JsonKey(name: 'es_predeterminado')
  final bool esPredeterminado;

  final bool activo;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const PaymentMethodResponse({
    required this.id,
    required this.tipo,
    required this.tipoDisplay,
    required this.alias,
    this.comprobantePago,
    this.observaciones,
    this.tieneComprobante = false,
    this.requiereVerificacion = false,
    this.esPredeterminado = false,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethodResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentMethodResponseToJson(this);
}
