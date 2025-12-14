// lib/config/api_config.dart

import 'dart:developer' as developer;
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/material.dart';

class ApiConfig {
  // ---------------------------------------------------------------------------
  // 1. CONSTANTES DE RED (IPs)
  // ---------------------------------------------------------------------------

  static const String _redCasaPrefix = '192.168.1';
  // IP fija del backend en la red local (interfaz wlo1)
  static const String _ipBackendLocal = '192.168.1.5';
  static const String _redInstitucionalPrefix = '172.16';
  static const String _ipInstitucional = '172.16.60.5';
  static const String _redHotspotPrefix = '192.168.137';
  static const String _ipHotspot = '192.168.137.1';
  static const String _ipEmulador = '10.0.2.2';
  static const String _envHost = String.fromEnvironment('API_HOST');
  static const String _envPort = String.fromEnvironment('API_PORT');
  static const String _defaultPort = '8000';
  static const bool enableEmulatorFallback = bool.fromEnvironment('ENABLE_EMULATOR_FALLBACK', defaultValue: false);

  // ---------------------------------------------------------------------------
  // 2. ESTADO INTERNO
  // ---------------------------------------------------------------------------

  static String? _cachedServerIp;
  static String? _lastDetectedNetwork;
  static bool _isInitialized = false;
  static bool _forceManualIp = false;
  static String? _manualIp;
  static bool _isEmulatorDevice = false;

  // ---------------------------------------------------------------------------
  // 3. LOGICA DE INICIALIZACION
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Permite forzar la IP desde --dart-define=API_HOST para no depender de detección.
    if (_envHost.isNotEmpty) {
      _lastDetectedNetwork = 'MANUAL_ENV';
      setManualIp(_envHost);
      _isInitialized = true;
      await printDebugInfo();
      return;
    }

