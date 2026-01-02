// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    ProfileResponse(
      id: (json['id'] as num).toInt(),
      email: json['usuario_email'] as String?,
      nombre: json['usuario_nombre'] as String?,
      telefono: json['telefono'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] as String?,
      edad: (json['edad'] as num?)?.toInt(),
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      totalResenas: (json['total_resenas'] as num?)?.toInt(),
      totalPedidos: (json['total_pedidos'] as num?)?.toInt(),
      pedidosMesActual: (json['pedidos_mes_actual'] as num?)?.toInt(),
      esClienteFrecuente: json['es_cliente_frecuente'] as bool?,
      puedeParticiparRifa: json['puede_participar_rifa'] as bool?,
      notificacionesPedido: json['notificaciones_pedido'] as bool?,
      notificacionesPromociones: json['notificaciones_promociones'] as bool?,
      fcmTokenActualizado: json['fcm_token_actualizado'] as String?,
      totalDirecciones: (json['total_direcciones'] as num?)?.toInt(),
      totalMetodosPago: (json['total_metodos_pago'] as num?)?.toInt(),
      creadoEn: json['creado_en'] as String?,
      actualizadoEn: json['actualizado_en'] as String?,
    );

Map<String, dynamic> _$ProfileResponseToJson(ProfileResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'usuario_email': instance.email,
      'usuario_nombre': instance.nombre,
      'telefono': instance.telefono,
      'foto_perfil': instance.fotoPerfil,
      'fecha_nacimiento': instance.fechaNacimiento,
      'edad': instance.edad,
      'calificacion': instance.calificacion,
      'total_resenas': instance.totalResenas,
      'total_pedidos': instance.totalPedidos,
      'pedidos_mes_actual': instance.pedidosMesActual,
      'es_cliente_frecuente': instance.esClienteFrecuente,
      'puede_participar_rifa': instance.puedeParticiparRifa,
      'notificaciones_pedido': instance.notificacionesPedido,
      'notificaciones_promociones': instance.notificacionesPromociones,
      'fcm_token_actualizado': instance.fcmTokenActualizado,
      'total_direcciones': instance.totalDirecciones,
      'total_metodos_pago': instance.totalMetodosPago,
      'creado_en': instance.creadoEn,
      'actualizado_en': instance.actualizadoEn,
    };
