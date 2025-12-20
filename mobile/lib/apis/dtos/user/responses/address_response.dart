// lib/apis/dtos/user/responses/address_response.dart

import 'package:json_annotation/json_annotation.dart';

part 'address_response.g.dart';

/// DTO para la respuesta de dirección de usuario.
@JsonSerializable()
class AddressResponse {
  final String id;
  final String tipo;

  @JsonKey(name: 'tipo_display')
  final String tipoDisplay;

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

  final bool activa;

  @JsonKey(name: 'veces_usada')
  final int vecesUsada;

  @JsonKey(name: 'ultimo_uso')
  final String? ultimoUso;

  @JsonKey(name: 'direccion_completa')
  final String? direccionCompleta;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const AddressResponse({
    required this.id,
    required this.tipo,
    required this.tipoDisplay,
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
    this.activa = true,
    this.vecesUsada = 0,
    this.ultimoUso,
    this.direccionCompleta,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      _$AddressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddressResponseToJson(this);
}
