// lib/models/rifa_activa.dart

class RifaActiva {
  final String id;
  final String titulo;
  final String descripcion;
  final int pedidosMinimos;
  final int misPedidos;
  final int pedidosFaltantes;
  final bool puedoParticipar;
  final bool yaParticipa;
  final String? imagenUrl;

  RifaActiva({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.pedidosMinimos,
    required this.misPedidos,
    required this.pedidosFaltantes,
    required this.puedoParticipar,
    required this.yaParticipa,
    this.imagenUrl,
  });

  factory RifaActiva.fromJson(Map<String, dynamic> json) {
    return RifaActiva(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      pedidosMinimos: json['pedidos_minimos'] as int? ?? 3,
      misPedidos: json['mis_pedidos'] as int? ?? 0,
      pedidosFaltantes: json['pedidos_faltantes'] as int? ?? 3,
      puedoParticipar: json['puedo_participar'] as bool? ?? false,
      yaParticipa: json['ya_participa'] as bool? ?? false,
      imagenUrl: json['imagen_url'] as String?,
    );
  }

  // Propiedad para calcular el progreso de 0.0 a 1.0
  double get progreso {
    if (pedidosMinimos <= 0) return 0.0;
    return (misPedidos / pedidosMinimos).clamp(0.0, 1.0);
  }
}
