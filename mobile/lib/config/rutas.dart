// lib/config/rutas.dart
import 'package:flutter/material.dart';

import '../screens/auth/pantalla_login.dart';
import '../screens/auth/pantalla_registro.dart';
import '../screens/auth/pantalla_recuperar_password.dart';
import '../screens/auth/recuperacion/pantalla_verificar_codigo.dart';
import '../screens/auth/recuperacion/pantalla_nueva_password.dart';
import '../screens/pantalla_router.dart';
import '../screens/user/pantalla_inicio.dart';
import '../screens/user/super/pantalla_super.dart';
import '../screens/user/super/pantalla_detalle_restaurante.dart';
import '../screens/user/catalogo/pantalla_categoria_detalle.dart';
import '../screens/user/catalogo/pantalla_producto_detalle.dart';
import '../screens/user/catalogo/pantalla_promocion_detalle.dart';
import '../screens/user/catalogo/pantalla_todas_categorias.dart';
import '../screens/user/catalogo/pantalla_menu_completo.dart';
import '../screens/user/catalogo/pantalla_notificaciones.dart';
import '../screens/user/carrito/pantalla_carrito.dart';
import '../screens/user/pedidos/pantalla_mis_pedidos.dart';
import '../screens/user/pedidos/pedido_detalle_screen.dart';
import '../screens/delivery/pantalla_inicio_repartidor.dart';
import '../screens/delivery/pantalla_datos_bancarios.dart';
import '../screens/supplier/pantalla_inicio_proveedor.dart';
import '../screens/admin/pantalla_dashboard.dart';
import '../screens/admin/screen/pantalla_solicitudes_rol.dart';
import '../screens/admin/screen/pantalla_ajustes.dart';
import '../screens/admin/screen/pantalla_admin_usuarios.dart';
import '../screens/admin/screen/pantalla_admin_proveedores.dart';
import '../screens/admin/screen/pantalla_admin_repartidores.dart';
import '../screens/admin/screen/pantalla_crear_rifa.dart';
import '../screens/admin/screen/pantalla_rifas_admin.dart';
import '../screens/admin/screen/config/pantalla_cambiar_password.dart';
import '../screens/admin/screen/config/pantalla_resetear_password_usuario.dart';

class Rutas {
  Rutas._();

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

  // ============================================================================
  // RUTAS - REPARTIDOR
  // ============================================================================

  static const repartidorHome = '/repartidor/home';
  static const repartidorPedidos = '/repartidor/pedidos';
  static const repartidorHistorial = '/repartidor/historial';
  static const perfilRepartidor = '/repartidor/perfil';
  static const verComprobante = '/delivery/ver-comprobante';
  static const datosBancarios = '/delivery/datos-bancarios';

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
  static const adminCambiarPassword = '/admin/ajustes/cambiar-password';
  static const adminResetPasswordUsuario =
      '/admin/ajustes/reset-password-usuario';
  static const adminUsuariosGestion = '/admin/gestion-usuarios';
  static const adminProveedoresGestion = '/admin/gestion-proveedores';
  static const adminRepartidoresGestion = '/admin/gestion-repartidores';
  static const adminRifasGestion = '/admin/rifas';
  static const adminCrearRifa = '/admin/rifas/crear';
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

    // Repartidor
    repartidorHome: (_) => const PantallaInicioRepartidor(),
    datosBancarios: (_) => const PantallaDatosBancarios(),

    // Proveedor
    proveedorHome: (_) => const PantallaInicioProveedor(),

    // Admin
    adminHome: (_) => const PantallaDashboard(),
    adminSolicitudesRol: (_) => const PantallaSolicitudesRol(),
    adminAjustes: (_) => const PantallaAjustesAdmin(),
    adminCambiarPassword: (_) => const PantallaCambiarPasswordAdmin(),
    adminResetPasswordUsuario: (_) => const PantallaResetearPasswordUsuario(),
    adminUsuariosGestion: (_) => const PantallaAdminUsuarios(),
    adminProveedoresGestion: (_) => const PantallaAdminProveedores(),
    adminRepartidoresGestion: (_) => const PantallaAdminRepartidores(),
    adminRifasGestion: (_) => const PantallaRifasAdmin(),
    adminCrearRifa: (_) => const PantallaCrearRifa(),
  };

  // ============================================================================
  // NAVEGACIÓN BASE
  // ============================================================================

  static Future<T?> irA<T>(BuildContext context, String ruta) =>
      Navigator.pushNamed<T>(context, ruta);

  static Future<T?> irAYLimpiar<T>(BuildContext context, String ruta) =>
      Navigator.pushNamedAndRemoveUntil<T>(context, ruta, (_) => false);

  static Future<T?> reemplazarCon<T>(BuildContext context, String ruta) =>
      Navigator.pushReplacementNamed<T, Object?>(context, ruta);

  static void volver(BuildContext context, [dynamic resultado]) {
    if (Navigator.canPop(context)) Navigator.pop(context, resultado);
  }

  static bool puedeVolver(BuildContext context) => Navigator.canPop(context);

  static Future<T?> irAConArgumentos<T>(
    BuildContext context,
    String ruta,
    Object args,
  ) => Navigator.pushNamed<T>(context, ruta, arguments: args);

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

  static Future<void> irAPedidoDetalle(BuildContext context, int pedidoId) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PedidoDetalleScreen(pedidoId: pedidoId),
        ),
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
  }) => Navigator.push<T>(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => pantalla,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: duracion,
    ),
  );

  static Future<T?> irAConSlide<T>(BuildContext context, Widget pantalla) =>
      Navigator.push<T>(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => pantalla,
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
      );

  static Future<T?> irAConScale<T>(BuildContext context, Widget pantalla) =>
      Navigator.push<T>(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => pantalla,
          transitionsBuilder: (_, anim, __, child) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          ),
        ),
      );

  // ============================================================================
  // DIÁLOGOS Y MODALES
  // ============================================================================

  static Future<T?> mostrarDialogo<T>(
    BuildContext context,
    Widget dialogo, {
    bool barrierDismissible = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => dialogo,
  );

  static Future<T?> mostrarBottomSheet<T>(
    BuildContext context,
    Widget contenido,
  ) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => contenido,
  );

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
