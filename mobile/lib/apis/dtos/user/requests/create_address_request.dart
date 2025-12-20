// lib/apis/dtos/user/requests/create_address_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'create_address_request.g.dart';

/// DTO para la solicitud de creación de dirección.
@JsonSerializable()
class CreateAddressRequest {
  final String tipo;
  final String etiqueta;
  final String direccion;
  final String? referencia;

  @JsonKey(name: 'piso_apartamento')
  final String? pisoApartamento;

  @JsonKey(name: 'calle_secundaria')
  final String? calleSecundaria;

  final double latitud;
  final double longitud;
  final String? ciudad;

  @JsonKey(name: 'telefono_contacto')
  final String? telefonoContacto;

  final String? indicaciones;

  @JsonKey(name: 'es_predeterminada')
  final bool esPredeterminada;

  const CreateAddressRequest({
    required this.tipo,
    required this.etiqueta,
    required this.direccion,
    this.referencia,
    this.pisoApartamento,
    this.calleSecundaria,
    required this.latitud,
    required this.longitud,
    this.ciudad,
    this.telefonoContacto,
    this.indicaciones,
    this.esPredeterminada = false,
  });

  factory CreateAddressRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAddressRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateAddressRequestToJson(this);
}
