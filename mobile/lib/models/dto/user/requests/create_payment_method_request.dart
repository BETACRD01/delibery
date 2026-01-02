// lib/models/dto/user/requests/create_payment_method_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'create_payment_method_request.g.dart';

/// DTO para la solicitud de creación de método de pago.
@JsonSerializable()
class CreatePaymentMethodRequest {
  final String tipo;
  final String alias;
  final String? observaciones;

  @JsonKey(name: 'es_predeterminado')
  final bool esPredeterminado;

  const CreatePaymentMethodRequest({
    required this.tipo,
    required this.alias,
    this.observaciones,
    this.esPredeterminado = false,
  });

  factory CreatePaymentMethodRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentMethodRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentMethodRequestToJson(this);
}
