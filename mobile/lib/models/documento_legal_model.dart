class DocumentoLegalModel {
  final String tipo;
  final String tipoDisplay;
  final String contenido;
  final String version;
  final DateTime fechaModificacion;

  DocumentoLegalModel({
    required this.tipo,
    required this.tipoDisplay,
    required this.contenido,
    required this.version,
    required this.fechaModificacion,
  });

  factory DocumentoLegalModel.fromJson(Map<String, dynamic> json) {
    return DocumentoLegalModel(
      tipo: json['tipo'] ?? '',
      tipoDisplay: json['tipo_display'] ?? '',
      contenido: json['contenido'] ?? '',
      version: json['version'] ?? '1.0',
      fechaModificacion: DateTime.parse(
        json['fecha_modificacion'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
