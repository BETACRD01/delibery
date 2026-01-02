// lib/models/dto/user/requests/update_payment_method_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'update_payment_method_request.g.dart';

/// DTO para la solicitud de actualización de método de pago.
@JsonSerializable(includeIfNull: false)
class UpdatePaymentMethodRequest {
  final String? tipo;
  final String? alias;
  final String? observaciones;

  @JsonKey(name: 'es_predeterminado')
  final bool? esPredeterminado;

  const UpdatePaymentMethodRequest({
    this.tipo,
    this.alias,
    this.observaciones,
    this.esPredeterminado,
  });

  factory UpdatePaymentMethodRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePaymentMethodRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePaymentMethodRequestToJson(this);
}
