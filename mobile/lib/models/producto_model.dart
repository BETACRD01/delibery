// lib/models/producto_model.dart

import '../config/api_config.dart';

class ProductoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final double? precioAnterior; // Precio antes del descuento
  final bool enOferta; // Si el producto está en oferta
  final int porcentajeDescuento; // Porcentaje de descuento calculado
  final double rating;
  final int totalResenas;
  final String? imagenUrl;
  final String categoriaId;
  final String? categoriaNombre;
  final bool disponible;
  final bool destacado;
  final String? proveedorId;
  final String? proveedorNombre;
  final String? proveedorLogoUrl;
  final double? proveedorLatitud;
  final double? proveedorLongitud;
  final int? tiempoEntregaMin; // minutos
  final int? tiempoEntregaMax; // minutos
  // Stock/control (solo panel proveedor)
  final bool? tieneStock;
  final int? stock;

  // Métricas para proveedor
  final int ventasTotales;
  final double conversionRate;
  final double ingresosEstimados;
  final Map<int, int> ratingBreakdown;
  final List<ResenaPreview> resenasPreview;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.precioAnterior,
    this.enOferta = false,
    this.porcentajeDescuento = 0,
    this.rating = 0.0,
    this.totalResenas = 0,
    this.imagenUrl,
    required this.categoriaId,
    this.categoriaNombre,
    this.disponible = true,
    this.destacado = false,
    this.proveedorId,
    this.proveedorNombre,
    this.proveedorLogoUrl,
    this.proveedorLatitud,
    this.proveedorLongitud,
    this.tiempoEntregaMin,
    this.tiempoEntregaMax,
    this.tieneStock,
    this.stock,
    this.ventasTotales = 0,
    this.conversionRate = 0.0,
    this.ingresosEstimados = 0.0,
    this.ratingBreakdown = const {},
    this.resenasPreview = const [],
  });

  /// Factory para crear desde JSON (backend)
  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    final rawImagen =
        json['imagen_url'] ??
        json['imagen'] ??
        json['foto'] ??
        json['foto_url'];
    final proveedor = json['proveedor'] as Map<String, dynamic>?;
    final rawProveedorLogo =
        json['proveedor_logo'] ??
        json['proveedor_logo_url'] ??
        json['proveedor_logo_full'] ??
        json['logo_proveedor'] ??
        json['logo_proveedor_url'] ??
        json['proveedor_foto'] ??
        json['proveedor_foto_url'] ??
        proveedor?['logo'] ??
        proveedor?['logo_url'] ??
        proveedor?['logo_completo'] ??
        proveedor?['logo_full'] ??
        proveedor?['foto'] ??
        proveedor?['foto_url'] ??
        proveedor?['foto_perfil'];

    // Procesa rating breakdown
    Map<int, int> breakdown = {};
    if (json['rating_breakdown'] != null) {
      if (json['rating_breakdown'] is Map) {
        (json['rating_breakdown'] as Map).forEach((k, v) {
          breakdown[int.tryParse(k.toString()) ?? 0] =
              int.tryParse(v.toString()) ?? 0;
        });
      }
    }

    // Procesa reseñas
    List<ResenaPreview> resenas = [];
    if (json['resenas_preview'] != null && json['resenas_preview'] is List) {
      resenas = (json['resenas_preview'] as List)
          .map((e) => ResenaPreview.fromJson(e))
          .toList();
    }

    return ProductoModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: _parseDouble(json['precio']),
      precioAnterior: json['precio_anterior'] != null
          ? _parseDouble(json['precio_anterior'])
          : null,
      enOferta: json['en_oferta'] ?? false,
      porcentajeDescuento: json['porcentaje_descuento'] ?? 0,
      rating: _parseDouble(json['rating_promedio']),
      totalResenas: json['total_resenas'] ?? 0,
      imagenUrl: _normalizarImagen(rawImagen),
      categoriaId: json['categoria_id']?.toString() ?? '',
      categoriaNombre: json['categoria_nombre'] as String?,
      disponible: json['disponible'] ?? true,
      destacado: json['destacado'] ?? false,
      proveedorId: json['proveedor_id']?.toString(),
      proveedorNombre:
          json['proveedor_nombre'] as String? ??
          proveedor?['nombre'] as String?,
      proveedorLogoUrl: _normalizarImagen(rawProveedorLogo),
      proveedorLatitud: _parseDouble(
        json['proveedor_latitud'] ?? proveedor?['latitud'],
      ),
      proveedorLongitud: _parseDouble(
        json['proveedor_longitud'] ?? proveedor?['longitud'],
      ),
      tiempoEntregaMin: _parseInt(
        json['tiempo_entrega_min'] ??
            json['tiempo_min'] ??
            json['tiempo_estimado_min'],
      ),
      tiempoEntregaMax: _parseInt(
        json['tiempo_entrega_max'] ??
            json['tiempo_max'] ??
            json['tiempo_estimado_max'],
      ),
      tieneStock: json['tiene_stock'],
      stock: _parseInt(json['stock']),
      ventasTotales: _parseInt(json['ventas_totales']) ?? 0,
      conversionRate: _parseDouble(json['conversion_rate']),
      ingresosEstimados: _parseDouble(json['ingresos_estimados']),
      ratingBreakdown: breakdown,
      resenasPreview: resenas,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'precio_anterior': precioAnterior,
      'en_oferta': enOferta,
      'porcentaje_descuento': porcentajeDescuento,
      'rating_promedio': rating,
      'total_resenas': totalResenas,
      'imagen_url': imagenUrl,
      'categoria_id': categoriaId,
      'categoria_nombre': categoriaNombre,
      'disponible': disponible,
      'destacado': destacado,
      'proveedor_id': proveedorId,
      'proveedor_nombre': proveedorNombre,
      'proveedor_logo_url': proveedorLogoUrl,
      'proveedor_latitud': proveedorLatitud,
      'proveedor_longitud': proveedorLongitud,
      'tiempo_entrega_min': tiempoEntregaMin,
      'tiempo_entrega_max': tiempoEntregaMax,
      'tiene_stock': tieneStock,
      'stock': stock,
    };
  }

  /// Obtiene el precio formateado
  String get precioFormateado => '\$${precio.toStringAsFixed(2)}';

  /// Obtiene el precio anterior formateado
  String get precioAnteriorFormateado =>
      precioAnterior != null ? '\$${precioAnterior!.toStringAsFixed(2)}' : '';

  /// Obtiene el rating formateado
  String get ratingFormateado => rating.toStringAsFixed(1);

  /// Verifica si tiene buena calificación (>= 4.0)
  bool get tieneBuenaCalificacion => rating >= 4.0;

  /// Texto del sticker de descuento (ej: "20% OFF")
  String get textoDescuento =>
      enOferta && porcentajeDescuento > 0 ? '$porcentajeDescuento% OFF' : '';

  /// Calcula el ahorro en precio
  double get montoAhorro =>
      (precioAnterior != null && enOferta) ? precioAnterior! - precio : 0.0;

  String get ahorroFormateado => '\$${montoAhorro.toStringAsFixed(2)}';

  /// Rango aproximado de entrega para mostrar en tarjetas
  String tiempoEntregaFormateado({String defaultRango = '30-40 min'}) {
    final min = tiempoEntregaMin;
    final max = tiempoEntregaMax;

    if (min != null && max != null && min > 0 && max >= min) {
      return '$min-$max min';
    }

    if (min != null && min > 0) {
      final maxCalculado = min + 10;
      return '$min-$maxCalculado min';
    }

    return defaultRango;
  }

  String get tiempoEntregaAproximado =>
      'Entrega aprox. ${tiempoEntregaFormateado()}';

  // ════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ════════════════════════════════════════════════════════════════

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String? _normalizarImagen(dynamic raw) {
    if (raw == null) return null;
    final url = raw.toString();
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return url;

    // Si es una ruta relativa, la unimos con el baseUrl del API.
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  /// Crea una copia con campos modificados
  ProductoModel copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precio,
    double? precioAnterior,
    bool? enOferta,
    int? porcentajeDescuento,
    double? rating,
    int? totalResenas,
    String? imagenUrl,
    String? categoriaId,
    String? categoriaNombre,
    bool? disponible,
    bool? destacado,
    String? proveedorId,
    String? proveedorNombre,
    String? proveedorLogoUrl,
    double? proveedorLatitud,
    double? proveedorLongitud,
    int? tiempoEntregaMin,
    int? tiempoEntregaMax,
    bool? tieneStock,
    int? stock,
    int? ventasTotales,
    double? conversionRate,
    double? ingresosEstimados,
    Map<int, int>? ratingBreakdown,
    List<ResenaPreview>? resenasPreview,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      precioAnterior: precioAnterior ?? this.precioAnterior,
      enOferta: enOferta ?? this.enOferta,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
      rating: rating ?? this.rating,
      totalResenas: totalResenas ?? this.totalResenas,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      disponible: disponible ?? this.disponible,
      destacado: destacado ?? this.destacado,
      proveedorId: proveedorId ?? this.proveedorId,
      proveedorNombre: proveedorNombre ?? this.proveedorNombre,
      proveedorLogoUrl: proveedorLogoUrl ?? this.proveedorLogoUrl,
      proveedorLatitud: proveedorLatitud ?? this.proveedorLatitud,
      proveedorLongitud: proveedorLongitud ?? this.proveedorLongitud,
      tiempoEntregaMin: tiempoEntregaMin ?? this.tiempoEntregaMin,
      tiempoEntregaMax: tiempoEntregaMax ?? this.tiempoEntregaMax,
      tieneStock: tieneStock ?? this.tieneStock,
      stock: stock ?? this.stock,
      ventasTotales: ventasTotales ?? this.ventasTotales,
      conversionRate: conversionRate ?? this.conversionRate,
      ingresosEstimados: ingresosEstimados ?? this.ingresosEstimados,
      ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      resenasPreview: resenasPreview ?? this.resenasPreview,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ResenaPreview {
  final int id;
  final String usuario;
  final String? usuarioFoto;
  final int estrellas;
  final String? comentario;
  final String fecha;

  ResenaPreview({
    required this.id,
    required this.usuario,
    this.usuarioFoto,
    required this.estrellas,
    this.comentario,
    required this.fecha,
  });

  factory ResenaPreview.fromJson(Map<String, dynamic> json) {
    return ResenaPreview(
      id: int.tryParse(json['id'].toString()) ?? 0,
      usuario: json['usuario'] ?? json['usuario_nombre'] ?? 'Anónimo',
      usuarioFoto: json['usuario_foto'] ?? json['foto'],
      estrellas: int.tryParse(json['estrellas'].toString()) ?? 0,
      comentario: json['comentario'],
      fecha: json['fecha'] ?? '',
    );
  }
}
