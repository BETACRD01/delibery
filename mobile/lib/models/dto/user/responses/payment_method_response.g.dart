// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMethodResponse _$PaymentMethodResponseFromJson(
  Map<String, dynamic> json,
) => PaymentMethodResponse(
  id: json['id'] as String,
  tipo: json['tipo'] as String,
  tipoDisplay: json['tipo_display'] as String,
  alias: json['alias'] as String,
  comprobantePago: json['comprobante_pago'] as String?,
  observaciones: json['observaciones'] as String?,
  tieneComprobante: json['tiene_comprobante'] as bool? ?? false,
  requiereVerificacion: json['requiere_verificacion'] as bool? ?? false,
  esPredeterminado: json['es_predeterminado'] as bool? ?? false,
  activo: json['activo'] as bool? ?? true,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$PaymentMethodResponseToJson(
  PaymentMethodResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'tipo': instance.tipo,
  'tipo_display': instance.tipoDisplay,
  'alias': instance.alias,
  'comprobante_pago': instance.comprobantePago,
  'observaciones': instance.observaciones,
  'tiene_comprobante': instance.tieneComprobante,
  'requiere_verificacion': instance.requiereVerificacion,
  'es_predeterminado': instance.esPredeterminado,
  'activo': instance.activo,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
