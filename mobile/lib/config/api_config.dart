// lib/config/api_config.dart
import 'dart:developer' as developer;
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/material.dart';

class ApiConfig {
  ApiConfig._();

  // ============================================================================
  // CONSTANTES DE RED
  // ============================================================================

  static const _redCasa = '192.168.1';
  static const _ipLocal = '192.168.1.6';
  static const _redInstitucional = '172.16';
  static const _ipInstitucional = '172.16.61.251';
  static const _redHotspot = '192.168.137';
  static const _ipHotspot = '192.168.137.1';
  static const _ipEmulador = '10.0.2.2';
  static const _envHost = String.fromEnvironment('API_HOST');
  static const _envPort = String.fromEnvironment('API_PORT');
  static const _defaultPort = '8000';
  static const enableEmulatorFallback = bool.fromEnvironment(
    'ENABLE_EMULATOR_FALLBACK',
    defaultValue: false,
  );

  // ============================================================================
  // ESTADO INTERNO
  // ============================================================================

  static String? _cachedIp;
  static String? _network;
  static bool _initialized = false;
  static bool _manualMode = false;
  static String? _manualIp;
  static bool _isEmulator = false;

  // ============================================================================
  // INICIALIZACIÓN Y DETECCIÓN
  // ============================================================================

  static Future<void> initialize() async {
    if (_initialized) return;

    if (_envHost.isNotEmpty) {
      _network = 'MANUAL_ENV';
      setManualIp(_envHost);
      _initialized = true;
      await _printDebug();
      return;
    }

    try {
      await _detectIp();
      _initialized = true;
      await _printDebug();
    } catch (_) {
      _cachedIp = _ipLocal;
      _network = 'LOCAL (Fallback)';
      _initialized = true;
    }
  }

  static Future<String> _detectIp() async {
    try {
      if (await _checkEmulator()) {
        _network = 'EMULADOR';
        _cachedIp = _ipEmulador;
        return _buildUrl(_ipEmulador);
      }

      final wifiIP = await NetworkInfo().getWifiIP();

      if (wifiIP == null || wifiIP.isEmpty) {
        _cachedIp = _ipLocal;
        _network = 'LOCAL (Sin WiFi)';
        return _buildUrl(_ipLocal);
      }

      final configs = {
        _redCasa: ('CASA/RED_LOCAL', _ipLocal),
        _redHotspot: ('HOTSPOT', _ipHotspot),
        _redInstitucional: ('INSTITUCIONAL', _ipInstitucional),
      };

      for (final entry in configs.entries) {
        if (wifiIP.startsWith(entry.key)) {
          _network = entry.value.$1;
          _cachedIp = entry.value.$2;
          return _buildUrl(_cachedIp!);
        }
      }

      _network = 'DESCONOCIDA';
      _cachedIp = _ipLocal;
      return _buildUrl(_ipLocal);
    } catch (_) {
      _cachedIp = _ipLocal;
      _network = 'ERROR';
      return _buildUrl(_ipLocal);
    }
  }

  static Future<bool> _checkEmulator() async {
    if (!Platform.isAndroid) return false;
    try {
      if (Platform.environment.containsKey('ANDROID_EMULATOR')) {
        _isEmulator = true;
        return true;
      }
      final wifiIP = await NetworkInfo().getWifiIP();
      _isEmulator = wifiIP == '10.0.2.15' || wifiIP == '10.0.2.16';
      return _isEmulator;
    } catch (_) {
      return false;
    }
  }

  static String _buildUrl(String ip) => 'http://$ip:$puerto';

  static Future<String> refreshNetwork() async {
    _cachedIp = null;
    _network = null;
    return await _detectIp();
  }

  // ============================================================================
  // URL BASE
  // ============================================================================

  static const _prodUrl = 'https://api.deliber.com';
  static const _isProd = bool.fromEnvironment('dart.vm.product');

  static Future<String> getBaseUrl() async {
    if (_isProd) return _prodUrl;
    if (_cachedIp != null) return _buildUrl(_cachedIp!);
    return await _detectIp();
  }

