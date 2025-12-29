// lib/config/rutas.dart
import 'package:flutter/material.dart';

import '../screens/admin/pantalla_dashboard.dart';
import '../screens/admin/screen/config/pantalla_cambiar_password.dart';
import '../screens/admin/screen/config/pantalla_resetear_password_usuario.dart';
import '../screens/admin/screen/pantalla_admin_proveedores.dart';
import '../screens/admin/screen/pantalla_admin_repartidores.dart';
import '../screens/admin/screen/pantalla_admin_usuarios.dart';
import '../screens/admin/ajustes/pantalla_gestion_categorias.dart';
import '../screens/admin/ajustes/pantalla_dispositivos.dart';
import '../screens/admin/screen/pantalla_ajustes.dart';
import '../screens/admin/screen/pantalla_config_envios.dart';
import '../screens/admin/screen/pantalla_crear_rifa.dart';
import '../screens/admin/screen/pantalla_rifas_admin.dart';
import '../screens/admin/screen/pantalla_solicitudes_rol.dart';
import '../screens/auth/pantalla_login.dart';
import '../screens/auth/pantalla_recuperar_password.dart';
import '../screens/auth/pantalla_registro.dart';
import '../screens/auth/recuperacion/pantalla_nueva_password.dart';
import '../screens/auth/recuperacion/pantalla_verificar_codigo.dart';
import '../screens/delivery/pantalla_datos_bancarios.dart';
import '../screens/delivery/pantalla_inicio_repartidor.dart';
import '../screens/delivery/configuracion/pantalla_configuracion_repartidor.dart';
import '../screens/delivery/ganancias/pantalla_ganancias_repartidor.dart';
import '../screens/delivery/perfil/pantalla_perfil_repartidor.dart';
import '../screens/delivery/soporte/pantalla_ayuda_soporte_repartidor.dart';
import '../screens/pantalla_router.dart';
import '../screens/ratings/pantalla_calificaciones_entidad.dart';
import '../screens/ratings/pantalla_mis_calificaciones.dart';
import '../screens/supplier/pantalla_inicio_proveedor.dart';
import '../screens/user/carrito/pantalla_carrito.dart';
import '../screens/user/catalogo/pantalla_categoria_detalle.dart';
import '../screens/user/catalogo/pantalla_menu_completo.dart';
import '../screens/user/catalogo/pantalla_notificaciones.dart';
import '../screens/user/catalogo/pantalla_producto_detalle.dart';
import '../screens/user/catalogo/pantalla_promocion_detalle.dart';
import '../screens/user/catalogo/pantalla_todas_categorias.dart';
import '../screens/user/pantalla_inicio.dart';
import '../screens/user/pedidos/pantalla_mis_pedidos.dart';
import '../screens/user/pedidos/pedido_detalle_screen.dart';
import '../screens/user/super/pantalla_detalle_restaurante.dart';
import '../screens/user/super/pantalla_super.dart';

class Rutas {
  Rutas._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get _nav => navigatorKey.currentState;

  static Future<T?> _pushNamedFallback<T>(String ruta, {Object? arguments}) {
    final nav = _nav;
    if (nav == null) return Future.value(null);
    return nav.pushNamed<T>(ruta, arguments: arguments);
  }

  static Future<T?> _pushReplacementNamedFallback<T>(
    String ruta, {
    Object? arguments,
  }) {
    final nav = _nav;
    if (nav == null) return Future.value(null);
    return nav.pushReplacementNamed<T, Object?>(ruta, arguments: arguments);
  }

  static Future<T?> _pushNamedAndRemoveUntilFallback<T>(
    String ruta, {
    bool rootNavigator = true,
  }) {
    final nav = _nav;
    if (nav == null) return Future.value(null);
    return nav.pushNamedAndRemoveUntil<T>(ruta, (_) => false);
  }

  // ============================================================================
  // RUTAS - AUTH
  // ============================================================================

  static const root = '/';
  static const router = '/';
  static const login = '/login';
  static const registro = '/registro';
  static const recuperarPassword = '/recuperar-password';
  static const verificarCodigo = '/verificar-codigo';
  static const nuevaPassword = '/nueva-password';

  // ============================================================================
  // RUTAS - USUARIO
  // ============================================================================

