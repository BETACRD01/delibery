// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_address_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAddressRequest _$CreateAddressRequestFromJson(
  Map<String, dynamic> json,
) => CreateAddressRequest(
  tipo: json['tipo'] as String,
  etiqueta: json['etiqueta'] as String,
  direccion: json['direccion'] as String,
  referencia: json['referencia'] as String?,
  pisoApartamento: json['piso_apartamento'] as String?,
  calleSecundaria: json['calle_secundaria'] as String?,
  latitud: (json['latitud'] as num).toDouble(),
  longitud: (json['longitud'] as num).toDouble(),
  ciudad: json['ciudad'] as String?,
  telefonoContacto: json['telefono_contacto'] as String?,
  indicaciones: json['indicaciones'] as String?,
  esPredeterminada: json['es_predeterminada'] as bool? ?? false,
);

Map<String, dynamic> _$CreateAddressRequestToJson(
  CreateAddressRequest instance,
) => <String, dynamic>{
  'tipo': instance.tipo,
  'etiqueta': instance.etiqueta,
  'direccion': instance.direccion,
  'referencia': instance.referencia,
  'piso_apartamento': instance.pisoApartamento,
  'calle_secundaria': instance.calleSecundaria,
  'latitud': instance.latitud,
  'longitud': instance.longitud,
  'ciudad': instance.ciudad,
  'telefono_contacto': instance.telefonoContacto,
  'indicaciones': instance.indicaciones,
  'es_predeterminada': instance.esPredeterminada,
};
