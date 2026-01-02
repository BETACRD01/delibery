// lib/models/categoria_super_model.dart

import 'package:flutter/material.dart';

/// Modelo para las categorías del Super
class CategoriaSuperModel {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final String? imagenUrl;
  final String? logoUrl;
  final bool activo;
  final int orden;
  final bool destacado;
  final int? totalProveedores;

  const CategoriaSuperModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    this.imagenUrl,
    this.logoUrl,
    this.activo = true,
    this.orden = 0,
    this.destacado = false,
    this.totalProveedores,
  });

  // Categorías predefinidas
  static const List<CategoriaSuperModel> categoriasPredefinidas = [
    CategoriaSuperModel(
      id: 'supermercados',
      nombre: 'Supermercados',
      descripcion: 'Productos frescos y de calidad',
      icono: Icons.shopping_cart,
      color: Color(0xFF4CAF50),
      imagenUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800',
    ),
    CategoriaSuperModel(
      id: 'farmacias',
      nombre: 'Farmacias',
      descripcion: 'Tu salud es nuestra prioridad',
      icono: Icons.local_pharmacy,
      color: Color(0xFF2196F3),
      imagenUrl: 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=800',
    ),
    CategoriaSuperModel(
      id: 'bebidas',
      nombre: 'Bebidas',
      descripcion: 'Refresca tu día',
      icono: Icons.local_bar,
      color: Color(0xFFFF9800),
      imagenUrl: 'https://images.unsplash.com/photo-1437418747212-8d9709afab22?w=800',
    ),
    CategoriaSuperModel(
      id: 'mensajeria',
      nombre: 'Mensajería',
      descripcion: 'Envíos rápidos y seguros',
      icono: Icons.local_shipping,
      color: Color(0xFF9C27B0),
      imagenUrl: 'https://images.unsplash.com/photo-1566576721346-d4a3b4eaeb55?w=800',
      destacado: true,
    ),
    CategoriaSuperModel(
      id: 'tiendas',
      nombre: 'Tiendas',
      descripcion: 'Lo mejor de tu barrio',
      icono: Icons.store,
      color: Color(0xFFF44336),
      imagenUrl: 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800',
    ),
  ];

  // Factory para crear desde JSON (si es necesario para backend)
  factory CategoriaSuperModel.fromJson(Map<String, dynamic> json) {
    return CategoriaSuperModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      icono: _iconFromString(json['icono']),
      color: _colorFromJson(json['color']),
      imagenUrl: json['imagen_url'] ?? json['imagenUrl'],
      logoUrl: json['logo_url'] ?? json['logoUrl'],
      activo: json['activo'] ?? true,
      orden: json['orden'] ?? 0,
      destacado: json['destacado'] ?? false,
      totalProveedores: json['total_proveedores'] ?? json['totalProveedores'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono.codePoint,
      'color': color.toARGB32(),
      'imagen_url': imagenUrl,
      'logo_url': logoUrl,
      'activo': activo,
      'orden': orden,
      'destacado': destacado,
      'total_proveedores': totalProveedores,
    };
  }

  static Color _colorFromJson(dynamic colorData) {
    if (colorData is int) {
      return Color(colorData);
    } else if (colorData is String) {
      // Soporta formato hexadecimal (#RRGGBB o #AARRGGBB)
      final hex = colorData.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return const Color(0xFF4FC3F7); // Color por defecto
  }

  static IconData _iconFromString(dynamic iconData) {
    if (iconData is int) {
      return IconData(iconData, fontFamily: 'MaterialIcons');
    }
    return Icons.store;
  }
}