  static String get baseUrl {
    if (_isProd) return _prodUrl;
    if (_envHost.isNotEmpty) return _buildUrl(_envHost);
    if (_manualMode && _manualIp != null) return _buildUrl(_manualIp!);
    if (_cachedIp != null) return _buildUrl(_cachedIp!);
    return _buildUrl(_ipLocal);
  }

  static String get apiUrl => '$baseUrl/api';

  static void setManualIp(String ip) {
    _manualMode = true;
    _manualIp = ip;
    _cachedIp = ip;
  }

  static void disableManualIp() {
    _manualMode = false;
    _manualIp = null;
    _cachedIp = null;
  }

  // ============================================================================
  // ENDPOINTS BASE
  // ============================================================================

  static String get _auth => '$apiUrl/auth';
  static String get _users => '$apiUrl/usuarios';
  static String get _products => '$apiUrl/productos';
  static String get _suppliers => '$apiUrl/proveedores';
  static String get _delivery => '$apiUrl/repartidores';
  static String get _admin => '$apiUrl/admin';
  static String get _adminEnvios => '$_admin/envios';
  static String get _payments => '$apiUrl/pagos';
  static String get _ratings => '$apiUrl/calificaciones';
  static String get _super => '$apiUrl/super-categorias';

  // ============================================================================
  // AUTH
  // ============================================================================

  static String get registro => '$_auth/registro/';
  static String get login => '$_auth/login/';
  static String get googleLogin => '$_auth/google-login/';
  static String get perfil => '$_auth/perfil/';
  static String get logout => '$_auth/logout/';
  static String get verificarToken => '$_auth/verificar-token/';
  static String get actualizarPerfil => '$_auth/actualizar-perfil/';
  static String get cambiarPassword => '$_auth/cambiar-password/';
  static String get solicitarCodigoRecuperacion =>
      '$_auth/solicitar-codigo-recuperacion/';
  static String get verificarCodigoRecuperacion => '$_auth/verificar-codigo/';
  static String get resetPasswordConCodigo =>
      '$_auth/reset-password-con-codigo/';
  static String get actualizarPreferencias =>
      '$_auth/preferencias-notificaciones/';
  static String get desactivarCuenta => '$_auth/desactivar-cuenta/';
  static String get tokenRefresh => '$_auth/token/refresh/';

  // ============================================================================
  // USUARIOS
  // ============================================================================

  static String get infoRol => '$_users/verificar-roles/';
  static String get usuariosPerfil => '$_users/perfil/';
  static String get usuariosActualizarPerfil => '$_users/perfil/actualizar/';
  static String get usuariosEstadisticas => '$_users/perfil/estadisticas/';
  static String get usuariosFotoPerfil => '$_users/perfil/foto/';
  static String usuariosPerfilPublico(int id) => '$_users/perfil/publico/$id/';

  static String get usuariosDirecciones => '$_users/direcciones/';
  static String usuariosDireccion(String id) => '$_users/direcciones/$id/';
  static String get usuariosDireccionPredeterminada =>
      '$_users/direcciones/predeterminada/';
  static String get usuariosUbicacionActualizar =>
      '$_users/ubicacion/actualizar/';
  static String get usuariosUbicacionMia => '$_users/ubicacion/mia/';

  static String get usuariosMetodosPago => '$_users/metodos-pago/';
  static String usuariosMetodoPago(String id) => '$_users/metodos-pago/$id/';
  static String get usuariosMetodoPagoPredeterminado =>
      '$_users/metodos-pago/predeterminado/';

  static String get usuariosFCMToken => '$_users/fcm-token/';
  static String get usuariosEliminarFCMToken => '$_users/fcm-token/eliminar/';
  static String get usuariosEstadoNotificaciones => '$_users/notificaciones/';

  static String get usuariosSolicitudesCambioRol =>
      '$_users/solicitudes-cambio-rol/';
  static String usuariosSolicitudCambioRolDetalle(String id) =>
      '$_users/solicitudes-cambio-rol/$id/';
  static String get usuariosCambiarRolActivo => '$_users/cambiar-rol-activo/';
  static String get usuariosMisRoles => '$_users/mis-roles/';

