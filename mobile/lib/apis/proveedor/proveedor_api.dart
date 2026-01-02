// lib/apis/proveedor/proveedor_api.dart

import 'dart:io';

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de proveedores
class ProveedorApi {
  // ---------------------------------------------------------------------------
  // SINGLETON
  // ---------------------------------------------------------------------------

  static final ProveedorApi _instance = ProveedorApi._internal();
  factory ProveedorApi() => _instance;
  ProveedorApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // CRUD BÁSICO (Endpoints públicos)
  // ---------------------------------------------------------------------------

  /// Lista proveedores con filtros
  Future<Map<String, dynamic>> getProveedores({
    bool? activos,
    bool? verificados,
    String? tipo,
    String? ciudad,
    String? search,
  }) async {
    final url = ApiConfig.buildProveedoresUrl(
      activos: activos,
      verificados: verificados,
      tipo: tipo,
      ciudad: ciudad,
      search: search,
    );
    return await _client.get(url);
  }

  /// Obtiene un proveedor por ID
  Future<Map<String, dynamic>> getProveedor(int id) async {
    return await _client.get(ApiConfig.proveedorDetalle(id));
  }

  /// Crea un proveedor
  Future<Map<String, dynamic>> createProveedor(
    Map<String, dynamic> data,
  ) async {
    return await _client.post(ApiConfig.proveedores, data);
  }

  /// Actualiza un proveedor (PUT)
  Future<Map<String, dynamic>> updateProveedor(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _client.put(ApiConfig.proveedorActualizar(id), data);
  }

  /// Actualiza un proveedor parcialmente (PATCH)
  Future<Map<String, dynamic>> patchProveedor(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.proveedorActualizar(id), data);
  }

  /// Elimina un proveedor
  Future<void> deleteProveedor(int id) async {
    await _client.delete(ApiConfig.proveedorActualizar(id));
  }

  // ---------------------------------------------------------------------------
  // PERFIL DEL PROVEEDOR AUTENTICADO
  // ---------------------------------------------------------------------------

  /// Obtiene el perfil del proveedor autenticado
  Future<Map<String, dynamic>> getMiProveedor() async {
    return await _client.get(ApiConfig.miProveedor);
  }

  /// Actualiza el perfil del proveedor autenticado
  Future<Map<String, dynamic>> patchMiProveedor(
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.miProveedorEditarPerfil, data);
  }

  /// Actualiza datos de contacto del proveedor autenticado
  Future<Map<String, dynamic>> patchMiContacto(
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.miProveedorEditarContacto, data);
  }

  // ---------------------------------------------------------------------------
  // SUBIDA DE LOGO
  // ---------------------------------------------------------------------------

  /// Sube logo de proveedor por ID
  Future<Map<String, dynamic>> uploadLogo(int id, File logoFile) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.proveedorActualizar(id),
      {},
      {'logo': logoFile},
    );
  }

  /// Sube logo del proveedor autenticado
  Future<Map<String, dynamic>> uploadMiLogo(File logoFile) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.miProveedorEditarPerfil,
      {},
      {'logo': logoFile},
    );
  }

  // ---------------------------------------------------------------------------
  // FILTROS Y BÚSQUEDAS
  // ---------------------------------------------------------------------------

  /// Obtiene proveedores activos
  Future<Map<String, dynamic>> getProveedoresActivos() async {
    return await _client.get(ApiConfig.proveedoresActivos);
  }

  /// Obtiene proveedores abiertos
  Future<Map<String, dynamic>> getProveedoresAbiertos() async {
    return await _client.get(ApiConfig.proveedoresAbiertos);
  }

  /// Obtiene proveedores por tipo
  Future<Map<String, dynamic>> getProveedoresPorTipo(String tipo) async {
    return await _client.get(ApiConfig.proveedoresPorTipoUrl(tipo));
  }

  // ---------------------------------------------------------------------------
  // ACCIONES ADMINISTRATIVAS (Endpoints públicos)
  // ---------------------------------------------------------------------------

  /// Activa un proveedor
  Future<Map<String, dynamic>> activarProveedor(int id) async {
    return await _client.post(ApiConfig.proveedorActivar(id), {});
  }

  /// Desactiva un proveedor
  Future<Map<String, dynamic>> desactivarProveedor(int id) async {
    return await _client.post(ApiConfig.proveedorDesactivar(id), {});
  }

  /// Verifica un proveedor
  Future<Map<String, dynamic>> verificarProveedor(int id) async {
    return await _client.post(ApiConfig.proveedorVerificar(id), {});
  }

  // ---------------------------------------------------------------------------
  // ADMIN ENDPOINTS
  // ---------------------------------------------------------------------------

  /// Lista proveedores (admin)
  Future<Map<String, dynamic>> getProveedoresAdmin({
    bool? verificado,
    bool? activo,
    String? tipoProveedor,
    String? search,
  }) async {
    final url = ApiConfig.buildAdminProveedoresUrl(
      verificado: verificado,
      activo: activo,
      tipoProveedor: tipoProveedor,
      search: search,
    );
    return await _client.get(url);
  }

  /// Obtiene detalle de proveedor (admin)
  Future<Map<String, dynamic>> getProveedorAdmin(int id) async {
    return await _client.get(ApiConfig.adminProveedorDetalle(id));
  }

  /// Actualiza proveedor (admin PUT)
  Future<Map<String, dynamic>> updateProveedorAdmin(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _client.put(ApiConfig.adminProveedorDetalle(id), data);
  }

  /// Actualiza proveedor parcialmente (admin PATCH)
  Future<Map<String, dynamic>> patchProveedorAdmin(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.adminProveedorDetalle(id), data);
  }

  /// Edita contacto de proveedor (admin)
  Future<Map<String, dynamic>> patchContactoProveedorAdmin(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(
      ApiConfig.adminProveedorEditarContacto(id),
      data,
    );
  }

  /// Verifica proveedor (admin)
  Future<Map<String, dynamic>> verificarProveedorAdmin(
    int id,
    Map<String, dynamic> body,
  ) async {
    return await _client.post(ApiConfig.adminProveedorVerificar(id), body);
  }

  /// Desactiva proveedor (admin)
  Future<Map<String, dynamic>> desactivarProveedorAdmin(int id) async {
    return await _client.post(ApiConfig.adminProveedorDesactivar(id), {});
  }

  /// Activa proveedor (admin)
  Future<Map<String, dynamic>> activarProveedorAdmin(int id) async {
    return await _client.post(ApiConfig.adminProveedorActivar(id), {});
  }

  /// Obtiene proveedores pendientes (admin)
  Future<Map<String, dynamic>> getProveedoresPendientes() async {
    return await _client.get(ApiConfig.adminProveedoresPendientes);
  }
}
