// lib/services/proveedor_service.dart

import 'dart:io';
import 'dart:developer' as developer;
import '../config/api_config.dart';
import '../models/proveedor.dart';
import '../apis/subapis/http_client.dart';

/// Servicio para gestionar proveedores
class ProveedorService {
  final ApiClient _apiClient = ApiClient();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'ProveedorService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD BÁSICO (Endpoints públicos)
  // ---------------------------------------------------------------------------

  Future<List<ProveedorListModel>> listarProveedores({
    bool? activos,
    bool? verificados,
    String? tipo,
    String? ciudad,
    String? search,
  }) async {
    try {
      final url = ApiConfig.buildProveedoresUrl(
        activos: activos,
        verificados: verificados,
        tipo: tipo,
        ciudad: ciudad,
        search: search,
      );

      final response = await _apiClient.get(url);
      final List<dynamic> proveedoresJson = response.containsKey('results') 
          ? response['results'] as List<dynamic> 
          : [];

      return proveedoresJson
          .map((json) => ProveedorListModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log('Error listando proveedores', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> obtenerProveedor(int id) async {
    try {
      final response = await _apiClient.get(ApiConfig.proveedorDetalle(id));
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error obteniendo proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> crearProveedor(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ApiConfig.proveedores, data);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error creando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedor(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiConfig.proveedorActualizar(id), data);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error actualizando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedorParcial(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(ApiConfig.proveedorActualizar(id), data);

      if (response.isEmpty) {
        // CORRECCIÓN 1: Agregado 'const'
        throw const FormatException('Respuesta vacía del servidor en PATCH');
      }

      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error actualizando parcialmente proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> eliminarProveedor(int id) async {
    try {
      await _apiClient.delete(ApiConfig.proveedorActualizar(id));
    } catch (e, stackTrace) {
      _log('Error eliminando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // PERFIL DEL PROVEEDOR AUTENTICADO
  // ---------------------------------------------------------------------------

  Future<ProveedorModel> obtenerMiProveedor() async {
    try {
      final response = await _apiClient.get(ApiConfig.miProveedor);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error obteniendo mi proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarMiProveedor(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(ApiConfig.miProveedorEditarPerfil, data);

      if (response.isEmpty) {
        // CORRECCIÓN 2: Agregado 'const'
        throw const FormatException('Respuesta vacía en PATCH');
      }

      if (response.containsKey('proveedor')) {
        return ProveedorModel.fromJson(response['proveedor']);
      }

      if (response['id'] != null) {
        return ProveedorModel.fromJson(response);
      }

      return await obtenerMiProveedor();
    } catch (e, stackTrace) {
      _log('Error actualizando mi proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // SUBIDA DE LOGO
  // ---------------------------------------------------------------------------

  Future<ProveedorModel> subirLogo(int id, File logoFile) async {
    try {
      final response = await _apiClient.multipart(
        'PATCH',
        ApiConfig.proveedorActualizar(id),
        {},
        {'logo': logoFile},
      );

      if (response.isEmpty) {
        // CORRECCIÓN 3: Agregado 'const'
        throw const FormatException('Respuesta vacía del servidor al subir logo');
      }

      if (response['id'] == null) {
        return await obtenerProveedor(id);
      }

      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error subiendo logo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> subirMiLogo(File logoFile) async {
    try {
      final response = await _apiClient.multipart(
        'PATCH',
        ApiConfig.miProveedorEditarPerfil,
        {},
        {'logo': logoFile},
      );

      if (response.isEmpty) {
        // CORRECCIÓN 4: Agregado 'const'
        throw const FormatException('Respuesta vacía del servidor al subir logo');
      }

      if (response.containsKey('proveedor')) {
        return ProveedorModel.fromJson(response['proveedor']);
      }
      
      if (response['id'] != null) {
        return ProveedorModel.fromJson(response);
      }

      return await obtenerMiProveedor();
    } catch (e, stackTrace) {
      _log('Error subiendo mi logo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // FILTROS Y BÚSQUEDAS
  // ---------------------------------------------------------------------------

  Future<List<ProveedorListModel>> obtenerProveedoresActivos() async {
    try {
      final response = await _apiClient.get(ApiConfig.proveedoresActivos);
      final List<dynamic> proveedoresJson = response.containsKey('results') 
          ? response['results'] as List<dynamic> 
          : [];

      return proveedoresJson
          .map((json) => ProveedorListModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log('Error obteniendo proveedores activos', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ProveedorListModel>> obtenerProveedoresAbiertos() async {
    try {
      final response = await _apiClient.get(ApiConfig.proveedoresAbiertos);
      final List<dynamic> proveedoresJson = response.containsKey('results') 
          ? response['results'] as List<dynamic> 
          : [];

      return proveedoresJson
          .map((json) => ProveedorListModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log('Error obteniendo proveedores abiertos', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ProveedorListModel>> obtenerProveedoresPorTipo(String tipo) async {
    try {
      final url = ApiConfig.proveedoresPorTipoUrl(tipo);
      final response = await _apiClient.get(url);
      final List<dynamic> proveedoresJson = response.containsKey('results') 
          ? response['results'] as List<dynamic> 
          : [];

      return proveedoresJson
          .map((json) => ProveedorListModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log('Error obteniendo proveedores por tipo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ACCIONES ADMINISTRATIVAS (Endpoints públicos)
  // ---------------------------------------------------------------------------

  Future<ProveedorModel> activarProveedor(int id) async {
    try {
      final response = await _apiClient.post(ApiConfig.proveedorActivar(id), {});
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error activando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> desactivarProveedor(int id) async {
    try {
      final response = await _apiClient.post(ApiConfig.proveedorDesactivar(id), {});
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error desactivando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> verificarProveedor(int id) async {
    try {
      final response = await _apiClient.post(ApiConfig.proveedorVerificar(id), {});
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error verificando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ADMIN ENDPOINTS - GESTIÓN COMPLETA
  // ---------------------------------------------------------------------------

  Future<List<ProveedorListModel>> listarProveedoresAdmin({
    bool? verificado,
    bool? activo,
    String? tipoProveedor,
    String? search,
  }) async {
    try {
      final url = ApiConfig.buildAdminProveedoresUrl(
        verificado: verificado,
        activo: activo,
        tipoProveedor: tipoProveedor,
        search: search,
      );

      final response = await _apiClient.get(url);
      final List<dynamic> proveedoresJson = response.containsKey('results') 
          ? response['results'] as List<dynamic> 
          : [];

      return proveedoresJson
          .map((json) => ProveedorListModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log('Error listando proveedores admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> obtenerProveedorAdmin(int id) async {
    try {
      final response = await _apiClient.get(ApiConfig.adminProveedorDetalle(id));
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error obteniendo proveedor admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedorAdmin(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiConfig.adminProveedorDetalle(id), data);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error actualizando proveedor admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedorAdminParcial(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(ApiConfig.adminProveedorDetalle(id), data);

      if (response.isEmpty || response['id'] == null) {
        return await obtenerProveedorAdmin(id);
      }

      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error actualizando parcialmente admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> editarMiContacto({
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      if ((email == null || email.isEmpty) &&
          (firstName == null || firstName.isEmpty) &&
          (lastName == null || lastName.isEmpty)) {
        throw ArgumentError('Debes proporcionar al menos un dato de contacto');
      }

      final data = <String, dynamic>{};
      if (email != null && email.isNotEmpty) data['email'] = email;
      if (firstName != null && firstName.isNotEmpty) data['first_name'] = firstName;
      if (lastName != null && lastName.isNotEmpty) data['last_name'] = lastName;

      final response = await _apiClient.patch(ApiConfig.miProveedorEditarContacto, data);

      if (!response.containsKey('proveedor')) {
        return await obtenerMiProveedor();
      }

      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error editando mis datos contacto', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> editarContactoProveedorAdmin(
    int id, {
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (email != null) data['email'] = email;
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;

      if (data.isEmpty) throw ArgumentError('Debe proporcionar al menos un campo');

      final response = await _apiClient.patch(ApiConfig.adminProveedorEditarContacto(id), data);

      if (response.isEmpty || response['id'] == null) {
        return await obtenerProveedorAdmin(id);
      }

      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error editando contacto admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> verificarProveedorAdmin(
    int id, {
    required bool verificado,
    String? motivo,
  }) async {
    try {
      final body = {
        'verificado': verificado,
        if (motivo != null) 'motivo': motivo,
      };

      final response = await _apiClient.post(ApiConfig.adminProveedorVerificar(id), body);
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error verificando proveedor admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> desactivarProveedorAdmin(int id) async {
    try {
      final response = await _apiClient.post(ApiConfig.adminProveedorDesactivar(id), {});
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error desactivando admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> activarProveedorAdmin(int id) async {
    try {
      final response = await _apiClient.post(ApiConfig.adminProveedorActivar(id), {});
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error activando admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ProveedorListModel>> obtenerProveedoresPendientes() async {
    try {
      final response = await _apiClient.get(ApiConfig.adminProveedoresPendientes);

      final List<dynamic> proveedoresJson;
      if (response.containsKey('proveedores')) {
        proveedoresJson = response['proveedores'] as List<dynamic>;
      } else if (response.containsKey('results')) {
        proveedoresJson = response['results'] as List<dynamic>;
      } else {
        proveedoresJson = [];
      }

      return proveedoresJson
          .map((json) => ProveedorListModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log('Error obteniendo pendientes admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES
  // ---------------------------------------------------------------------------

  bool puedeEditar(ProveedorModel proveedor) {
    final userRole = _apiClient.userRole;
    final userId = _apiClient.userId;

    if (userRole == ApiConfig.rolAdministrador) return true;
    if (userRole == ApiConfig.rolProveedor && proveedor.userId == userId) return true;
    return false;
  }

  bool get esProveedor => _apiClient.userRole == ApiConfig.rolProveedor;
  bool get esAdministrador => _apiClient.userRole == ApiConfig.rolAdministrador;
  bool tienePermisoAdmin() => esAdministrador;
}