  // ============================================================================
  // RIFAS
  // ============================================================================

  static String get rifasMisParticipaciones =>
      '$apiUrl/rifas/participaciones/mis-participaciones/';
  static String get rifasActiva => '$apiUrl/rifas/rifas/activa/';
  static String get rifasEstadisticas => '$apiUrl/rifas/rifas/estadisticas/';
  static String get rifasAdminBase => '$apiUrl/rifas/rifas/';

  // ============================================================================
  // PRODUCTOS Y CARRITO
  // ============================================================================

  static String get productosCategorias => '$_products/categorias/';
  static String get productosLista => '$_products/productos/';
  static String get productosDestacados => '$_products/productos/destacados/';
  static String get productosPromociones => '$_products/promociones/';
  static String productoDetalle(int id) => '$_products/productos/$id/';
  static String promocionDetalle(int id) => '$_products/promociones/$id/';

  static String get carrito => '$_products/carrito/';
  static String get carritoAgregar => '$_products/carrito/agregar/';
  static String get carritoLimpiar => '$_products/carrito/limpiar/';
  static String get carritoCheckout => '$_products/carrito/checkout/';
  static String carritoItemCantidad(int id) =>
      '$_products/carrito/item/$id/cantidad/';
  static String carritoRemoverItem(int id) => '$_products/carrito/item/$id/';
  static String get enviosCotizar => '$apiUrl/envios/cotizar/';

  // ============================================================================
  // PROVEEDORES
  // ============================================================================

  static String get proveedores => '$_suppliers/';
  static String get miProveedor => '$_suppliers/mi_proveedor/';
  static String get miProveedorEditarPerfil => '$_suppliers/editar_mi_perfil/';
  static String get miProveedorEditarContacto =>
      '$_suppliers/editar_mi_contacto/';
  static String get proveedoresActivos => '$_suppliers/activos/';
  static String get proveedoresAbiertos => '$_suppliers/abiertos/';
  static String get proveedoresPorTipo => '$_suppliers/por_tipo/';

  static String proveedorDetalle(int id) => '$_suppliers/$id/';
  static String proveedorActualizar(int id) => '$_suppliers/$id/';
  static String proveedorActivar(int id) => '$_suppliers/$id/activar/';
  static String proveedorDesactivar(int id) => '$_suppliers/$id/desactivar/';
  static String proveedorVerificar(int id) => '$_suppliers/$id/verificar/';
  static String proveedoresPorTipoUrl(String tipo) =>
      '$_suppliers/por_tipo/?tipo=$tipo';

  static String buildProveedoresUrl({
    bool? activos,
    bool? verificados,
    String? tipo,
    String? ciudad,
    String? search,
  }) => _buildQueryUrl(proveedores, {
    'activos': activos,
    'verificados': verificados,
    'tipo_proveedor': tipo,
    'ciudad': ciudad,
    'search': search,
  });

  // ============================================================================
  // REPARTIDORES
  // ============================================================================

  static String get repartidorPerfil => '$_delivery/perfil/';
  static String get repartidorPerfilActualizar =>
      '$_delivery/perfil/actualizar/';
  static String get repartidorEstadisticas => '$_delivery/perfil/estadisticas/';
  static String get miRepartidor => '$_delivery/mi_repartidor/';
  static String get miRepartidorEditarPerfil => '$_delivery/editar_mi_perfil/';
  static String get miRepartidorEditarContacto =>
      '$_delivery/editar_mi_contacto/';
  static String get repartidorEstado => '$_delivery/estado/';
  static String get repartidorEstadoHistorial => '$_delivery/estado/historial/';
  static String get repartidorUbicacion => '$_delivery/ubicacion/';
  static String get repartidorUbicacionHistorial =>
      '$_delivery/ubicacion/historial/';
  static String get repartidorHistorialEntregas =>
      '$_delivery/historial-entregas/';
  static String get repartidorPedidosDisponibles =>
      '$_delivery/pedidos-disponibles/';
  static String get repartidorMisPedidos => '$_delivery/mis-pedidos/';
  static String get repartidorVehiculos => '$_delivery/vehiculos/';
  static String get repartidorVehiculosCrear => '$_delivery/vehiculos/crear/';
  static String get repartidorCalificaciones => '$_delivery/calificaciones/';
  static String get repartidorDatosBancarios => '$_delivery/datos-bancarios/';

