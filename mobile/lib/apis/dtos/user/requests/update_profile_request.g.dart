// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  nombre: json['nombre'] as String?,
  apellido: json['apellido'] as String?,
  telefono: json['telefono'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'nombre': ?instance.nombre,
  'apellido': ?instance.apellido,
  'telefono': ?instance.telefono,
};
