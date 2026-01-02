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

  // Nuevos campos de tipo de promoción
  final String tipoPromocion; // 'porcentaje', '2x1', 'precio_fijo', etc.
  final String? tipoPromocionDisplay; // 'Descuento Porcentual', '2x1', etc.
  final double? valorDescuento; // Valor numérico del descuento

  // Campos de navegación
  final List<String> productosAsociadosIds; // Lista de IDs de productos
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
    this.tipoPromocion = 'porcentaje',
    this.tipoPromocionDisplay,
    this.valorDescuento,
    this.productosAsociadosIds = const [], // Lista vacía por defecto
    this.categoriaAsociadaId,
    this.fechaInicio,
    this.fechaFin,
    this.activa = true,
    this.esVigente = true,
    this.diasRestantes,
  });

  /// Factory para crear desde JSON (backend)
  factory PromocionModel.fromJson(Map<String, dynamic> json) {
    // Parsear lista de IDs de productos asociados
    List<String> productosIds = [];
    if (json['productos_asociados'] != null) {
      if (json['productos_asociados'] is List) {
        productosIds = (json['productos_asociados'] as List)
            .map((id) => id.toString())
            .toList();
      }
    }

    return PromocionModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      descuento: json['descuento'] ?? '',
      color: _colorFromString(json['color']),
      imagenUrl: json['imagen_url'] as String?,
      proveedorId: json['proveedor_id']?.toString(),
      proveedorNombre: json['proveedor_nombre'] as String?,
      tipoPromocion: json['tipo_promocion'] ?? 'porcentaje',
      tipoPromocionDisplay: json['tipo_promocion_display'] as String?,
      valorDescuento: json['valor_descuento'] != null
          ? double.tryParse(json['valor_descuento'].toString())
          : null,
      productosAsociadosIds: productosIds,
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
      'productos_asociados': productosAsociadosIds,
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
    if (productosAsociadosIds.isNotEmpty) return 'producto';
    if (categoriaAsociadaId != null) return 'categoria';
    return 'ninguno';
  }

  /// Verifica si tiene navegación configurada
  bool get tieneNavegacion => tipoNavegacion != 'ninguno';

  /// Cantidad de productos asociados
  int get cantidadProductos => productosAsociadosIds.length;

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

  /// Obtiene un icono representativo según el tipo de promoción
  IconData get iconoTipo {
    switch (tipoPromocion) {
      case 'porcentaje':
        return Icons.percent;
      case '2x1':
      case '3x2':
        return Icons.local_offer;
      case 'precio_fijo':
        return Icons.attach_money;
      case 'combo':
        return Icons.category;
      case 'envio_gratis':
        return Icons.local_shipping;
      default:
        return Icons.star;
    }
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
    String? tipoPromocion,
    String? tipoPromocionDisplay,
    double? valorDescuento,
    List<String>? productosAsociadosIds,
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
      tipoPromocion: tipoPromocion ?? this.tipoPromocion,
      tipoPromocionDisplay: tipoPromocionDisplay ?? this.tipoPromocionDisplay,
      valorDescuento: valorDescuento ?? this.valorDescuento,
      productosAsociadosIds: productosAsociadosIds ?? this.productosAsociadosIds,
      categoriaAsociadaId: categoriaAsociadaId ?? this.categoriaAsociadaId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      activa: activa ?? this.activa,
      esVigente: esVigente ?? this.esVigente,
      diasRestantes: diasRestantes ?? this.diasRestantes,
    );
  }
}
