// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressResponse _$AddressResponseFromJson(Map<String, dynamic> json) =>
    AddressResponse(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      tipoDisplay: json['tipo_display'] as String,
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
      activa: json['activa'] as bool? ?? true,
      vecesUsada: (json['veces_usada'] as num?)?.toInt() ?? 0,
      ultimoUso: json['ultimo_uso'] as String?,
      direccionCompleta: json['direccion_completa'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$AddressResponseToJson(AddressResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': instance.tipo,
      'tipo_display': instance.tipoDisplay,
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
      'activa': instance.activa,
      'veces_usada': instance.vecesUsada,
      'ultimo_uso': instance.ultimoUso,
      'direccion_completa': instance.direccionCompleta,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
