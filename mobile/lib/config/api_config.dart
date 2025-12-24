// lib/config/api_config.dart

import 'dart:developer' as developer;

import 'package:flutter/material.dart';

class ApiConfig {
  ApiConfig._();

  // ============================================================================
  // 1. CONFIGURACIÓN PRINCIPAL (NGROK / PRODUCCIÓN)
  // ============================================================================

  // CAMBIA ESTO CADA VEZ QUE REINICIES NGROK (Sin la barra / al final)
  static const String _ngrokUrl = 'https://7a09d7fed6a6.ngrok-free.app';

  // URL para producción (cuando subas a Play Store)
  static const String _prodUrl = 'https://api.tu-dominio-real.com';

  // Cambia a 'true' SOLO cuando generes el APK final
  static const bool _isProduction = false;

  // ============================================================================
  // 2. INICIALIZACIÓN
  // ============================================================================

  /// Método de inicialización (llamado desde main.dart)
  static Future<void> initialize() async {
    developer.log('API CONFIG: Inicializando...');
    developer.log(
      'MODO: ${_isProduction ? "PRODUCCIÓN" : "DESARROLLO (Ngrok)"}',
    );
    developer.log('URL BASE: $baseUrl');
  }

  // ============================================================================
  // 3. GETTERS GLOBALES
  // ============================================================================

  /// Devuelve la URL base activa
  static String get baseUrl => _isProduction ? _prodUrl : _ngrokUrl;

  /// Endpoint principal de la API
  static String get apiUrl => '$baseUrl/api';

  /// Endpoint para imágenes/media
  static String get mediaUrl => '$baseUrl/media';

  // ============================================================================
  // 4. ENDPOINTS: AUTH
  // ============================================================================

  static String get _auth => '$apiUrl/auth';

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
  // 5. ENDPOINTS: USUARIOS
  // ============================================================================

  static String get _users => '$apiUrl/usuarios';

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
  // 6. ENDPOINTS: RIFAS
  // ============================================================================

  static String get rifasMisParticipaciones =>
      '$apiUrl/rifas/participaciones/mis-participaciones/';
  static String get rifasActiva => '$apiUrl/rifas/rifas/activa/';
  static String get rifasMesActual => '$apiUrl/rifas/mes-actual/';
  static String get rifasEstadisticas => '$apiUrl/rifas/rifas/estadisticas/';
  static String get rifasAdminBase => '$apiUrl/rifas/rifas/';
  static String rifasDetalle(String rifaId) => '$apiUrl/rifas/$rifaId/detalle/';
  static String rifasParticipar(String rifaId) =>
      '$apiUrl/rifas/$rifaId/participar/';

  // ============================================================================
  // 7. ENDPOINTS: PRODUCTOS Y CARRITO
  // ============================================================================

  static String get _products => '$apiUrl/productos';

  static String get productosCategorias => '$_products/categorias/';
  static String get productosLista => '$_products/productos/';
  static String get productosDestacados => '$_products/productos/destacados/';
  static String get productosPromociones => '$_products/promociones/';
  static String productoDetalle(int id) => '$_products/productos/$id/';
  static String promocionDetalle(int id) => '$_products/promociones/$id/';

  // Endpoints para panel proveedor (Gestión de productos)
  static String get providerProducts => '$_products/provider/products/';
  static String providerProductDetail(int id) =>
      '$_products/provider/products/$id/';
  static String providerProductRatings(int id) =>
      '$_products/provider/products/$id/reviews/';

  // Endpoints para panel proveedor (Gestión de promociones)
  static String get providerPromociones => '$_products/provider/promociones/';
  static String providerPromocionDetalle(int id) =>
      '$_products/provider/promociones/$id/';

  static String get carrito => '$_products/carrito/';
  static String get carritoAgregar => '$_products/carrito/agregar/';
  static String get carritoLimpiar => '$_products/carrito/limpiar/';
  static String get carritoCheckout => '$_products/carrito/checkout/';
  static String carritoItemCantidad(int id) =>
      '$_products/carrito/item/$id/cantidad/';
  static String carritoRemoverItem(int id) => '$_products/carrito/item/$id/';

  static String get enviosCotizar => '$apiUrl/envios/cotizar/';

  // ============================================================================
  // 8. ENDPOINTS: PROVEEDORES
  // ============================================================================

