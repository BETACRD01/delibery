// lib/services/proveedor/proveedor_service.dart

import 'dart:developer' as developer;
import 'dart:io';

import '../../apis/proveedor/proveedor_api.dart';
import '../../apis/subapis/http_client.dart';
import '../../config/network/api_config.dart';
import '../../models/entities/proveedor.dart';

/// Servicio para gestionar proveedores
/// Delegación: Usa ProveedorApi para llamadas HTTP
class ProveedorService {
  final _proveedorApi = ProveedorApi();
  final _apiClient = ApiClient(); // Solo para roles y permisos

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
      final response = await _proveedorApi.getProveedores(
        activos: activos,
        verificados: verificados,
        tipo: tipo,
        ciudad: ciudad,
        search: search,
      );
      final List<dynamic> proveedoresJson = response.containsKey('results')
          ? response['results'] as List<dynamic>
          : [];

      return proveedoresJson
          .map(
            (json) => ProveedorListModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      _log('Error listando proveedores', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> obtenerProveedor(int id) async {
    try {
      final response = await _proveedorApi.getProveedor(id);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error obteniendo proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> crearProveedor(Map<String, dynamic> data) async {
    try {
      final response = await _proveedorApi.createProveedor(data);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error creando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedor(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _proveedorApi.updateProveedor(id, data);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error actualizando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedorParcial(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _proveedorApi.patchProveedor(id, data);

      if (response.isEmpty) {
        throw const FormatException('Respuesta vacía del servidor en PATCH');
      }

      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log(
        'Error actualizando parcialmente proveedor',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> eliminarProveedor(int id) async {
    try {
      await _proveedorApi.deleteProveedor(id);
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
      final response = await _proveedorApi.getMiProveedor();
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log('Error obteniendo mi proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarMiProveedor(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _proveedorApi.patchMiProveedor(data);

      if (response.isEmpty) {
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
      final response = await _proveedorApi.uploadLogo(id, logoFile);

      if (response.isEmpty) {
        throw const FormatException(
          'Respuesta vacía del servidor al subir logo',
        );
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
      final response = await _proveedorApi.uploadMiLogo(logoFile);

      if (response.isEmpty) {
        throw const FormatException(
          'Respuesta vacía del servidor al subir logo',
        );
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
      final response = await _proveedorApi.getProveedoresActivos();
      final List<dynamic> proveedoresJson = response.containsKey('results')
          ? response['results'] as List<dynamic>
          : [];

      return proveedoresJson
          .map(
            (json) => ProveedorListModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo proveedores activos',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ProveedorListModel>> obtenerProveedoresAbiertos() async {
    try {
      final response = await _proveedorApi.getProveedoresAbiertos();
      final List<dynamic> proveedoresJson = response.containsKey('results')
          ? response['results'] as List<dynamic>
          : [];

      return proveedoresJson
          .map(
            (json) => ProveedorListModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo proveedores abiertos',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ProveedorListModel>> obtenerProveedoresPorTipo(
    String tipo,
  ) async {
    try {
      final response = await _proveedorApi.getProveedoresPorTipo(tipo);
      final List<dynamic> proveedoresJson = response.containsKey('results')
          ? response['results'] as List<dynamic>
          : [];

      return proveedoresJson
          .map(
            (json) => ProveedorListModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo proveedores por tipo',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ACCIONES ADMINISTRATIVAS (Endpoints públicos)
  // ---------------------------------------------------------------------------

  Future<ProveedorModel> activarProveedor(int id) async {
    try {
      final response = await _proveedorApi.activarProveedor(id);
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error activando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> desactivarProveedor(int id) async {
    try {
      final response = await _proveedorApi.desactivarProveedor(id);
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error desactivando proveedor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> verificarProveedor(int id) async {
    try {
      final response = await _proveedorApi.verificarProveedor(id);
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
      final response = await _proveedorApi.getProveedoresAdmin(
        verificado: verificado,
        activo: activo,
        tipoProveedor: tipoProveedor,
        search: search,
      );
      final List<dynamic> proveedoresJson = response.containsKey('results')
          ? response['results'] as List<dynamic>
          : [];

      return proveedoresJson
          .map(
            (json) => ProveedorListModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      _log(
        'Error listando proveedores admin',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProveedorModel> obtenerProveedorAdmin(int id) async {
    try {
      final response = await _proveedorApi.getProveedorAdmin(id);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo proveedor admin',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedorAdmin(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _proveedorApi.updateProveedorAdmin(id, data);
      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log(
        'Error actualizando proveedor admin',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProveedorModel> actualizarProveedorAdminParcial(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _proveedorApi.patchProveedorAdmin(id, data);

      if (response.isEmpty || response['id'] == null) {
        return await obtenerProveedorAdmin(id);
      }

      return ProveedorModel.fromJson(response);
    } catch (e, stackTrace) {
      _log(
        'Error actualizando parcialmente admin',
        error: e,
        stackTrace: stackTrace,
      );
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
      if (firstName != null && firstName.isNotEmpty) {
        data['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) data['last_name'] = lastName;

      final response = await _proveedorApi.patchMiContacto(data);

      if (!response.containsKey('proveedor')) {
        return await obtenerMiProveedor();
      }

      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log(
        'Error editando mis datos contacto',
        error: e,
        stackTrace: stackTrace,
      );
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

      if (data.isEmpty) {
        throw ArgumentError('Debe proporcionar al menos un campo');
      }

      final response = await _proveedorApi.patchContactoProveedorAdmin(
        id,
        data,
      );

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

      final response = await _proveedorApi.verificarProveedorAdmin(id, body);
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log(
        'Error verificando proveedor admin',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProveedorModel> desactivarProveedorAdmin(int id) async {
    try {
      final response = await _proveedorApi.desactivarProveedorAdmin(id);
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error desactivando admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProveedorModel> activarProveedorAdmin(int id) async {
    try {
      final response = await _proveedorApi.activarProveedorAdmin(id);
      return ProveedorModel.fromJson(response['proveedor']);
    } catch (e, stackTrace) {
      _log('Error activando admin', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ProveedorListModel>> obtenerProveedoresPendientes() async {
    try {
      final response = await _proveedorApi.getProveedoresPendientes();

      final List<dynamic> proveedoresJson;
      if (response.containsKey('proveedores')) {
        proveedoresJson = response['proveedores'] as List<dynamic>;
      } else if (response.containsKey('results')) {
        proveedoresJson = response['results'] as List<dynamic>;
      } else {
        proveedoresJson = [];
      }

      return proveedoresJson
          .map(
            (json) => ProveedorListModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      _log(
        'Error obteniendo pendientes admin',
        error: e,
        stackTrace: stackTrace,
      );
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
    if (userRole == ApiConfig.rolProveedor && proveedor.userId == userId) {
      return true;
    }
    return false;
  }

  bool get esProveedor => _apiClient.userRole == ApiConfig.rolProveedor;
  bool get esAdministrador => _apiClient.userRole == ApiConfig.rolAdministrador;
  bool tienePermisoAdmin() => esAdministrador;
}
