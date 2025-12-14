// lib/models/promocion_model.dart

import 'package:flutter/material.dart';

/// Modelo de promoción/banner especial con navegación
class PromocionModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String descuento; // Ej: "20% OFF", "Exclusivo"
  final Color color;
  final String? imagenUrl;
  final String? proveedorId;
  final String? proveedorNombre;
  
  // Campos de navegación
  final String? productoAsociadoId;
  final String? categoriaAsociadaId;
  
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activa;
  final bool esVigente;
  final int? diasRestantes;

  PromocionModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.descuento,
    required this.color,
    this.imagenUrl,
    this.proveedorId,
    this.proveedorNombre,
    this.productoAsociadoId,
    this.categoriaAsociadaId,
    this.fechaInicio,
    this.fechaFin,
    this.activa = true,
    this.esVigente = true,
    this.diasRestantes,
  });

  /// Factory para crear desde JSON (backend)
  factory PromocionModel.fromJson(Map<String, dynamic> json) {
    return PromocionModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      descuento: json['descuento'] ?? '',
      color: _colorFromString(json['color']),
      imagenUrl: json['imagen_url'] as String?,
      proveedorId: json['proveedor_id']?.toString(),
      proveedorNombre: json['proveedor_nombre'] as String?,
      productoAsociadoId: json['producto_asociado']?.toString(),
      categoriaAsociadaId: json['categoria_asociada']?.toString(),
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : null,
      fechaFin: json['fecha_fin'] != null 
          ? DateTime.parse(json['fecha_fin']) 
          : null,
      activa: json['activa'] ?? true,
      esVigente: json['es_vigente'] ?? true,
      diasRestantes: json['dias_restantes'] as int?,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'descuento': descuento,
      'color': _colorToString(color),
      'imagen_url': imagenUrl,
      'proveedor_id': proveedorId,
      'proveedor_nombre': proveedorNombre,
      'producto_asociado': productoAsociadoId,
      'categoria_asociada': categoriaAsociadaId,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'activa': activa,
      'es_vigente': esVigente,
      'dias_restantes': diasRestantes,
    };
  }

  /// Determina el tipo de navegación que tiene el banner
  String get tipoNavegacion {
    if (productoAsociadoId != null) return 'producto';
    if (categoriaAsociadaId != null) return 'categoria';
    return 'ninguno';
  }

  /// Verifica si tiene navegación configurada
  bool get tieneNavegacion => tipoNavegacion != 'ninguno';

  /// Texto de días restantes formateado
  String get textoTiempoRestante {
    if (diasRestantes == null) return '';
    if (diasRestantes! <= 0) return 'Expira hoy';
    if (diasRestantes == 1) return 'Expira mañana';
    return 'Expira en $diasRestantes días';
  }

  // ════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ════════════════════════════════════════════════════════════════

  static Color _colorFromString(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return const Color(0xFFE91E63); // Color por defecto (rosa)
    }
    
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFFE91E63);
    }
  }

  static String _colorToString(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}'; 
  }

  /// Crea una copia con campos modificados
  PromocionModel copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? descuento,
    Color? color,
    String? imagenUrl,
    String? proveedorId,
    String? proveedorNombre,
    String? productoAsociadoId,
    String? categoriaAsociadaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activa,
    bool? esVigente,
    int? diasRestantes,
  }) {
    return PromocionModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      descuento: descuento ?? this.descuento,
      color: color ?? this.color,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      proveedorId: proveedorId ?? this.proveedorId,
      proveedorNombre: proveedorNombre ?? this.proveedorNombre,
      productoAsociadoId: productoAsociadoId ?? this.productoAsociadoId,
      categoriaAsociadaId: categoriaAsociadaId ?? this.categoriaAsociadaId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      activa: activa ?? this.activa,
      esVigente: esVigente ?? this.esVigente,
      diasRestantes: diasRestantes ?? this.diasRestantes,
    );
  }
}
