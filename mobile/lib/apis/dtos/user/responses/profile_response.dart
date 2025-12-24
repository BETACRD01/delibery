// lib/apis/dtos/user/responses/profile_response.dart

import 'package:json_annotation/json_annotation.dart';

part 'profile_response.g.dart';

/// DTO para la respuesta del perfil de usuario.
/// Coincide con la respuesta de /api/usuarios/perfil/ y /api/auth/perfil/
@JsonSerializable()
class ProfileResponse {
  final int id;

  @JsonKey(name: 'usuario_email')
  final String? email;

  @JsonKey(name: 'usuario_nombre')
  final String? nombre;

  final String? telefono;

  @JsonKey(name: 'foto_perfil')
  final String? fotoPerfil;

  @JsonKey(name: 'fecha_nacimiento')
  final String? fechaNacimiento;

  final int? edad;

  final double? calificacion;

  @JsonKey(name: 'total_resenas')
  final int? totalResenas;

  @JsonKey(name: 'total_pedidos')
  final int? totalPedidos;

  @JsonKey(name: 'pedidos_mes_actual')
  final int? pedidosMesActual;

  @JsonKey(name: 'es_cliente_frecuente')
  final bool? esClienteFrecuente;

  @JsonKey(name: 'puede_participar_rifa')
  final bool? puedeParticiparRifa;

  @JsonKey(name: 'notificaciones_pedido')
  final bool? notificacionesPedido;

  @JsonKey(name: 'notificaciones_promociones')
  final bool? notificacionesPromociones;

  @JsonKey(name: 'fcm_token_actualizado')
  final String? fcmTokenActualizado;

  @JsonKey(name: 'total_direcciones')
  final int? totalDirecciones;

  @JsonKey(name: 'total_metodos_pago')
  final int? totalMetodosPago;

  @JsonKey(name: 'creado_en')
  final String? creadoEn;

  @JsonKey(name: 'actualizado_en')
  final String? actualizadoEn;

  const ProfileResponse({
    required this.id,
    this.email,
    this.nombre,
    this.telefono,
    this.fotoPerfil,
    this.fechaNacimiento,
    this.edad,
    this.calificacion,
    this.totalResenas,
    this.totalPedidos,
    this.pedidosMesActual,
    this.esClienteFrecuente,
    this.puedeParticiparRifa,
    this.notificacionesPedido,
    this.notificacionesPromociones,
    this.fcmTokenActualizado,
    this.totalDirecciones,
    this.totalMetodosPago,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseToJson(this);
}
