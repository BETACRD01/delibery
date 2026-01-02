// lib/apis/repartidor/repartidor_api.dart

import 'dart:io';

import '../../config/network/api_config.dart';
import '../subapis/http_client.dart';

/// API para gestión de repartidores
class RepartidorApi {
  static final RepartidorApi _instance = RepartidorApi._internal();
  factory RepartidorApi() => _instance;
  RepartidorApi._internal();

  final _client = ApiClient();

  // ---------------------------------------------------------------------------
  // PERFIL
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getPerfil() async {
    return await _client.get(ApiConfig.repartidorPerfil);
  }

  Future<Map<String, dynamic>> patchPerfil(Map<String, dynamic> data) async {
    return await _client.patch(ApiConfig.repartidorPerfilActualizar, data);
  }

  Future<Map<String, dynamic>> patchPerfilConFoto(
    Map<String, String> fields,
    File fotoPerfil,
  ) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.repartidorPerfilActualizar,
      fields,
      {'foto_perfil': fotoPerfil},
    );
  }

  Future<Map<String, dynamic>> getEstadisticas() async {
    return await _client.get(ApiConfig.repartidorEstadisticas);
  }

  // ---------------------------------------------------------------------------
  // ESTADO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> patchEstado(String estado) async {
    return await _client.patch(ApiConfig.repartidorEstado, {'estado': estado});
  }

  Future<Map<String, dynamic>> getHistorialEstados(String url) async {
    return await _client.get(url);
  }

  // ---------------------------------------------------------------------------
  // UBICACIÓN
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> patchUbicacion(
    double latitud,
    double longitud,
  ) async {
    return await _client.patch(ApiConfig.repartidorUbicacion, {
      'latitud': latitud,
      'longitud': longitud,
    });
  }

  Future<Map<String, dynamic>> getHistorialUbicaciones(String url) async {
    return await _client.get(url);
  }

  // ---------------------------------------------------------------------------
  // PEDIDOS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getPedidosDisponibles(String url) async {
    return await _client.get(url);
  }

  Future<Map<String, dynamic>> getDetallePedido(int pedidoId) async {
    return await _client.get(ApiConfig.repartidorPedidoDetalle(pedidoId));
  }

  Future<Map<String, dynamic>> getMisPedidosActivos() async {
    return await _client.get(ApiConfig.repartidorMisPedidos);
  }

  Future<Map<String, dynamic>> postAceptarPedido(int pedidoId) async {
    return await _client.post(ApiConfig.repartidorPedidoAceptar(pedidoId), {});
  }

  Future<Map<String, dynamic>> postRechazarPedido(
    int pedidoId,
    String motivo,
  ) async {
    return await _client.post(ApiConfig.repartidorPedidoRechazar(pedidoId), {
      'motivo': motivo,
    });
  }

  Future<Map<String, dynamic>> postCalificarCliente(
    int pedidoId,
    Map<String, dynamic> data,
  ) async {
    return await _client.post(
      ApiConfig.repartidorCalificarCliente(pedidoId),
      data,
    );
  }

  Future<Map<String, dynamic>> postMarcarEnCamino(int pedidoId) async {
    return await _client.post(
      ApiConfig.repartidorPedidoMarcarEnCamino(pedidoId),
      {},
    );
  }

  Future<Map<String, dynamic>> postMarcarEntregado(int pedidoId) async {
    return await _client.post(
      ApiConfig.repartidorPedidoMarcarEntregado(pedidoId),
      {},
    );
  }

  Future<Map<String, dynamic>> postMarcarEntregadoConImagen(
    int pedidoId,
    File imagen,
  ) async {
    return await _client.multipart(
      'POST',
      ApiConfig.repartidorPedidoMarcarEntregado(pedidoId),
      {},
      {'imagen_evidencia': imagen},
    );
  }

  // ---------------------------------------------------------------------------
  // VEHÍCULOS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getVehiculos() async {
    return await _client.get(ApiConfig.repartidorVehiculos);
  }

  Future<Map<String, dynamic>> postVehiculo(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.repartidorVehiculosCrear, data);
  }

  Future<Map<String, dynamic>> getVehiculo(int vehiculoId) async {
    return await _client.get(ApiConfig.repartidorVehiculo(vehiculoId));
  }

  Future<Map<String, dynamic>> patchVehiculo(
    int vehiculoId,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.repartidorVehiculo(vehiculoId), data);
  }

  Future<void> deleteVehiculo(int vehiculoId) async {
    await _client.delete(ApiConfig.repartidorVehiculo(vehiculoId));
  }

  Future<Map<String, dynamic>> patchActivarVehiculo(int vehiculoId) async {
    return await _client.patch(
      ApiConfig.repartidorVehiculoActivar(vehiculoId),
      {},
    );
  }

  Future<Map<String, dynamic>> patchDatosVehiculo(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(endpoint, data);
  }

  Future<Map<String, dynamic>> patchDatosVehiculoConFoto(
    String endpoint,
    Map<String, String> fields,
    File licenciaFoto,
  ) async {
    return await _client.multipart('PATCH', endpoint, fields, {
      'licencia_foto': licenciaFoto,
    });
  }

  // ---------------------------------------------------------------------------
  // CALIFICACIONES
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getCalificaciones(String url) async {
    return await _client.get(url);
  }

  // ---------------------------------------------------------------------------
  // MI REPARTIDOR
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMiRepartidor() async {
    return await _client.get(ApiConfig.miRepartidor);
  }

  Future<Map<String, dynamic>> patchMiPerfil(Map<String, dynamic> data) async {
    return await _client.patch(ApiConfig.miRepartidorEditarPerfil, data);
  }

  Future<Map<String, dynamic>> patchMiPerfilConFoto(
    Map<String, String> fields,
    File fotoPerfil,
  ) async {
    return await _client.multipart(
      'PATCH',
      ApiConfig.miRepartidorEditarPerfil,
      fields,
      {'foto_perfil': fotoPerfil},
    );
  }

  Future<Map<String, dynamic>> patchMiContacto(
    Map<String, dynamic> data,
  ) async {
    return await _client.patch(ApiConfig.miRepartidorEditarContacto, data);
  }

  // ---------------------------------------------------------------------------
  // HISTORIAL
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getHistorialEntregas(String url) async {
    return await _client.get(url);
  }
}