  static String repartidorPedidoDetalle(int id) =>
      '$_delivery/pedidos/$id/detalle/';
  static String repartidorPedidoAceptar(int id) =>
      '$_delivery/pedidos/$id/aceptar/';
  static String repartidorPedidoRechazar(int id) =>
      '$_delivery/pedidos/$id/rechazar/';
  static String repartidorPedidoMarcarEnCamino(int id) =>
      '$_delivery/pedidos/$id/marcar-en-camino/';
  static String repartidorPedidoMarcarEntregado(int id) =>
      '$_delivery/pedidos/$id/marcar-entregado/';
  static String repartidorVehiculo(int id) => '$_delivery/vehiculos/$id/';
  static String repartidorVehiculoActivar(int id) =>
      '$_delivery/vehiculos/$id/activar/';
  static String repartidorCalificarCliente(int id) =>
      '$_delivery/calificaciones/clientes/$id/';
  static String repartidorPerfilPublicoPedido(int pedidoId) =>
      '$_delivery/publico/$pedidoId/';
  static String repartidorPublicoInfo(int repartidorId) =>
      '$_delivery/publico/$repartidorId/info/';

  // ============================================================================
  // CALIFICACIONES
  // ============================================================================

  static String get calificacionesRapida => '$_ratings/rapida/';
  static String calificacionesPendientesPedido(int pedidoId) =>
      '$_ratings/pendientes/$pedidoId/';
  static String calificacionesEntidad(String type, int id) =>
      '$_ratings/$type/$id/';
  static String calificacionesResumen(String type, int id) =>
      '$_ratings/$type/$id/resumen/';

  // ============================================================================
  // ADMIN
  // ============================================================================

  static String get adminDashboard => '$_admin/dashboard/';
  static String get adminAcciones => '$_admin/acciones/';
  // Admin - Envíos (solo administradores)
  static String get adminEnviosConfiguracion => '$_adminEnvios/configuracion/';
  static String get adminEnviosZonas => '$_adminEnvios/zonas/';
  static String get adminEnviosCiudades => '$_adminEnvios/ciudades/';

  // Admin - Proveedores
  static String get adminProveedores => '$_admin/proveedores/';
  static String get adminProveedoresPendientes =>
      '$_admin/proveedores/pendientes/';
  static String adminProveedorDetalle(int id) => '$_admin/proveedores/$id/';
  static String adminProveedorEditarContacto(int id) =>
      '$_admin/proveedores/$id/editar_contacto/';
  static String adminProveedorVerificar(int id) =>
      '$_admin/proveedores/$id/verificar/';
  static String adminProveedorDesactivar(int id) =>
      '$_admin/proveedores/$id/desactivar/';
  static String adminProveedorActivar(int id) =>
      '$_admin/proveedores/$id/activar/';

  static String buildAdminProveedoresUrl({
    bool? verificado,
    bool? activo,
    String? tipoProveedor,
    String? search,
  }) => _buildQueryUrl(adminProveedores, {
    'verificado': verificado,
    'activo': activo,
    'tipo_proveedor': tipoProveedor,
    'search': search,
  });

  // Admin - Repartidores
  static String get adminRepartidores => '$_admin/repartidores/';
  static String get adminRepartidoresPendientes =>
      '$_admin/repartidores/pendientes/';
  static String adminRepartidorDetalle(int id) => '$_admin/repartidores/$id/';
  static String adminRepartidorEditarContacto(int id) =>
      '$_admin/repartidores/$id/editar_contacto/';
  static String adminRepartidorVerificar(int id) =>
      '$_admin/repartidores/$id/verificar/';
  static String adminRepartidorDesactivar(int id) =>
      '$_admin/repartidores/$id/desactivar/';
  static String adminRepartidorActivar(int id) =>
      '$_admin/repartidores/$id/activar/';

