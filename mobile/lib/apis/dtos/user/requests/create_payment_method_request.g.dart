// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_payment_method_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePaymentMethodRequest _$CreatePaymentMethodRequestFromJson(
  Map<String, dynamic> json,
) => CreatePaymentMethodRequest(
  tipo: json['tipo'] as String,
  alias: json['alias'] as String,
  observaciones: json['observaciones'] as String?,
  esPredeterminado: json['es_predeterminado'] as bool? ?? false,
);

Map<String, dynamic> _$CreatePaymentMethodRequestToJson(
  CreatePaymentMethodRequest instance,
) => <String, dynamic>{
  'tipo': instance.tipo,
  'alias': instance.alias,
  'observaciones': instance.observaciones,
  'es_predeterminado': instance.esPredeterminado,
};