    try {
      await detectServerIp();
      _isInitialized = true;
      await printDebugInfo();
    } catch (e) {
      // Fallback si la detección falla, usa la IP local configurada
      _cachedServerIp = _ipBackendLocal;
      _lastDetectedNetwork = 'LOCAL (Fallback)';
      _isInitialized = true;
    }
  }

  static Future<String> detectServerIp() async {
    try {
      if (await _isRunningOnEmulator()) {
        _lastDetectedNetwork = 'EMULADOR';
        _cachedServerIp = _ipEmulador;
        return _buildUrl(_ipEmulador);
      }

      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();

      if (wifiIP == null || wifiIP.isEmpty) {
        // Usa el backend local si no hay conexión WiFi activa
        _cachedServerIp = _ipBackendLocal;
        _lastDetectedNetwork = 'LOCAL (Sin WiFi)';
        return _buildUrl(_ipBackendLocal);
      }

      // Si estamos en la red de casa, usamos directamente la IP local del backend
      if (wifiIP.startsWith(_redCasaPrefix)) {
        _lastDetectedNetwork = 'CASA/RED_LOCAL';
        _cachedServerIp = _ipBackendLocal;
        return _buildUrl(_cachedServerIp!);
      }

      if (wifiIP.startsWith(_redHotspotPrefix)) {
        _lastDetectedNetwork = 'HOTSPOT';
        _cachedServerIp = _ipHotspot;
        return _buildUrl(_ipHotspot);
      }

      if (wifiIP.startsWith(_redInstitucionalPrefix)) {
        _lastDetectedNetwork = 'INSTITUCIONAL';
        _cachedServerIp = _ipInstitucional;
        return _buildUrl(_ipInstitucional);
      }

      _lastDetectedNetwork = 'DESCONOCIDA';
      _cachedServerIp = _ipBackendLocal; // Fallback al backend local para desarrollo
      return _buildUrl(_ipBackendLocal);

    } catch (e) {
      _cachedServerIp = _ipBackendLocal;
      _lastDetectedNetwork = 'ERROR';
      return _buildUrl(_ipBackendLocal);
    }
  }

  static Future<bool> _isRunningOnEmulator() async {
    if (!Platform.isAndroid) return false;
    try {
      final isEmu = Platform.environment.containsKey('ANDROID_EMULATOR') || await _checkEmulatorByNetwork();
      if (isEmu) _isEmulatorDevice = true;
      return isEmu;
    } catch (e) { return false; }
  }

  static Future<bool> _checkEmulatorByNetwork() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      return wifiIP == '10.0.2.15' || wifiIP == '10.0.2.16';
    } catch (e) { return false; }
  }

  static String _buildUrl(String ip) => 'http://$ip:$puertoServidor';

  static Future<String> refreshNetworkDetection() async {
    _cachedServerIp = null;
    _lastDetectedNetwork = null;
    return await detectServerIp();
  }

  // ---------------------------------------------------------------------------
  // 4. GESTION DE URL BASE Y MANUAL
  // ---------------------------------------------------------------------------

  static Future<String> getBaseUrl() async {
    if (const bool.fromEnvironment('dart.vm.product')) return 'https://api.deliber.com';
    if (_cachedServerIp != null) return _buildUrl(_cachedServerIp!);
    return await detectServerIp();
  }

  static String get baseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) return 'https://api.deliber.com';
    if (_envHost.isNotEmpty) return _buildUrl(_envHost); // Prioriza la IP pasada por --dart-define
    if (_forceManualIp && _manualIp != null) return _buildUrl(_manualIp!);
    if (_cachedServerIp != null) return _buildUrl(_cachedServerIp!);
    // Usa la IP local como último recurso en desarrollo
    return _buildUrl(_ipBackendLocal); 
  }

  static String get apiUrl => '$baseUrl/api';

  static void setManualIp(String ip) {
    _forceManualIp = true;
    _manualIp = ip;
    _cachedServerIp = ip;
  }

  static void disableManualIp() {
    _forceManualIp = false;
    _manualIp = null;
    _cachedServerIp = null;
  }

  // ---------------------------------------------------------------------------
  // 5. DEFINICION DE RUTAS (ENDPOINTS)
  // ---------------------------------------------------------------------------

  static String get _auth => '$apiUrl/auth';
  static String get _users => '$apiUrl/usuarios';
  static String get _products => '$apiUrl/productos';
  static String get _suppliers => '$apiUrl/proveedores';
  static String get _delivery => '$apiUrl/repartidores';
  static String get _admin => '$apiUrl/admin';
  static String get _payments => '$apiUrl/pagos';

  // --- A. AUTENTICACION ---
  static String get registro => '$_auth/registro/';
  static String get login => '$_auth/login/';
  static String get googleLogin => '$_auth/google-login/';
  static String get perfil => '$_auth/perfil/';
  static String get logout => '$_auth/logout/';
  static String get infoRol => '$_users/verificar-roles/';
  static String get verificarToken => '$_auth/verificar-token/';
  static String get actualizarPerfil => '$_auth/actualizar-perfil/';
  static String get cambiarPassword => '$_auth/cambiar-password/';
  static String get solicitarCodigoRecuperacion => '$_auth/solicitar-codigo-recuperacion/';
  static String get verificarCodigoRecuperacion => '$_auth/verificar-codigo/';
  static String get resetPasswordConCodigo => '$_auth/reset-password-con-codigo/';
  static String get actualizarPreferencias => '$_auth/preferencias-notificaciones/';
  static String get desactivarCuenta => '$_auth/desactivar-cuenta/';
  static String get tokenRefresh => '$_auth/token/refresh/';

  // --- B. USUARIOS ---
  static String get usuariosPerfil => '$_users/perfil/';
  static String get usuariosActualizarPerfil => '$_users/perfil/actualizar/';
  static String get usuariosEstadisticas => '$_users/perfil/estadisticas/';
  static String usuariosPerfilPublico(int id) => '$_users/perfil/publico/$id/';
  static String get usuariosFotoPerfil => '$_users/perfil/foto/';
  
  static String get usuariosDirecciones => '$_users/direcciones/';
  static String usuariosDireccion(String id) => '$_users/direcciones/$id/';
  static String get usuariosDireccionPredeterminada => '$_users/direcciones/predeterminada/';
  static String get usuariosUbicacionActualizar => '$_users/ubicacion/actualizar/';
  static String get usuariosUbicacionMia => '$_users/ubicacion/mia/';
  
  static String get usuariosMetodosPago => '$_users/metodos-pago/';
  static String usuariosMetodoPago(String id) => '$_users/metodos-pago/$id/';
  static String get usuariosMetodoPagoPredeterminado => '$_users/metodos-pago/predeterminado/';
  static String get usuariosFCMToken => '$_users/fcm-token/';
  static String get usuariosEliminarFCMToken => '$_users/fcm-token/eliminar/';
  static String get usuariosEstadoNotificaciones => '$_users/notificaciones/';
  static String get rifasMisParticipaciones => '$apiUrl/rifas/participaciones/mis-participaciones/';
  // Nota: la app de rifas se incluye en la ruta /api/rifas/, y el router de DRF registra "rifas" y "participaciones"
  static String get rifasActiva => '$apiUrl/rifas/rifas/activa/';
  static String get rifasEstadisticas => '$apiUrl/rifas/rifas/estadisticas/';
  static String get rifasAdminBase => '$apiUrl/rifas/rifas/';

  static String get usuariosSolicitudesCambioRol => '$_users/solicitudes-cambio-rol/';
  static String usuariosSolicitudCambioRolDetalle(String id) => '$_users/solicitudes-cambio-rol/$id/';
  static String get usuariosCambiarRolActivo => '$_users/cambiar-rol-activo/';
  static String get usuariosMisRoles => '$_users/mis-roles/';

  // --- C. PRODUCTOS Y CARRITO ---
  static String get productosCategorias => '$_products/categorias/';
  static String get productosLista => '$_products/productos/';
  static String productoDetalle(int id) => '$_products/productos/$id/';
  static String get productosDestacados => '$_products/productos/destacados/';
  static String get productosPromociones => '$_products/promociones/';

  static String get carrito => '$_products/carrito/';
  static String get carritoAgregar => '$_products/carrito/agregar/';
  static String get carritoLimpiar => '$_products/carrito/limpiar/';
  static String get carritoCheckout => '$_products/carrito/checkout/';
  static String carritoItemCantidad(int id) => '$_products/carrito/item/$id/cantidad/';
  static String carritoRemoverItem(int id) => '$_products/carrito/item/$id/';
  static String get enviosCotizar => '$apiUrl/envios/cotizar/';

  // --- D. PROVEEDORES ---
  static String get proveedores => '$_suppliers/';
  static String proveedorDetalle(int id) => '$_suppliers/$id/';
  static String proveedorActualizar(int id) => '$_suppliers/$id/';
  static String get miProveedor => '$_suppliers/mi_proveedor/';
  static String get miProveedorEditarPerfil => '$_suppliers/editar_mi_perfil/'; 
  static String get miProveedorEditarContacto => '$_suppliers/editar_mi_contacto/'; 
  static String get proveedoresActivos => '$_suppliers/activos/';
  static String get proveedoresAbiertos => '$_suppliers/abiertos/';
  static String get proveedoresPorTipo => '$_suppliers/por_tipo/';
  static String proveedoresPorTipoUrl(String tipo) => '$_suppliers/por_tipo/?tipo=$tipo';
  
  static String proveedorActivar(int id) => '$_suppliers/$id/activar/';
  static String proveedorDesactivar(int id) => '$_suppliers/$id/desactivar/';
  static String proveedorVerificar(int id) => '$_suppliers/$id/verificar/';

  static String buildProveedoresUrl({bool? activos, bool? verificados, String? tipo, String? ciudad, String? search}) {
    final params = <String, String>{};
    if (activos != null) params['activos'] = activos.toString();
    if (verificados != null) params['verificados'] = verificados.toString();
    if (tipo != null) params['tipo_proveedor'] = tipo;
    if (ciudad != null) params['ciudad'] = ciudad;
    if (search != null) params['search'] = search;
    
    if (params.isEmpty) return proveedores;
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$proveedores?$qs';
  }

  // --- E. REPARTIDORES ---
  static String get repartidorPerfil => '$_delivery/perfil/';
  static String get repartidorPerfilActualizar => '$_delivery/perfil/actualizar/';
  static String get repartidorEstadisticas => '$_delivery/perfil/estadisticas/';
  static String get miRepartidor => '$_delivery/mi_repartidor/';
  static String get miRepartidorEditarPerfil => '$_delivery/editar_mi_perfil/';
  static String get miRepartidorEditarContacto => '$_delivery/editar_mi_contacto/';
  static String get repartidorEstado => '$_delivery/estado/';
  static String get repartidorEstadoHistorial => '$_delivery/estado/historial/';
  static String get repartidorUbicacion => '$_delivery/ubicacion/';
  static String get repartidorUbicacionHistorial => '$_delivery/ubicacion/historial/';
  static String get repartidorHistorialEntregas => '$_delivery/historial-entregas/';
  static String get repartidorPedidosDisponibles => '$_delivery/pedidos-disponibles/';
  static String get repartidorMisPedidos => '$_delivery/mis-pedidos/';
  static String repartidorPedidoDetalle(int id) => '$_delivery/pedidos/$id/detalle/';
  static String repartidorPedidoAceptar(int id) => '$_delivery/pedidos/$id/aceptar/';
  static String repartidorPedidoRechazar(int id) => '$_delivery/pedidos/$id/rechazar/';
  static String repartidorPedidoMarcarEnCamino(int id) => '$_delivery/pedidos/$id/marcar-en-camino/';
  static String repartidorPedidoMarcarEntregado(int id) => '$_delivery/pedidos/$id/marcar-entregado/';
  static String get repartidorVehiculos => '$_delivery/vehiculos/';
  static String get repartidorVehiculosCrear => '$_delivery/vehiculos/crear/';
  static String repartidorVehiculo(int id) => '$_delivery/vehiculos/$id/';
  static String repartidorVehiculoActivar(int id) => '$_delivery/vehiculos/$id/activar/';
  static String get repartidorCalificaciones => '$_delivery/calificaciones/';
  static String repartidorCalificarCliente(int id) => '$_delivery/calificaciones/clientes/$id/';

  // 🆕 Datos bancarios del repartidor
  static String get repartidorDatosBancarios => '$_delivery/datos-bancarios/';

  // --- F. ADMIN ---
  static String get adminProveedores => '$_admin/proveedores/';
  static String adminProveedorDetalle(int id) => '$_admin/proveedores/$id/';
  static String adminProveedorEditarContacto(int id) => '$_admin/proveedores/$id/editar_contacto/';
  static String adminProveedorVerificar(int id) => '$_admin/proveedores/$id/verificar/';
  static String adminProveedorDesactivar(int id) => '$_admin/proveedores/$id/desactivar/';
  static String adminProveedorActivar(int id) => '$_admin/proveedores/$id/activar/';
  static String get adminProveedoresPendientes => '$_admin/proveedores/pendientes/';

  static String buildAdminProveedoresUrl({bool? verificado, bool? activo, String? tipoProveedor, String? search}) {
    final params = <String, String>{};
    if (verificado != null) params['verificado'] = verificado.toString();
    if (activo != null) params['activo'] = activo.toString();
    if (tipoProveedor != null) params['tipo_proveedor'] = tipoProveedor;
    if (search != null) params['search'] = search;
    
    if (params.isEmpty) return adminProveedores;
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$adminProveedores?$qs';
  }

  static String get adminRepartidores => '$_admin/repartidores/';
  static String adminRepartidorDetalle(int id) => '$_admin/repartidores/$id/';
  static String adminRepartidorEditarContacto(int id) => '$_admin/repartidores/$id/editar_contacto/';
  static String adminRepartidorVerificar(int id) => '$_admin/repartidores/$id/verificar/';
  static String adminRepartidorDesactivar(int id) => '$_admin/repartidores/$id/desactivar/';
  static String adminRepartidorActivar(int id) => '$_admin/repartidores/$id/activar/';
  static String get adminRepartidoresPendientes => '$_admin/repartidores/pendientes/';

  static String buildAdminRepartidoresUrl({bool? verificado, bool? activo, String? estado, String? search}) {
    final params = <String, String>{};
    if (verificado != null) params['verificado'] = verificado.toString();
    if (activo != null) params['activo'] = activo.toString();
    if (estado != null) params['estado'] = estado;
    if (search != null) params['search'] = search;
    
    if (params.isEmpty) return adminRepartidores;
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$adminRepartidores?$qs';
  }

  // --- F. ADMIN - USUARIOS ---
  static String get adminUsuarios => '$_admin/usuarios/';
  static String adminUsuarioDetalle(int id) => '$_admin/usuarios/$id/';
  static String adminUsuarioResetPassword(int id) => '$_admin/usuarios/$id/resetear_password/';
  static String buildAdminUsuariosUrl({String? search, bool? activo, bool? rol}) {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (activo != null) params['activo'] = activo.toString();
    if (rol != null) params['rol'] = rol.toString();
    if (params.isEmpty) return adminUsuarios;
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$adminUsuarios?$qs';
  }

  static String get adminSolicitudesCambioRol => '$_admin/solicitudes-cambio-rol/';
  static String adminSolicitudCambioRolDetalle(String id) => '$_admin/solicitudes-cambio-rol/$id/';
  static String adminAceptarSolicitud(String id) => '$_admin/solicitudes-cambio-rol/$id/aceptar/';
  static String adminRechazarSolicitud(String id) => '$_admin/solicitudes-cambio-rol/$id/rechazar/';
  static String get adminSolicitudesPendientes => '$_admin/solicitudes-cambio-rol/pendientes/';
  static String get adminSolicitudesEstadisticas => '$_admin/solicitudes-cambio-rol/estadisticas/';
  static String get adminDashboard => '$_admin/dashboard/';
  static String get adminAcciones => '$_admin/acciones/';

  // --- G. PEDIDOS ---
  static String get pedidos => '$apiUrl/pedidos/';
  static String pedidoDetalle(int id) => '$apiUrl/pedidos/$id/';
  static String pedidoAceptarRepartidor(int id) => '$apiUrl/pedidos/$id/aceptar-repartidor/';
  static String pedidoConfirmarProveedor(int id) => '$apiUrl/pedidos/$id/confirmar-proveedor/';
  static String pedidoCambiarEstado(int id) => '$apiUrl/pedidos/$id/estado/';
  static String pedidoCancelar(int id) => '$apiUrl/pedidos/$id/cancelar/';
  static String pedidoGanancias(int id) => '$apiUrl/pedidos/$id/ganancias/';

  static String buildPedidosUrl({
    String? estado,
    String? tipo,
    int page = 1,
    int pageSize = 20,
  }) {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (estado != null) params['estado'] = estado;
    if (tipo != null) params['tipo'] = tipo;

    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$pedidos?$qs';
  }

  // Pedidos Agrupados (Multi-Proveedor)
  static String listarPedidosGrupo(String pedidoGrupo) => '$apiUrl/pedidos/grupos/$pedidoGrupo/';
  static String get misGruposPedidos => '$apiUrl/pedidos/mis-grupos/';

  // --- H. PAGOS ---
  static String obtenerDatosBancariosPago(int pagoId) => '$_payments/pagos/$pagoId/datos-bancarios/';
  static String subirComprobantePago(int pagoId) => '$_payments/pagos/$pagoId/subir-comprobante/';
  static String verComprobanteRepartidor(int pagoId) => '$_payments/pagos/$pagoId/ver-comprobante/';
  static String marcarComprobanteVisto(int pagoId) => '$_payments/pagos/$pagoId/marcar-visto/';

  // --- I. SUPER (Supermercados, Farmacias, Bebidas, Mensajería, Tiendas) ---
  // ✅ CORREGIDO: Cambiado de '/super' a '/super-categorias' sin barra final
  static String get _super => '$apiUrl/super-categorias';

  // Categorías Super
  static String get superCategorias => '$_super/';
  static String superCategoriaDetalle(String id) => '$_super/$id/';
  static String superCategoriaProductos(String id) => '$_super/$id/productos/';

  // Proveedores Super
  static String get superProveedores => '$_super/proveedores/';
  static String superProveedorDetalle(int id) => '$_super/proveedores/$id/';
  static String superProveedorProductos(int id) => '$_super/proveedores/$id/productos/';
  static String get superProveedoresAbiertos => '$_super/proveedores/abiertos/';
  static String superProveedoresPorCategoria(String categoriaId) => '$_super/proveedores/por_categoria/?categoria=$categoriaId';

  // Productos Super
  static String get superProductos => '$_super/productos/';
  static String superProductoDetalle(int id) => '$_super/productos/$id/';
  static String get superProductosOfertas => '$_super/productos/ofertas/';
  static String get superProductosDestacados => '$_super/productos/destacados/';

  // ---------------------------------------------------------------------------
  // 6. CONSTANTES Y CONFIGURACION
  // ---------------------------------------------------------------------------

  static const String apiKeyMobile = 'mobile_app_deliber_2025_aW7xK3pM9qR5tL2nV8jH4cF6gB1dY0sZ';
  static const String apiKeyWeb = 'web_admin_deliber_2025_XkJ9mP3nQ7wR2vL5zT8hF1cY4gN6sB0d';
  static String get currentApiKey => apiKeyMobile;

  static String get puertoServidor => _envPort.isNotEmpty ? _envPort : _defaultPort;
  static String get localBackendIp => _ipBackendLocal;
  static String get emulatorHost => _ipEmulador;

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  static const int codigoLongitud = 6;
  static const int codigoExpiracionMinutos = 15;
  static const int maxIntentosVerificacion = 5;

  static const String rolUsuario = 'USUARIO';
  static const String rolRepartidor = 'REPARTIDOR';
  static const String rolProveedor = 'PROVEEDOR';
  static const String rolAdministrador = 'ADMINISTRADOR';

  static const List<String> tiposProveedor = [
    'restaurante', 'farmacia', 'supermercado', 'tienda', 'otro'
  ];

  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusTooManyRequests = 429;
  static const int statusServerError = 500;

  static const String errorNetwork = 'Error de conexion. Verifica tu internet.';
  static const String errorTimeout = 'La peticion tardo demasiado. Intenta de nuevo.';
  static const String errorUnauthorized = 'Sesion expirada. Inicia sesion nuevamente.';
  static const String errorServer = 'Error del servidor. Intenta mas tarde.';
  static const String errorUnknown = 'Ocurrio un error inesperado.';
  static const String errorRateLimit = 'Demasiados intentos. Espera un momento.';

  // ---------------------------------------------------------------------------
  // 7. DEBUGGER
  // ---------------------------------------------------------------------------

  static Future<void> printDebugInfo() async {
    const bool isProd = bool.fromEnvironment('dart.vm.product');
    final currentUrl = await getBaseUrl();
    final buffer = StringBuffer();
    
    buffer.writeln('--- Deliber API Config ---');
    buffer.writeln('Env: ${isProd ? "PROD" : "DEV"}');
    buffer.writeln('URL: $currentUrl');
    
    if (_lastDetectedNetwork != null) buffer.writeln('Red: $_lastDetectedNetwork');
    if (_cachedServerIp != null) buffer.writeln('IP: $_cachedServerIp:$puertoServidor');
    if (_forceManualIp) buffer.writeln('Manual: $_manualIp');

    developer.log(buffer.toString(), name: 'Deliber API');
  }

  // ---------------------------------------------------------------------------
  // 8. HELPERS
  // ---------------------------------------------------------------------------

  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
  static bool get isHttps => baseUrl.startsWith('https');
  static String? get currentNetwork => _lastDetectedNetwork;
  static String? get currentServerIp => _cachedServerIp;
  static bool get isInitialized => _isInitialized;

  static String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) { return false; }
  }

  static bool get isEmulatorDevice => _isEmulatorDevice;

  static bool validarHorarios(String? apertura, String? cierre) {
    if (apertura == null || cierre == null) return true;
    try {
      final open = _parseTime(apertura);
      final close = _parseTime(cierre);
      return (close.hour * 60 + close.minute) > (open.hour * 60 + open.minute);
    } catch (e) { return false; }
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
