// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_payment_method_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePaymentMethodRequest _$UpdatePaymentMethodRequestFromJson(
  Map<String, dynamic> json,
) => UpdatePaymentMethodRequest(
  tipo: json['tipo'] as String?,
  alias: json['alias'] as String?,
  observaciones: json['observaciones'] as String?,
  esPredeterminado: json['es_predeterminado'] as bool?,
);

Map<String, dynamic> _$UpdatePaymentMethodRequestToJson(
  UpdatePaymentMethodRequest instance,
) => <String, dynamic>{
  'tipo': ?instance.tipo,
  'alias': ?instance.alias,
  'observaciones': ?instance.observaciones,
  'es_predeterminado': ?instance.esPredeterminado,
};
