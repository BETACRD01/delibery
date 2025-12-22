// lib/apis/admin/rifas_admin_api.dart

import 'dart:developer' as developer;
import 'dart:io';

import '../../config/api_config.dart';
import '../subapis/http_client.dart';

class RifasAdminApi {
  final ApiClient _client = ApiClient();

  // ============================================
  // CREAR RIFA CON PREMIOS
  // ============================================

  Future<Map<String, dynamic>> crearRifa({
    required String titulo,
    required String descripcion,
    required int pedidosMinimos,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    File? imagen,
    List<Map<String, dynamic>>? premios,
  }) async {
    try {
      final body = <String, String>{
        'titulo': titulo,
        'descripcion': descripcion,
        'pedidos_minimos': pedidosMinimos.toString(),
        'fecha_inicio': fechaInicio.toIso8601String(),
        'fecha_fin': fechaFin.toIso8601String(),
      };

      // Agregar premios si existen
      if (premios != null && premios.isNotEmpty) {
        for (int i = 0; i < premios.length; i++) {
          final premio = premios[i];
          final posicion = premio['posicion'];
          final descripcion = premio['descripcion'];
          if (posicion != null && descripcion != null) {
            body['premios[$i][posicion]'] = posicion.toString();
            body['premios[$i][descripcion]'] = descripcion.toString();
          }
        }
      }

      final files = <String, File>{};
      if (imagen != null) {
        files['imagen'] = imagen;
      }

      // Agregar imágenes de premios si existen
      if (premios != null) {
        for (int i = 0; i < premios.length; i++) {
          if (premios[i]['imagen'] != null && premios[i]['imagen'] is File) {
            files['premios[$i][imagen]'] = premios[i]['imagen'];
          }
        }
      }

      return await _client.multipart(
        'POST',
        ApiConfig.rifasAdminBase,
        body,
        files,
      );
    } catch (e) {
      developer.log('Error creando rifa: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }

  // ============================================
  // LISTAR RIFAS
  // ============================================

  Future<Map<String, dynamic>> listarRifas({
    String? estado, // 'activa', 'finalizada', 'cancelada'
    int? mes,
    int? anio,
    int pagina = 1,
  }) async {
    try {
      final params = <String, String>{
        'page': pagina.toString(),
      };

      if (estado != null) params['estado'] = estado;
      if (mes != null) params['mes'] = mes.toString();
      if (anio != null) params['anio'] = anio.toString();

      // Construir URL con query params
      final uri = Uri.parse(ApiConfig.rifasAdminBase).replace(queryParameters: params);

      return await _client.get(uri.toString());
    } catch (e) {
      developer.log('Error listando rifas: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }

  // ============================================
  // OBTENER DETALLE DE RIFA
  // ============================================

  Future<Map<String, dynamic>> obtenerRifa(String rifaId) async {
    try {
      return await _client.get('${ApiConfig.rifasAdminBase}$rifaId/');
    } catch (e) {
      developer.log('Error obteniendo rifa $rifaId: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }

  // ============================================
  // ACTUALIZAR RIFA
  // ============================================

  Future<Map<String, dynamic>> actualizarRifa({
    required String rifaId,
    String? titulo,
    String? descripcion,
    int? pedidosMinimos,
    String? estado, // 'activa', 'finalizada', 'cancelada'
    File? imagen,
  }) async {
    try {
      final body = <String, String>{};

      if (titulo != null) body['titulo'] = titulo;
      if (descripcion != null) body['descripcion'] = descripcion;
      if (pedidosMinimos != null) body['pedidos_minimos'] = pedidosMinimos.toString();
      if (estado != null) body['estado'] = estado;

      final files = <String, File>{};
      if (imagen != null) {
        files['imagen'] = imagen;
      }

      if (files.isNotEmpty) {
        return await _client.multipart(
          'PATCH',
          '${ApiConfig.rifasAdminBase}$rifaId/',
          body,
          files,
        );
      } else {
        final bodyDynamic = body.map((k, v) => MapEntry(k, v as dynamic));
        return await _client.patch(
          '${ApiConfig.rifasAdminBase}$rifaId/',
          bodyDynamic,
        );
      }
    } catch (e) {
      developer.log('Error actualizando rifa $rifaId: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }

  // ============================================
  // REALIZAR SORTEO
  // ============================================

  Future<Map<String, dynamic>> realizarSorteo(String rifaId) async {
    try {
      return await _client.post(
        '${ApiConfig.rifasAdminBase}$rifaId/sortear/',
        {},
      );
    } catch (e) {
      developer.log('Error realizando sorteo de rifa $rifaId: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }

  // ============================================
  // OBTENER PARTICIPANTES
  // ============================================

  Future<Map<String, dynamic>> obtenerParticipantes(String rifaId) async {
    try {
      return await _client.get('${ApiConfig.rifasAdminBase}$rifaId/participantes/');
    } catch (e) {
      developer.log('Error obteniendo participantes de rifa $rifaId: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }

  // ============================================
  // CANCELAR RIFA
  // ============================================

  Future<Map<String, dynamic>> cancelarRifa(String rifaId) async {
    try {
      return await actualizarRifa(
        rifaId: rifaId,
        estado: 'cancelada',
      );
    } catch (e) {
      developer.log('Error cancelando rifa $rifaId: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }

  // ============================================
  // FINALIZAR RIFA
  // ============================================

  Future<Map<String, dynamic>> finalizarRifa(String rifaId) async {
    try {
      return await actualizarRifa(
        rifaId: rifaId,
        estado: 'finalizada',
      );
    } catch (e) {
      developer.log('Error finalizando rifa $rifaId: $e', name: 'RifasAdminApi');
      rethrow;
    }
  }
}
