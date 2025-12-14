// lib/models/categoria_model.dart

import 'package:flutter/material.dart'; 

class CategoriaModel {
  final String id;
  final String nombre;
  final String? imagenUrl;
  final int? totalProductos;
  
  // Campos visuales
  final IconData? icono;
  final Color? color;

  const CategoriaModel({
    required this.id,
    required this.nombre,
    this.imagenUrl,
    this.totalProductos,
    this.icono,
    this.color,
  });

  /// Factory INTELIGENTE que lee lo que manda el Backend (visual_services.py)
  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    // 1. Extraemos el bloque de configuración visual
    final uiData = json['ui_data'] as Map<String, dynamic>?;
    
    String? urlDetectada;
    IconData? iconoDetectado;
    Color? colorDetectado;

    // 2. Si el backend envió instrucciones visuales...
    if (uiData != null) {
      final tipo = uiData['tipo'];
      final contenido = uiData['contenido'];
      final hexColor = uiData['color_hex'];

      if (tipo == 'IMAGEN') {
        // El backend dice que hay foto
        urlDetectada = contenido; 
      } else if (tipo == 'ICONO') {
        // El backend dice qué icono usar (Ej: "local_pizza")
        iconoDetectado = _mapIcono(contenido);
      }

      // El backend dice qué color usar
      if (hexColor != null) {
        colorDetectado = _parseColor(hexColor);
      }
    } else {
      // Soporte Legacy: Si el backend no mandó ui_data, buscamos donde siempre
      urlDetectada = json['imagen_url'];
    }

    return CategoriaModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      totalProductos: json['total_productos'] as int?,
      imagenUrl: urlDetectada,
      icono: iconoDetectado,
      color: colorDetectado,
    );
  }

  /// Verifica si tiene imagen
  bool get tieneImagen => imagenUrl != null && imagenUrl!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // HERRAMIENTAS DE TRADUCCIÓN (Texto del Backend -> Objetos de Flutter)
  // ---------------------------------------------------------------------------

  /// Convierte el texto "local_pizza" en el icono real Icons.local_pizza
  static IconData _mapIcono(String? nombreIcono) {
    switch (nombreIcono) {
      case 'fastfood': return Icons.fastfood;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'local_pizza': return Icons.local_pizza;
      case 'local_drink': return Icons.local_drink;
      case 'cake': return Icons.cake;
      case 'icecream': return Icons.icecream;
      case 'medical_services': return Icons.medical_services;
      case 'liquor': return Icons.liquor;
      case 'local_cafe': return Icons.local_cafe;
      case 'breakfast_dining': return Icons.breakfast_dining;
      case 'category': 
      default: return Icons.category_outlined; // Fallback
    }
  }

  /// Convierte el texto "#FF5722" en un Color real
  static Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue; // Color por defecto si falla
    }
  }
}