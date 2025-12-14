// lib/models/notificacion_model.dart

import 'package:flutter/material.dart'; // ✅ AGREGADO

/// Modelo de notificación
class NotificacionModel {
  final String id;
  final String titulo;
  final String mensaje;
  final String tipo; // pedido, promocion, sistema, pago
  final DateTime fecha;
  final bool leida;
  final String? imagenUrl;
  final Map<String, dynamic>? metadata;

  NotificacionModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    this.leida = false,
    this.imagenUrl,
    this.metadata,
  });

  /// Factory para crear desde JSON
  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: json['tipo'] ?? 'sistema',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
      leida: json['leida'] ?? false,
      imagenUrl: json['imagen_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'leida': leida,
      'imagen_url': imagenUrl,
      'metadata': metadata,
    };
  }

  /// Crea una copia con campos modificados
  NotificacionModel copyWith({
    String? id,
    String? titulo,
    String? mensaje,
    String? tipo,
    DateTime? fecha,
    bool? leida,
    String? imagenUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificacionModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      leida: leida ?? this.leida,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Obtiene el icono según el tipo
  IconData get icono {
    switch (tipo) {
      case 'pedido':
        return Icons.shopping_bag;
      case 'promocion':
        return Icons.local_offer;
      case 'pago':
        return Icons.payment;
      case 'sistema':
      default:
        return Icons.notifications;
    }
  }

  /// Obtiene el color según el tipo
  Color get color {
    switch (tipo) {
      case 'pedido':
        return const Color(0xFF4FC3F7);
      case 'promocion':
        return const Color(0xFFFF6B9D);
      case 'pago':
        return const Color(0xFF66BB6A);
      case 'sistema':
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Obtiene el tiempo transcurrido en formato legible
  String get tiempoTranscurrido {
    final diferencia = DateTime.now().difference(fecha);
    
    if (diferencia.inSeconds < 60) {
      return 'Ahora';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  @override
  String toString() {
    return 'NotificacionModel(id: $id, titulo: $titulo, tipo: $tipo, leida: $leida)';
  }
}