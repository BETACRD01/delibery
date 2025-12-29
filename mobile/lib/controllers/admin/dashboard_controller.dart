// lib/controllers/admin/dashboard_controller.dart
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../apis/admin/solicitudes_api.dart';
import '../../apis/admin/dashboard_admin_api.dart';
import '../../apis/helpers/api_exception.dart';
import '../../models/solicitud_cambio_rol.dart';

class DashboardController extends ChangeNotifier {
  // Servicios
  final _api = AuthService();
  final _solicitudesApi = SolicitudesAdminAPI();
  final _dashboardApi = DashboardAdminAPI();

  // Estado
  Map<String, dynamic>? _usuario;
  bool _loading = true;
  String? _error;

  // Estadísticas
  int _totalUsuarios = 0;
  int _totalProveedores = 0;
  int _totalRepartidores = 0;
  int _proveedoresPendientes = 0;
  double _ventasTotales = 0.0;
  int _pedidosActivos = 0;

  // Solicitudes
  List<SolicitudCambioRol> _solicitudesPendientes = [];
  int _solicitudesPendientesCount = 0;

  // Getters
  Map<String, dynamic>? get usuario => _usuario;
  bool get loading => _loading;
  String? get error => _error;
  int get totalUsuarios => _totalUsuarios;
  int get totalProveedores => _totalProveedores;
  int get totalRepartidores => _totalRepartidores;
  int get proveedoresPendientes => _proveedoresPendientes;
  double get ventasTotales => _ventasTotales;
  int get pedidosActivos => _pedidosActivos;
  List<SolicitudCambioRol> get solicitudesPendientes => _solicitudesPendientes;
  int get solicitudesPendientesCount => _solicitudesPendientesCount;

  // ============================================
  // MÉTODOS DE CARGA
  // ============================================

  Future<void> cargarDatos() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final perfil = await _api.getPerfil();
      _usuario = perfil['usuario'];

      await _cargarEstadisticas();
      await cargarSolicitudesPendientes();

      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'Error al cargar información';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final data = await _dashboardApi.obtenerEstadisticas();

      final usuarios = data['usuarios'] as Map<String, dynamic>? ?? {};
      final proveedores = data['proveedores'] as Map<String, dynamic>? ?? {};
      final repartidores = data['repartidores'] as Map<String, dynamic>? ?? {};
      final pedidos = data['pedidos'] as Map<String, dynamic>? ?? {};
      final solicitudes =
          data['solicitudes_cambio_rol'] as Map<String, dynamic>? ?? {};

      _totalUsuarios = (usuarios['total'] as num?)?.toInt() ?? 0;
      _totalProveedores = (proveedores['total'] as num?)?.toInt() ?? 0;
      _totalRepartidores = (repartidores['total'] as num?)?.toInt() ?? 0;
      _proveedoresPendientes =
          (proveedores['pendientes'] as num?)?.toInt() ?? 0;

      // Pedidos activos: suma estados que no sean entregado/cancelado
      _pedidosActivos = _calcularPedidosActivos(pedidos['por_estado']);
      // Ventas: si no hay monto, usamos total pedidos del mes como proxy
      _ventasTotales = (pedidos['mes'] as num?)?.toDouble() ?? 0.0;

      // Solicitudes
      _solicitudesPendientesCount =
          (solicitudes['pendientes'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (e) {
      _error = 'No se pudieron cargar las estadísticas';
      notifyListeners();
    }
  }

  int _calcularPedidosActivos(dynamic porEstadoRaw) {
    if (porEstadoRaw is Map) {
      int total = 0;
      porEstadoRaw.forEach((key, value) {
        final estado = key?.toString().toUpperCase() ?? '';
        if (estado != 'ENTREGADO' && estado != 'CANCELADO') {
          total += (value as num?)?.toInt() ?? 0;
        }
      });
      return total;
    }
    return (porEstadoRaw as num?)?.toInt() ?? 0;
  }

  Future<void> cargarSolicitudesPendientes() async {
    try {
      final response = await _solicitudesApi.listarSolicitudes(
        estado: 'PENDIENTE',
        pageSize: 5,
      );

      final results = response['results'] as List<dynamic>?;
      if (results != null) {
        _solicitudesPendientes = results
            .map((json) => SolicitudCambioRol.fromJson(json))
            .toList();
        _solicitudesPendientesCount = response['count'] ?? results.length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando solicitudes pendientes: $e');
    }
  }

  void marcarSolicitudesPendientesVistas() {
    _solicitudesPendientesCount = 0;
    _solicitudesPendientes = [];
    notifyListeners();
  }

  // ============================================
  // ACCIONES DE SOLICITUDES
  // ============================================

  Future<void> aceptarSolicitud(String solicitudId, {String? motivo}) async {
    await _solicitudesApi.aceptarSolicitud(
      solicitudId,
      motivoRespuesta: motivo ?? 'Solicitud aprobada por administrador',
    );
    await cargarSolicitudesPendientes();
  }

  Future<void> rechazarSolicitud(String solicitudId, String motivo) async {
    await _solicitudesApi.rechazarSolicitud(
      solicitudId,
      motivoRespuesta: motivo,
    );
    await cargarSolicitudesPendientes();
  }

  Future<void> actualizarFotoPerfil(dynamic imagen) async {
    _loading = true;
    notifyListeners();
    try {
      await _api.actualizarFotoPerfil(imagen);
      // Recargar perfil para obtener la nueva URL
      await cargarDatos();
    } catch (e) {
      _error = 'Error al actualizar foto de perfil';
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cerrarSesion() async {
    await _api.logout();
  }
}