  static String get _suppliers => '$apiUrl/proveedores';

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
  }) => buildQueryUrl(proveedores, {
    'activos': activos,
    'verificados': verificados,
    'tipo_proveedor': tipo,
    'ciudad': ciudad,
    'search': search,
  });

  // ============================================================================
  // 9. ENDPOINTS: REPARTIDORES
  // ============================================================================

  static String get _delivery => '$apiUrl/repartidores';

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
  // 10. ENDPOINTS: CALIFICACIONES
  // ============================================================================

  static String get _ratings => '$apiUrl/calificaciones';

  static String get calificacionesRapida => '$_ratings/rapida/';
  static String calificacionesPendientesPedido(int pedidoId) =>
      '$_ratings/pendientes/$pedidoId/';
  static String calificacionesEntidad(String type, int id) =>
      '$_ratings/$type/$id/';
  static String calificacionesResumen(String type, int id) =>
      '$_ratings/$type/$id/resumen/';

  // ============================================================================
  // 11. ENDPOINTS: ADMIN
  // ============================================================================

  static String get _admin => '$apiUrl/admin';
  static String get _adminEnvios => '$_admin/envios';

  static String get adminDashboard => '$_admin/dashboard/';
  static String get adminAcciones => '$_admin/acciones/';

  // Admin Envíos
  static String get adminEnviosConfiguracion => '$_adminEnvios/configuracion/';
  static String get adminEnviosZonas => '$_adminEnvios/zonas/';
  static String get adminEnviosCiudades => '$_adminEnvios/ciudades/';

  // Admin Proveedores
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
  }) => buildQueryUrl(adminProveedores, {
    'verificado': verificado,
    'activo': activo,
    'tipo_proveedor': tipoProveedor,
    'search': search,
  });

  // Admin Repartidores
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
  }) => buildQueryUrl(adminRepartidores, {
    'verificado': verificado,
    'activo': activo,
    'estado': estado,
    'search': search,
  });

  // Admin Usuarios
  static String get adminUsuarios => '$_admin/usuarios/';
  static String adminUsuarioDetalle(int id) => '$_admin/usuarios/$id/';
  static String adminUsuarioResetPassword(int id) =>
      '$_admin/usuarios/$id/resetear_password/';

  static String buildAdminUsuariosUrl({
    String? search,
    bool? activo,
    bool? rol,
  }) => buildQueryUrl(adminUsuarios, {
    'search': search,
    'activo': activo,
    'rol': rol,
  });

  // Admin Solicitudes
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
  // 12. ENDPOINTS: PEDIDOS
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
  }) => buildQueryUrl(pedidos, {
    'estado': estado,
    'tipo': tipo,
    'page': page,
    'page_size': pageSize,
  });

  // ============================================================================
  // 13. ENDPOINTS: PAGOS
  // ============================================================================

  static String get _payments => '$apiUrl/pagos';

  static String obtenerDatosBancariosPago(int pagoId) =>
      '$_payments/pagos/$pagoId/datos-bancarios/';
  static String subirComprobantePago(int pagoId) =>
      '$_payments/pagos/$pagoId/subir-comprobante/';
  static String verComprobanteRepartidor(int pagoId) =>
      '$_payments/pagos/$pagoId/ver-comprobante/';
  static String marcarComprobanteVisto(int pagoId) =>
      '$_payments/pagos/$pagoId/marcar-visto/';

  // ============================================================================
  // 14. ENDPOINTS: SUPER (FARMACIAS, TIENDAS)
  // ============================================================================

  static String get _super => '$apiUrl/super-categorias';

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
  // 15. CONSTANTES DEL SISTEMA
  // ============================================================================

  static const apiKeyMobile =
      'mobile_app_deliber_2025_aW7xK3pM9qR5tL2nV8jH4cF6gB1dY0sZ';
  static const apiKeyWeb =
      'web_admin_deliber_2025_XkJ9mP3nQ7wR2vL5zT8hF1cY4gN6sB0d';

  static String get currentApiKey => apiKeyMobile;

  // Timeouts y Reintentos
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
  static const sendTimeout = Duration(seconds: 30);
  static const maxRetries = 3;
  static const retryDelay = Duration(seconds: 2);

  // Verificación y Seguridad
  static const codigoLongitud = 6;
  static const codigoExpiracionMinutos = 15;
  static const maxIntentosVerificacion = 5;

  // Roles
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

  // HTTP Status Codes
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
  // 16. HELPERS Y UTILIDADES
  // ============================================================================

  static bool get isProduction => _isProduction;
  static bool get isDevelopment => !_isProduction;
  static bool get isHttps => baseUrl.startsWith('https');

  /// Procesa URLs de imágenes. Si viene relativa, le pega el Base URL.
  static String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('http') ? path : '$baseUrl$path';
  }

  /// Valida URLs HTTP/HTTPS
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Valida horarios de apertura/cierre
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

  /// Parseador de hora interno
  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Constructor de Query Strings limpio (sin nulos)
  static String buildQueryUrl(String base, Map<String, dynamic> params) {
    final filtered = params.entries.where(
      (e) => e.value != null && e.value.toString().isNotEmpty,
    );

    if (filtered.isEmpty) return base;

    final qs = filtered
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$base?$qs';
  }

  /// Debug de la configuración
  static void printDebug() {
    developer.log('---------------------------------------', name: 'ApiConfig');
    developer.log('API CONFIG - ESTADO', name: 'ApiConfig');
    developer.log(
      'Modo: ${_isProduction ? "PROD" : "DEV (Ngrok)"}',
      name: 'ApiConfig',
    );
    developer.log('URL: $baseUrl', name: 'ApiConfig');
    developer.log('---------------------------------------', name: 'ApiConfig');
  }
}
