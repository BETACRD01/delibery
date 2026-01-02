// lib/models/dto/user/requests/update_address_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'update_address_request.g.dart';

/// DTO para la solicitud de actualización de dirección.
@JsonSerializable(includeIfNull: false)
class UpdateAddressRequest {
  final String? tipo;
  final String? etiqueta;
  final String? direccion;
  final String? referencia;

  @JsonKey(name: 'piso_apartamento')
  final String? pisoApartamento;

  @JsonKey(name: 'calle_secundaria')
  final String? calleSecundaria;

  final double? latitud;
  final double? longitud;
  final String? ciudad;

  @JsonKey(name: 'telefono_contacto')
  final String? telefonoContacto;

  final String? indicaciones;

  @JsonKey(name: 'es_predeterminada')
  final bool? esPredeterminada;

  const UpdateAddressRequest({
    this.tipo,
    this.etiqueta,
    this.direccion,
    this.referencia,
    this.pisoApartamento,
    this.calleSecundaria,
    this.latitud,
    this.longitud,
    this.ciudad,
    this.telefonoContacto,
    this.indicaciones,
    this.esPredeterminada,
  });

  factory UpdateAddressRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAddressRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateAddressRequestToJson(this);
}
