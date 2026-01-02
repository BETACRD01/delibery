// lib/models/dto/user/requests/update_profile_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

/// DTO para la solicitud de actualización de perfil.
@JsonSerializable(includeIfNull: false)
class UpdateProfileRequest {
  final String? nombre;
  final String? apellido;
  final String? telefono;

  const UpdateProfileRequest({
    this.nombre,
    this.apellido,
    this.telefono,
  });

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}
