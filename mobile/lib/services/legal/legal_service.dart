import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/documento_legal_model.dart';

class LegalService {
  /// Obtiene los términos y condiciones desde el backend
  Future<DocumentoLegalModel> obtenerTerminos() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/legal/terminos/');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return DocumentoLegalModel.fromJson(data);
      } else {
        throw Exception('Error al cargar términos y condiciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene la política de privacidad desde el backend
  Future<DocumentoLegalModel> obtenerPrivacidad() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/legal/privacidad/');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return DocumentoLegalModel.fromJson(data);
      } else {
        throw Exception('Error al cargar política de privacidad');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