  static const inicio = '/inicio';
  static const perfil = '/perfil';
  static const configuracion = '/configuracion';
  static const super_ = '/super';
  static const restauranteDetalle = '/restaurante-detalle';
  static const categoriaDetalle = '/categoria-detalle';
  static const productoDetalle = '/producto-detalle';
  static const promocionDetalle = '/promocion-detalle';
  static const todasCategorias = '/todas-categorias';
  static const menuCompleto = '/menu-completo';
  static const carrito = '/carrito';
  static const notificaciones = '/notificaciones';
  static const ofertas = '/ofertas';
  static const misPedidos = '/mis-pedidos';
  static const pedidoDetalle = '/pedido-detalle';
  static const subirComprobante = '/user/subir-comprobante';
  static const ratingsMisCalificaciones = '/ratings/mis-calificaciones';
  static const ratingsEntidad = '/ratings/entidad';

  // ============================================================================
  // RUTAS - REPARTIDOR
  // ============================================================================

  static const repartidorHome = '/repartidor/home';
  static const repartidorPedidos = '/repartidor/pedidos';
  static const repartidorHistorial = '/repartidor/historial';
  static const perfilRepartidor = '/repartidor/perfil';
  static const verComprobante = '/delivery/ver-comprobante';
  static const datosBancarios = '/delivery/datos-bancarios';
  static const repartidorGanancias = '/delivery/ganancias';
  static const repartidorConfiguracion = '/delivery/configuracion';
  static const repartidorPerfilEditar = '/delivery/perfil';
  static const repartidorAyuda = '/delivery/ayuda';

  // ============================================================================
  // RUTAS - PROVEEDOR
  // ============================================================================

  static const proveedorHome = '/proveedor/home';
  static const proveedorProductos = '/proveedor/productos';
  static const proveedorPedidos = '/proveedor/pedidos';
  static const proveedorEstadisticas = '/proveedor/estadisticas';

  // ============================================================================
  // RUTAS - ADMIN
  // ============================================================================

  static const adminHome = '/admin/home';
  static const adminUsuarios = '/admin/usuarios';
  static const adminReportes = '/admin/reportes';
  static const adminSolicitudesRol = '/admin/solicitudes-rol';
  static const adminAjustes = '/admin/ajustes';
  static const String adminGestionCategorias = '/admin/ajustes/categorias';
  static const String adminDispositivos = '/admin/ajustes/dispositivos';
  static const adminCambiarPassword = '/admin/ajustes/cambiar-password';
  static const adminResetPasswordUsuario =
      '/admin/ajustes/reset-password-usuario';
  static const adminUsuariosGestion = '/admin/gestion-usuarios';
  static const adminProveedoresGestion = '/admin/gestion-proveedores';
  static const adminRepartidoresGestion = '/admin/gestion-repartidores';
  static const adminRifasGestion = '/admin/rifas';
  static const adminCrearRifa = '/admin/rifas/crear';
  static const adminEnviosConfig = '/admin/envios/configuracion';
  static const test = '/test';

  // ============================================================================
  // MAPA DE RUTAS
  // ============================================================================

  static Map<String, WidgetBuilder> obtenerRutas() => {
    // Auth
    root: (_) => const PantallaRouter(),
    login: (_) => const PantallaLogin(),
    registro: (_) => const PantallaRegistro(),
    recuperarPassword: (_) => const PantallaRecuperarPassword(),
    verificarCodigo: (_) => const PantallaVerificarCodigo(),
    nuevaPassword: (_) => const PantallaNuevaPassword(),

    // Usuario
    inicio: (_) => const PantallaInicio(),
    super_: (_) => const PantallaSuper(),
    restauranteDetalle: (_) => const PantallaDetalleRestaurante(),
    categoriaDetalle: (_) => const PantallaCategoriaDetalle(),
    productoDetalle: (_) => const PantallaProductoDetalle(),
    promocionDetalle: (_) => const PantallaPromocionDetalle(),
    todasCategorias: (_) => const PantallaTodasCategorias(),
    menuCompleto: (_) => const PantallaMenuCompleto(),
    notificaciones: (_) => const PantallaNotificaciones(),
    carrito: (_) => const PantallaCarrito(),
    misPedidos: (_) => const PantallaMisPedidos(),
    ratingsMisCalificaciones: (_) => const PantallaMisCalificaciones(),
    ratingsEntidad: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final type = args?['type'] as String?;
      final id = args?['id'] as int?;
      final nombre = args?['nombre'] as String? ?? 'Calificaciones';
      if (type == null || id == null) {
        return const PantallaMisCalificaciones(); // fallback vacío
      }
      return PantallaCalificacionesEntidad(
        entityType: type,
        entityId: id,
        entityNombre: nombre,
      );
    },

