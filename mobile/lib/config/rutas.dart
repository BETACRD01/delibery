// lib/config/rutas.dart

import 'package:flutter/material.dart';
// Imports de pantallas
import '../screens/auth/pantalla_login.dart';
import '../screens/auth/pantalla_registro.dart';
import '../screens/auth/pantalla_recuperar_password.dart';
import '../screens/auth/recuperacion/pantalla_verificar_codigo.dart';
import '../screens/auth/recuperacion/pantalla_nueva_password.dart';
import '../screens/pantalla_router.dart';
import '../screens/user/pantalla_inicio.dart';
import '../screens/user/super/pantalla_super.dart';
import '../screens/delivery/pantalla_inicio_repartidor.dart';
import '../screens/supplier/pantalla_inicio_proveedor.dart';
import '../screens/admin/pantalla_dashboard.dart';
import '../screens/admin/screen/pantalla_solicitudes_rol.dart';
import '../screens/admin/screen/pantalla_ajustes.dart';
import '../screens/admin/screen/config/pantalla_cambiar_password.dart';
import '../screens/admin/screen/config/pantalla_resetear_password_usuario.dart';
import '../screens/admin/screen/pantalla_admin_usuarios.dart';
import '../screens/admin/screen/pantalla_admin_proveedores.dart';
import '../screens/admin/screen/pantalla_admin_repartidores.dart';
import '../screens/admin/screen/pantalla_crear_rifa.dart';
import '../screens/admin/screen/pantalla_rifas_admin.dart';
// IMPORTS - CATALOGO
import '../screens/user/catalogo/pantalla_categoria_detalle.dart';
import '../screens/user/catalogo/pantalla_producto_detalle.dart';
import '../screens/user/catalogo/pantalla_promocion_detalle.dart';
import '../screens/user/catalogo/pantalla_todas_categorias.dart';
import '../screens/user/catalogo/pantalla_menu_completo.dart';
// IMPORTS - RESTAURANTES
import '../screens/user/super/pantalla_detalle_restaurante.dart';
// IMPORT - NOTIFICACIONES
import '../screens/user/catalogo/pantalla_notificaciones.dart';
// IMPORT - CARRITO
import '../screens/user/carrito/pantalla_carrito.dart';
// IMPORTS - PEDIDOS
import '../screens/user/pedidos/pantalla_mis_pedidos.dart';
import '../screens/user/pedidos/pedido_detalle_screen.dart';
// IMPORTS - DELIVERY
import '../screens/delivery/pantalla_datos_bancarios.dart';

class Rutas {
  // ---------------------------------------------------------------------------
  // CONSTANTES DE RUTAS
  // ---------------------------------------------------------------------------

  // ✅ NUEVA RUTA: Raíz
  static const String root = '/';
  // Unificamos router en la raíz para evitar dobles pushes (/ y /router)
  static const String router = '/';
  // Auth
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperarPassword = '/recuperar-password';
  static const String verificarCodigo = '/verificar-codigo';
  static const String nuevaPassword = '/nueva-password';

  // Router y Core
  static const String inicio = '/inicio';
  static const String perfil = '/perfil';
  static const String configuracion = '/configuracion';
  // RUTAS - SUPER
  static const String super_ = '/super';
  static const String restauranteDetalle = '/restaurante-detalle';
  // RUTAS - CATALOGO USUARIO
  static const String categoriaDetalle = '/categoria-detalle';
  static const String productoDetalle = '/producto-detalle';
  static const String promocionDetalle = '/promocion-detalle';
  static const String todasCategorias = '/todas-categorias';
  static const String menuCompleto = '/menu-completo';
  static const String carrito = '/carrito';
  static const String notificaciones = '/notificaciones';
  static const String ofertas = '/ofertas';

  // RUTAS - PEDIDOS
  static const String misPedidos = '/mis-pedidos';
  static const String pedidoDetalle = '/pedido-detalle';
  static const String subirComprobante = '/user/subir-comprobante';
  // Repartidor
  static const String repartidorHome = '/repartidor/home';
  static const String repartidorPedidos = '/repartidor/pedidos';
  static const String repartidorHistorial = '/repartidor/historial';
  static const String perfilRepartidor = '/repartidor/perfil';
  static const String verComprobante = '/delivery/ver-comprobante';
  static const String datosBancarios = '/delivery/datos-bancarios';
  // Proveedor
  static const String proveedorHome = '/proveedor/home';
  static const String proveedorProductos = '/proveedor/productos';
  static const String proveedorPedidos = '/proveedor/pedidos';
  static const String proveedorEstadisticas = '/proveedor/estadisticas';
  // Admin
  static const String adminHome = '/admin/home';
  static const String adminUsuarios = '/admin/usuarios';
  static const String adminReportes = '/admin/reportes';
  static const String adminSolicitudesRol = '/admin/solicitudes-rol';
  static const String adminAjustes = '/admin/ajustes';
  static const String adminCambiarPassword = '/admin/ajustes/cambiar-password';
  static const String adminResetPasswordUsuario = '/admin/ajustes/reset-password-usuario';
  static const String adminUsuariosGestion = '/admin/gestion-usuarios';
  static const String adminProveedoresGestion = '/admin/gestion-proveedores';
  static const String adminRepartidoresGestion = '/admin/gestion-repartidores';
  static const String adminRifasGestion = '/admin/rifas';
  static const String adminCrearRifa = '/admin/rifas/crear';
  // Test
  static const String test = '/test';