  static String buildAdminRepartidoresUrl({
    bool? verificado,
    bool? activo,
    String? estado,
    String? search,
  }) => _buildQueryUrl(adminRepartidores, {
    'verificado': verificado,
    'activo': activo,
    'estado': estado,
    'search': search,
  });

  // Admin - Usuarios
  static String get adminUsuarios => '$_admin/usuarios/';
  static String adminUsuarioDetalle(int id) => '$_admin/usuarios/$id/';
  static String adminUsuarioResetPassword(int id) =>
      '$_admin/usuarios/$id/resetear_password/';

  static String buildAdminUsuariosUrl({
    String? search,
    bool? activo,
    bool? rol,
  }) => _buildQueryUrl(adminUsuarios, {
    'search': search,
    'activo': activo,
    'rol': rol,
  });

  // Admin - Solicitudes
  static String get adminSolicitudesCambioRol =>
      '$_admin/solicitudes-cambio-rol/';
  static String get adminSolicitudesPendientes =>
      '$_admin/solicitudes-cambio-rol/pendientes/';
  static String get adminSolicitudesEstadisticas =>
      '$_admin/solicitudes-cambio-rol/estadisticas/';
  static String adminSolicitudCambioRolDetalle(String id) =>
      '$_admin/solicitudes-cambio-rol/$id/';
  static String adminAceptarSolicitud(String id) =>
      '$_admin/solicitudes-cambio-rol/$id/aceptar/';
  static String adminRechazarSolicitud(String id) =>
      '$_admin/solicitudes-cambio-rol/$id/rechazar/';

  // ============================================================================
  // PEDIDOS
  // ============================================================================

  static String get pedidos => '$apiUrl/pedidos/';
  static String get misGruposPedidos => '$apiUrl/pedidos/mis-grupos/';
  static String pedidoDetalle(int id) => '$apiUrl/pedidos/$id/';
  static String pedidoAceptarRepartidor(int id) =>
      '$apiUrl/pedidos/$id/aceptar-repartidor/';
  static String pedidoConfirmarProveedor(int id) =>
      '$apiUrl/pedidos/$id/confirmar-proveedor/';
  static String pedidoCambiarEstado(int id) => '$apiUrl/pedidos/$id/estado/';
  static String pedidoCancelar(int id) => '$apiUrl/pedidos/$id/cancelar/';
  static String pedidoGanancias(int id) => '$apiUrl/pedidos/$id/ganancias/';
  static String listarPedidosGrupo(String grupo) =>
      '$apiUrl/pedidos/grupos/$grupo/';

  static String buildPedidosUrl({
    String? estado,
    String? tipo,
    int page = 1,
    int pageSize = 20,
  }) => _buildQueryUrl(pedidos, {
    'estado': estado,
    'tipo': tipo,
    'page': page,
    'page_size': pageSize,
  });

  // ============================================================================
  // PAGOS
  // ============================================================================

  static String obtenerDatosBancariosPago(int pagoId) =>
      '$_payments/pagos/$pagoId/datos-bancarios/';
  static String subirComprobantePago(int pagoId) =>
      '$_payments/pagos/$pagoId/subir-comprobante/';
  static String verComprobanteRepartidor(int pagoId) =>
      '$_payments/pagos/$pagoId/ver-comprobante/';
  static String marcarComprobanteVisto(int pagoId) =>
      '$_payments/pagos/$pagoId/marcar-visto/';

  // ============================================================================
  // SUPER (Supermercados, Farmacias, etc.)
  // ============================================================================

  static String get superCategorias => '$_super/categorias/';
  static String get superProveedores => '$_super/proveedores/';
  static String get superProveedoresAbiertos => '$_super/proveedores/abiertos/';
  static String get superProductos => '$_super/productos/';
  static String get superProductosOfertas => '$_super/productos/ofertas/';
  static String get superProductosDestacados => '$_super/productos/destacados/';