    // Repartidor
    repartidorHome: (_) => const PantallaInicioRepartidor(),
    datosBancarios: (_) => const PantallaDatosBancarios(),
    repartidorGanancias: (_) => const PantallaGananciasRepartidor(),
    repartidorConfiguracion: (_) => const PantallaConfiguracionRepartidor(),
    repartidorPerfilEditar: (_) => const PantallaEditarPerfilRepartidor(),
    repartidorAyuda: (_) => const PantallaAyudaSoporteRepartidor(),

    // Proveedor
    proveedorHome: (_) => const PantallaInicioProveedor(),

    // Admin
    adminHome: (_) => const PantallaDashboard(),
    adminSolicitudesRol: (_) => const PantallaSolicitudesRol(),
    adminAjustes: (_) => const PantallaAjustesAdmin(),
    adminGestionCategorias: (_) => const PantallaGestionCategorias(),
    adminDispositivos: (_) => const PantallaDispositivosConectados(),
    adminCambiarPassword: (_) => const PantallaCambiarPasswordAdmin(),
    adminResetPasswordUsuario: (_) => const PantallaResetearPasswordUsuario(),
    adminUsuariosGestion: (_) => const PantallaAdminUsuarios(),
    adminProveedoresGestion: (_) => const PantallaAdminProveedores(),
    adminRepartidoresGestion: (_) => const PantallaAdminRepartidores(),
    adminRifasGestion: (_) => const PantallaRifasAdmin(),
    adminCrearRifa: (_) => const PantallaCrearRifa(),
    adminEnviosConfig: (_) => const PantallaConfigEnviosAdmin(),
  };

  // ============================================================================
  // NAVEGACIÓN BASE
  // ============================================================================

  static Future<T?> irA<T>(BuildContext context, String ruta) => context.mounted
      ? Navigator.pushNamed<T>(context, ruta)
      : _pushNamedFallback<T>(ruta);

  static Future<T?> irAYLimpiar<T>(
    BuildContext context,
    String ruta, {
    bool rootNavigator = true,
  }) => context.mounted
      ? Navigator.of(
          context,
          rootNavigator: rootNavigator,
        ).pushNamedAndRemoveUntil<T>(ruta, (_) => false)
      : _pushNamedAndRemoveUntilFallback<T>(ruta, rootNavigator: rootNavigator);

  static Future<T?> reemplazarCon<T>(BuildContext context, String ruta) =>
      context.mounted
      ? Navigator.pushReplacementNamed<T, Object?>(context, ruta)
      : _pushReplacementNamedFallback<T>(ruta);

  static void volver(BuildContext context, [dynamic resultado]) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context, resultado);
      return;
    }
    if (_nav?.canPop() ?? false) {
      _nav?.pop(resultado);
    }
  }

  static bool puedeVolver(BuildContext context) =>
      context.mounted ? Navigator.canPop(context) : (_nav?.canPop() ?? false);

  static Future<T?> irAConArgumentos<T>(
    BuildContext context,
    String ruta,
    Object args,
  ) => context.mounted
      ? Navigator.pushNamed<T>(context, ruta, arguments: args)
      : _pushNamedFallback<T>(ruta, arguments: args);

  static T? obtenerArgumentos<T>(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments as T?;

  // ============================================================================
  // NAVEGACIÓN POR ROL
  // ============================================================================

  static Future<void> irARouter(BuildContext context) =>
      irAYLimpiar(context, router);

  static Future<void> irAHomePorRol(BuildContext context, [String? rol]) {
    if (rol == null || rol.isEmpty) return irARouter(context);

    final rutas = {
      'ADMINISTRADOR': adminHome,
      'REPARTIDOR': repartidorHome,
      'PROVEEDOR': proveedorHome,
      'USUARIO': inicio,
    };

    return irAYLimpiar(context, rutas[rol.toUpperCase()] ?? inicio);
  }

  // ============================================================================
  // NAVEGACIÓN ESPECÍFICA
  // ============================================================================

  static Future<void> irACategoriaDetalle(
    BuildContext context,
    dynamic categoria,
  ) => irAConArgumentos(context, categoriaDetalle, categoria);

  static Future<void> irAProductoDetalle(
    BuildContext context,
    dynamic producto,
  ) => irAConArgumentos(context, productoDetalle, producto);

  static Future<void> irAPromocionDetalle(
    BuildContext context,
    dynamic promocion,
  ) => irAConArgumentos(context, promocionDetalle, promocion);

  static Future<void> irARestauranteDetalle(
    BuildContext context,
    dynamic restaurante,
  ) => irAConArgumentos(context, restauranteDetalle, restaurante);

  static Future<void> irATodasCategorias(BuildContext context) =>
      irA(context, todasCategorias);
  static Future<void> irAMenuCompleto(BuildContext context) =>
      irA(context, menuCompleto);
  static Future<void> irACarrito(BuildContext context) => irA(context, carrito);
  static Future<void> irANotificaciones(BuildContext context) =>
      irA(context, notificaciones);
  static Future<void> irAOfertas(BuildContext context) => irA(context, ofertas);
  static Future<void> irASuper(BuildContext context) => irA(context, super_);
  static Future<void> irAMisPedidos(BuildContext context) =>
      irA(context, misPedidos);

  // ============================================================================
  // NAVEGACIÓN GLOBAL TAB BAR
  // ============================================================================

  /// Navega al inicio principal con el tab específico seleccionado.
  /// Limpia todo el stack de navegación para evitar acumulación de rutas.
  ///
  /// Tab indices:
  /// - 0: Inicio
  /// - 1: Super
  /// - 2: Pedidos
  /// - 3: Perfil
  static Future<void> irAInicioConTab(BuildContext context, int tabIndex) =>
      context.mounted
      ? Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          inicio,
          (_) => false,
          arguments: {'tabIndex': tabIndex},
        )
      : _pushNamedFallback(inicio, arguments: {'tabIndex': tabIndex});

  /// Navega a la pestaña Inicio (tab 0)
  static Future<void> irATabInicio(BuildContext context) =>
      irAInicioConTab(context, 0);

  /// Navega a la pestaña Super (tab 1)
  static Future<void> irATabSuper(BuildContext context) =>
      irAInicioConTab(context, 1);

  /// Navega a la pestaña Pedidos (tab 2)
  static Future<void> irATabPedidos(BuildContext context) =>
      irAInicioConTab(context, 2);

  /// Navega a la pestaña Perfil (tab 3)
  static Future<void> irATabPerfil(BuildContext context) =>
      irAInicioConTab(context, 3);

  static Future<void> irAPedidoDetalle(BuildContext context, int pedidoId) =>
      context.mounted
      ? Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PedidoDetalleScreen(pedidoId: pedidoId),
          ),
        )
      : _nav?.push(
              MaterialPageRoute(
                builder: (_) => PedidoDetalleScreen(pedidoId: pedidoId),
              ),
            ) ??
            Future.value(null);

  // Calificaciones
  static Future<void> irAMisCalificaciones(
    BuildContext context, {
    String? entityType,
    int? entityId,
  }) => context.mounted
      ? Navigator.pushNamed(
          context,
          ratingsMisCalificaciones,
          arguments: entityType != null && entityId != null
              ? {'type': entityType, 'id': entityId}
              : null,
        )
      : _pushNamedFallback(
          ratingsMisCalificaciones,
          arguments: entityType != null && entityId != null
              ? {'type': entityType, 'id': entityId}
              : null,
        );

  static Future<void> irACalificacionesEntidad(
    BuildContext context, {
    required String entityType,
    required int entityId,
    required String entityNombre,
  }) => context.mounted
      ? Navigator.pushNamed(
          context,
          ratingsEntidad,
          arguments: {
            'type': entityType,
            'id': entityId,
            'nombre': entityNombre,
          },
        )
      : _pushNamedFallback(
          ratingsEntidad,
          arguments: {
            'type': entityType,
            'id': entityId,
            'nombre': entityNombre,
          },
        );

  // ============================================================================
  // FLUJO RECUPERACIÓN PASSWORD
  // ============================================================================

  static Future<void> iniciarRecuperacionPassword(BuildContext context) =>
      irA(context, recuperarPassword);

  static Future<void> irAVerificarCodigo(BuildContext context, String email) =>
      irAConArgumentos(context, verificarCodigo, {'email': email});

  static Future<void> irANuevaPassword(
    BuildContext context, {
    required String email,
    required String codigo,
  }) => irAConArgumentos(context, nuevaPassword, {
    'email': email,
    'codigo': codigo,
  });

  static Future<void> completarRecuperacionPassword(BuildContext context) =>
      irAYLimpiar(context, login);

  // ============================================================================
  // TRANSICIONES PERSONALIZADAS
  // ============================================================================

  static Future<T?> irAConFade<T>(
    BuildContext context,
    Widget pantalla, {
    Duration duracion = const Duration(milliseconds: 300),
  }) => context.mounted
      ? Navigator.push<T>(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => pantalla,
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: duracion,
          ),
        )
      : _nav?.push<T>(
              PageRouteBuilder(
                pageBuilder: (_, _, _) => pantalla,
                transitionsBuilder: (_, anim, _, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: duracion,
              ),
            ) ??
            Future.value(null);

  static Future<T?> irAConSlide<T>(BuildContext context, Widget pantalla) =>
      context.mounted
      ? Navigator.push<T>(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => pantalla,
            transitionsBuilder: (_, anim, _, child) => SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
        )
      : _nav?.push<T>(
              PageRouteBuilder(
                pageBuilder: (_, _, _) => pantalla,
                transitionsBuilder: (_, anim, _, child) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
            ) ??
            Future.value(null);

  static Future<T?> irAConScale<T>(BuildContext context, Widget pantalla) =>
      context.mounted
      ? Navigator.push<T>(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => pantalla,
            transitionsBuilder: (_, anim, _, child) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: child,
            ),
          ),
        )
      : _nav?.push<T>(
              PageRouteBuilder(
                pageBuilder: (_, _, _) => pantalla,
                transitionsBuilder: (_, anim, _, child) => ScaleTransition(
                  scale: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                  child: child,
                ),
              ),
            ) ??
            Future.value(null);

  // ============================================================================
  // DIÁLOGOS Y MODALES
  // ============================================================================

  static Future<T?> mostrarDialogo<T>(
    BuildContext context,
    Widget dialogo, {
    bool barrierDismissible = true,
  }) => context.mounted
      ? showDialog<T>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (_) => dialogo,
        )
      : (navigatorKey.currentContext != null
            ? showDialog<T>(
                context: navigatorKey.currentContext!,
                barrierDismissible: barrierDismissible,
                builder: (_) => dialogo,
              )
            : Future.value(null));

  static Future<T?> mostrarBottomSheet<T>(
    BuildContext context,
    Widget contenido,
  ) => context.mounted
      ? showModalBottomSheet<T>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => contenido,
        )
      : (navigatorKey.currentContext != null
            ? showModalBottomSheet<T>(
                context: navigatorKey.currentContext!,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => contenido,
              )
            : Future.value(null));

  // ============================================================================
  // PERMISOS Y VALIDACIÓN
  // ============================================================================

  static const _rutasPublicas = {
    login,
    registro,
    recuperarPassword,
    verificarCodigo,
    nuevaPassword,
    test,
  };

  static const _rutasPorRol = {
    'USUARIO': {
      inicio,
      perfil,
      configuracion,
      super_,
      categoriaDetalle,
      productoDetalle,
      promocionDetalle,
      todasCategorias,
      menuCompleto,
      carrito,
      notificaciones,
      ofertas,
      misPedidos,
      pedidoDetalle,
    },
    'REPARTIDOR': {
      repartidorHome,
      repartidorPedidos,
      repartidorHistorial,
      perfil,
      configuracion,
    },
    'PROVEEDOR': {
      proveedorHome,
      proveedorProductos,
      proveedorPedidos,
      proveedorEstadisticas,
      perfil,
      configuracion,
    },
    'ADMINISTRADOR': {
      adminHome,
      adminUsuarios,
      adminReportes,
      adminSolicitudesRol,
      perfil,
      configuracion,
    },
  };

  static bool requiereAutenticacion(String ruta) =>
      !_rutasPublicas.contains(ruta);

  static bool tienePermiso(String rol, String ruta) =>
      _rutasPorRol[rol.toUpperCase()]?.contains(ruta) ?? false;
}
