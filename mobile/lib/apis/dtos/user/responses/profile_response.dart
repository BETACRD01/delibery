// lib/apis/dtos/user/responses/profile_response.dart

import 'package:json_annotation/json_annotation.dart';

part 'profile_response.g.dart';

/// DTO para la respuesta del perfil de usuario.
@JsonSerializable()
class ProfileResponse {
  final int id;
  final String username;
  final String email;
  final String? nombre;
  final String? apellido;
  final String? telefono;

  @JsonKey(name: 'foto_perfil')
  final String? fotoPerfil;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'rol_activo')
  final String? rolActivo;

  const ProfileResponse({
    required this.id,
    required this.username,
    required this.email,
    this.nombre,
    this.apellido,
    this.telefono,
    this.fotoPerfil,
    required this.createdAt,
    this.isActive = true,
    this.rolActivo,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}