  // ---------------------------------------------------------------------------
  // MAPA DE RUTAS
  // ---------------------------------------------------------------------------
  static Map<String, WidgetBuilder> obtenerRutas() {
    return {
      // ✅ MAPEO RAÍZ: Permite navegar a '/' para reiniciar el router
      root: (_) => const PantallaRouter(),
      // Auth
      login: (_) => const PantallaLogin(),
      registro: (_) => const PantallaRegistro(),
      recuperarPassword: (_) => const PantallaRecuperarPassword(),
      verificarCodigo: (_) => const PantallaVerificarCodigo(),
      nuevaPassword: (_) => const PantallaNuevaPassword(),

      // Router y Core
      inicio: (_) => const PantallaInicio(),

      // RUTAS - SUPER
      super_: (_) => const PantallaSuper(),
      restauranteDetalle: (_) => const PantallaDetalleRestaurante(),

      // RUTAS - CATALOGO
      categoriaDetalle: (_) => const PantallaCategoriaDetalle(),
      productoDetalle: (_) => const PantallaProductoDetalle(),
      promocionDetalle: (_) => const PantallaPromocionDetalle(),
      todasCategorias: (_) => const PantallaTodasCategorias(),
      menuCompleto: (_) => const PantallaMenuCompleto(),
      notificaciones: (_) => const PantallaNotificaciones(),
      carrito: (_) => const PantallaCarrito(),
      
      // RUTAS - PEDIDOS
      misPedidos: (_) => const PantallaMisPedidos(),
      datosBancarios: (_) => const PantallaDatosBancarios(),

      // Roles
      repartidorHome: (_) => const PantallaInicioRepartidor(),
      proveedorHome: (_) => const PantallaInicioProveedor(),
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
  }

  // ---------------------------------------------------------------------------
  // METODOS DE NAVEGACION BASE
  // ---------------------------------------------------------------------------

  static Future<T?> irA<T>(BuildContext context, String ruta) {
    return Navigator.pushNamed<T>(context, ruta);
  }

  static Future<T?> irAYLimpiar<T>(BuildContext context, String ruta) {
    return Navigator.pushNamedAndRemoveUntil<T>(context, ruta, (_) => false);
  }

  static Future<T?> reemplazarCon<T>(BuildContext context, String ruta) {
    return Navigator.pushReplacementNamed<T, Object?>(context, ruta);
  }

  static void volver(BuildContext context, [dynamic resultado]) {
    if (Navigator.canPop(context)) Navigator.pop(context, resultado);
  }

  static bool puedeVolver(BuildContext context) {
    return Navigator.canPop(context);
  }

  // ---------------------------------------------------------------------------
  // NAVEGACION INTELIGENTE (ROLES)
  // ---------------------------------------------------------------------------

  static Future<void> irARouter(BuildContext context) {
    return irAYLimpiar(context, router);
  }

  static Future<void> irAHomePorRol(BuildContext context, [String? rol]) {
    if (rol == null || rol.isEmpty) {
      return irARouter(context);
    }

    String ruta;
    switch (rol.toUpperCase()) {
      case 'ADMINISTRADOR':
        ruta = adminHome;
        break;
      case 'REPARTIDOR':
        ruta = repartidorHome;
        break;
      case 'PROVEEDOR':
        ruta = proveedorHome;
        break;
      case 'USUARIO':
      default:
        ruta = inicio;
        break;
    }
    return irAYLimpiar(context, ruta);
  }

  // ---------------------------------------------------------------------------
  // ARGUMENTOS
  // ---------------------------------------------------------------------------

  static Future<T?> irAConArgumentos<T>(BuildContext context, String ruta, Object args) {
    return Navigator.pushNamed<T>(context, ruta, arguments: args);
  }

  static T? obtenerArgumentos<T>(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as T?;
  }

  // ---------------------------------------------------------------------------
  // NAVEGACION ESPECIFICA - CATALOGO
  // ---------------------------------------------------------------------------

  static Future<void> irACategoriaDetalle(BuildContext context, dynamic categoria) {
    return irAConArgumentos(context, categoriaDetalle, categoria);
  }

  static Future<void> irAProductoDetalle(BuildContext context, dynamic producto) {
    return irAConArgumentos(context, productoDetalle, producto);
  }

  static Future<void> irAPromocionDetalle(BuildContext context, dynamic promocion) {
    return irAConArgumentos(context, promocionDetalle, promocion);
  }

  static Future<void> irARestauranteDetalle(BuildContext context, dynamic restaurante) {
    return irAConArgumentos(context, restauranteDetalle, restaurante);
  }

  static Future<void> irATodasCategorias(BuildContext context) {
    return irA(context, todasCategorias);
  }

  static Future<void> irAMenuCompleto(BuildContext context) {
    return irA(context, menuCompleto);
  }

  static Future<void> irACarrito(BuildContext context) {
    return irA(context, carrito);
  }

  static Future<void> irANotificaciones(BuildContext context) {
    return irA(context, notificaciones);
  }

  static Future<void> irAOfertas(BuildContext context) {
    return irA(context, ofertas);
  }

  // ---------------------------------------------------------------------------
  // NAVEGACION ESPECIFICA - SUPER
  // ---------------------------------------------------------------------------

  static Future<void> irASuper(BuildContext context) {
    return irA(context, super_);
  }

  // ---------------------------------------------------------------------------
  // NAVEGACION ESPECIFICA - PEDIDOS
  // ---------------------------------------------------------------------------

  static Future<void> irAMisPedidos(BuildContext context) {
    return irA(context, misPedidos);
  }

  static Future<void> irAPedidoDetalle(BuildContext context, int pedidoId) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PedidoDetalleScreen(pedidoId: pedidoId),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FLUJO RECUPERACION PASSWORD
  // ---------------------------------------------------------------------------

  static Future<void> iniciarRecuperacionPassword(BuildContext context) {
    return irA(context, recuperarPassword);
  }

  static Future<void> irAVerificarCodigo(BuildContext context, String email) {
    return irAConArgumentos(context, verificarCodigo, {'email': email});
  }

  static Future<void> irANuevaPassword(BuildContext context, {required String email, required String codigo}) {
    return irAConArgumentos(context, nuevaPassword, {'email': email, 'codigo': codigo});
  }

  static Future<void> completarRecuperacionPassword(BuildContext context) {
    return irAYLimpiar(context, login);
  }

  // ---------------------------------------------------------------------------
  // TRANSICIONES PERSONALIZADAS
  // ---------------------------------------------------------------------------

  static Future<T?> irAConFade<T>(BuildContext context, Widget pantalla, {Duration duracion = const Duration(milliseconds: 300)}) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => pantalla,
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: duracion,
      ),
    );
  }

  static Future<T?> irAConSlide<T>(BuildContext context, Widget pantalla) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => pantalla,
        transitionsBuilder: (_, anim, _, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim),
            child: child,
          );
        },
      ),
    );
  }

  static Future<T?> irAConScale<T>(BuildContext context, Widget pantalla) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => pantalla,
        transitionsBuilder: (_, anim, _, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGOS Y MODALES
  // ---------------------------------------------------------------------------

  static Future<T?> mostrarDialogo<T>(BuildContext context, Widget dialogo, {bool barrierDismissible = true}) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => dialogo,
    );
  }

  static Future<T?> mostrarBottomSheet<T>(BuildContext context, Widget contenido) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => contenido,
    );
  }

  // ---------------------------------------------------------------------------
  // VALIDACION Y PERMISOS
  // ---------------------------------------------------------------------------

  static const List<String> rutasPublicas = [
    login, registro, recuperarPassword, verificarCodigo, nuevaPassword, test
  ];

  static const List<String> rutasUsuario = [
    inicio, perfil, configuracion, super_,
    categoriaDetalle, productoDetalle, promocionDetalle,
    todasCategorias, menuCompleto, carrito, notificaciones, ofertas,
    misPedidos, pedidoDetalle
  ];
  
  static const List<String> rutasRepartidor = [
    repartidorHome, repartidorPedidos, repartidorHistorial, perfil, configuracion
  ];
  
  static const List<String> rutasProveedor = [
    proveedorHome, proveedorProductos, proveedorPedidos, proveedorEstadisticas, perfil, configuracion
  ];
  
  static const List<String> rutasAdmin = [
    adminHome, adminUsuarios, adminReportes, adminSolicitudesRol, perfil, configuracion
  ];

  static bool requiereAutenticacion(String ruta) {
    return !rutasPublicas.contains(ruta);
  }

  static bool tienePermiso(String rol, String ruta) {
    switch (rol.toUpperCase()) {
      case 'ADMINISTRADOR':
        return rutasAdmin.contains(ruta);
      case 'REPARTIDOR':
        return rutasRepartidor.contains(ruta);
      case 'PROVEEDOR':
        return rutasProveedor.contains(ruta);
      case 'USUARIO':
        return rutasUsuario.contains(ruta);
      default:
        return false;
    }
  }
}