  static String superCategoriaDetalle(String id) => '$_super/categorias/$id/';
  static String superCategoriaProductos(String id) =>
      '$_super/categorias/$id/productos/';
  static String superProveedorDetalle(int id) => '$_super/proveedores/$id/';
  static String superProveedorProductos(int id) =>
      '$_super/proveedores/$id/productos/';
  static String superProveedoresPorCategoria(String categoriaId) =>
      '$_super/proveedores/por_categoria/?categoria=$categoriaId';
  static String superProductoDetalle(int id) => '$_super/productos/$id/';

  // ============================================================================
  // CONSTANTES
  // ============================================================================

  static const apiKeyMobile =
      'mobile_app_deliber_2025_aW7xK3pM9qR5tL2nV8jH4cF6gB1dY0sZ';
  static const apiKeyWeb =
      'web_admin_deliber_2025_XkJ9mP3nQ7wR2vL5zT8hF1cY4gN6sB0d';
  static String get currentApiKey => apiKeyMobile;

  static String get puerto => _envPort.isNotEmpty ? _envPort : _defaultPort;
  static String get localBackendIp => _ipLocal;
  static String get emulatorHost => _ipEmulador;

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
  static const sendTimeout = Duration(seconds: 30);
  static const maxRetries = 3;
  static const retryDelay = Duration(seconds: 2);

  static const codigoLongitud = 6;
  static const codigoExpiracionMinutos = 15;
  static const maxIntentosVerificacion = 5;

  static const rolUsuario = 'USUARIO';
  static const rolRepartidor = 'REPARTIDOR';
  static const rolProveedor = 'PROVEEDOR';
  static const rolAdministrador = 'ADMINISTRADOR';

  static const tiposProveedor = [
    'restaurante',
    'farmacia',
    'supermercado',
    'tienda',
    'otro',
  ];

  // HTTP Status
  static const statusOk = 200;
  static const statusCreated = 201;
  static const statusBadRequest = 400;
  static const statusUnauthorized = 401;
  static const statusForbidden = 403;
  static const statusNotFound = 404;
  static const statusTooManyRequests = 429;
  static const statusServerError = 500;

  // Error Messages
  static const errorNetwork = 'Error de conexion. Verifica tu internet.';
  static const errorTimeout = 'La peticion tardo demasiado. Intenta de nuevo.';
  static const errorUnauthorized = 'Sesion expirada. Inicia sesion nuevamente.';
  static const errorServer = 'Error del servidor. Intenta mas tarde.';
  static const errorUnknown = 'Ocurrio un error inesperado.';
  static const errorRateLimit = 'Demasiados intentos. Espera un momento.';

  // ============================================================================
  // HELPERS
  // ============================================================================

  static bool get isProduction => _isProd;
  static bool get isDevelopment => !_isProd;
  static bool get isHttps => baseUrl.startsWith('https');
  static String? get currentNetwork => _network;
  static String? get currentServerIp => _cachedIp;
  static bool get isInitialized => _initialized;
  static bool get isEmulatorDevice => _isEmulator;

  static String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('http') ? path : '$baseUrl$path';
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  static bool validarHorarios(String? apertura, String? cierre) {
    if (apertura == null || cierre == null) return true;
    try {
      final open = _parseTime(apertura);
      final close = _parseTime(cierre);
      return (close.hour * 60 + close.minute) > (open.hour * 60 + open.minute);
    } catch (_) {
      return false;
    }
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _buildQueryUrl(String base, Map<String, dynamic> params) {
    final filtered = params.entries.where(
      (e) => e.value != null && e.value.toString().isNotEmpty,
    );
    if (filtered.isEmpty) return base;
    final qs = filtered
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '$base?$qs';
  }

  static Future<void> _printDebug() async {
    final buffer = StringBuffer()
      ..writeln('--- Deliber API Config ---')
      ..writeln('Env: ${_isProd ? "PROD" : "DEV"}')
      ..writeln('URL: ${await getBaseUrl()}');

    if (_network != null) buffer.writeln('Red: $_network');
    if (_cachedIp != null) buffer.writeln('IP: $_cachedIp:$puerto');
    if (_manualMode) buffer.writeln('Manual: $_manualIp');

    developer.log(buffer.toString(), name: 'Deliber API');
  }
}
