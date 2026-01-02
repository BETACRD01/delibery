// lib/models/resena_model.dart

/// Modelo para una reseña/calificación individual
class ResenaModel {
  final int id;
  final String entityType; // 'repartidor' | 'producto' | 'cliente' | 'proveedor'
  final int entityId;
  final String autorNombre;
  final String? autorEmail;
  final String? autorFoto;
  final double puntuacion; // 1.0 - 5.0
  final String? comentario;
  final DateTime fecha;

  ResenaModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.autorNombre,
    this.autorEmail,
    this.autorFoto,
    required this.puntuacion,
    this.comentario,
    required this.fecha,
  });

  factory ResenaModel.fromJson(Map<String, dynamic> json) {
    return ResenaModel(
      id: json['id'] as int,
      entityType: json['entity_type'] as String? ?? json['tipo_entidad'] as String,
      entityId: json['entity_id'] as int? ?? json['entidad_id'] as int,
      autorNombre: json['autor_nombre'] as String? ?? json['cliente_nombre'] as String? ?? 'Usuario',
      autorEmail: json['autor_email'] as String?,
      autorFoto: json['autor_foto'] as String?,
      puntuacion: (json['puntuacion'] as num?)?.toDouble() ??
                  (json['estrellas'] as num?)?.toDouble() ??
                  0.0,
      comentario: json['comentario'] as String?,
      fecha: DateTime.parse(json['fecha'] as String? ?? json['creado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'autor_nombre': autorNombre,
      'autor_email': autorEmail,
      'autor_foto': autorFoto,
      'puntuacion': puntuacion,
      'comentario': comentario,
      'fecha': fecha.toIso8601String(),
    };
  }

  // Helpers
  bool get esPositiva => puntuacion >= 4.0;
  bool get esNegativa => puntuacion <= 2.0;

  String get tiempoTranscurrido {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays > 365) {
      final years = (diferencia.inDays / 365).floor();
      return 'Hace $years ${years == 1 ? 'año' : 'años'}';
    } else if (diferencia.inDays > 30) {
      final months = (diferencia.inDays / 30).floor();
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} ${diferencia.inDays == 1 ? 'día' : 'días'}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} ${diferencia.inHours == 1 ? 'hora' : 'horas'}';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} ${diferencia.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace un momento';
    }
  }

  String get iniciales {
    final nombres = autorNombre.split(' ');
    if (nombres.isEmpty) return '?';
    if (nombres.length == 1) return nombres[0][0].toUpperCase();
    return '${nombres[0][0]}${nombres[1][0]}'.toUpperCase();
  }
}

/// Respuesta paginada de reseñas
class ResenaListResponse {
  final List<ResenaModel> resenas;
  final int total;
  final int pagina;
  final int totalPaginas;
  final bool tieneMas;

  ResenaListResponse({
    required this.resenas,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
    required this.tieneMas,
  });

  factory ResenaListResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? json['resenas'] as List<dynamic>? ?? [];

    return ResenaListResponse(
      resenas: results.map((r) => ResenaModel.fromJson(r as Map<String, dynamic>)).toList(),
      total: json['count'] as int? ?? json['total'] as int? ?? 0,
      pagina: json['current_page'] as int? ?? json['pagina'] as int? ?? 1,
      totalPaginas: json['total_pages'] as int? ?? json['total_paginas'] as int? ?? 1,
      tieneMas: json['next'] != null || (json['tiene_mas'] as bool? ?? false),
    );
  }
}

/// Resumen estadístico de calificaciones
class RatingSummary {
  final double promedioCalificacion;
  final int totalCalificaciones;
  final Map<int, int> desglosePorEstrellas;
  final double porcentaje5Estrellas;

  RatingSummary({
    required this.promedioCalificacion,
    required this.totalCalificaciones,
    required this.desglosePorEstrellas,
    required this.porcentaje5Estrellas,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    final desglose = <int, int>{};

    // Intentar múltiples formatos del backend
    if (json['desglose_calificaciones'] != null) {
      final data = json['desglose_calificaciones'] as Map<String, dynamic>;
      data.forEach((key, value) {
        final starKey = int.tryParse(key) ?? 0;
        desglose[starKey] = value as int;
      });
    } else {
      // Formato alternativo con campos individuales
      desglose[5] = json['calificaciones_5_estrellas'] as int? ?? 0;
      desglose[4] = json['calificaciones_4_estrellas'] as int? ?? 0;
      desglose[3] = json['calificaciones_3_estrellas'] as int? ?? 0;
      desglose[2] = json['calificaciones_2_estrellas'] as int? ?? 0;
      desglose[1] = json['calificaciones_1_estrella'] as int? ?? 0;
    }

    return RatingSummary(
      promedioCalificacion: (json['promedio_calificacion'] as num?)?.toDouble() ??
                           (json['calificacion_promedio'] as num?)?.toDouble() ??
                           0.0,
      totalCalificaciones: json['total_calificaciones'] as int? ??
                          json['total_resenas'] as int? ??
                          0,
      desglosePorEstrellas: desglose,
      porcentaje5Estrellas: (json['porcentaje_5_estrellas'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
