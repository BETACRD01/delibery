// lib/screens/user/pantalla_inicio.dart

import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../config/routing/rutas.dart';
import '../../../providers/orders/proveedor_pedido.dart';
import '../../../services/core/toast_service.dart';
import '../../../theme/jp_theme.dart';
import '../courier/pantalla_courier.dart';
import 'pantalla_home.dart';
import '../orders/pantalla_mis_pedidos.dart';
import '../profile/pantalla_perfil.dart';

/// Pantalla principal que contiene el CupertinoTabBar y gestiona
/// la navegación entre las 4 pantallas principales de la aplicación
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  /// Índice de la pantalla actualmente seleccionada
  late int _indiceActual;

  /// Lista de pantallas que se mantienen en memoria
  final List<Widget> _pantallas = const [
    // ✅ CORREGIDO: Usamos PantallaHome (el contenido) en lugar de PantallaInicio (el contenedor)
    PantallaHome(),

    PantallaCourier(), // <-- REEMPLAZO: Envios en lugar de Super
    PantallaMisPedidos(),
    PantallaPerfil(),
  ];

  /// Navigator keys para cada tab - permite hacer pop a root en cada tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar con tab por defecto
    _indiceActual = 0;

    // Leer el tab inicial de los argumentos de la ruta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leerTabIndexDeArgumentos();
      _configurarNotificacionesPush();
    });
  }

  /// Lee el tabIndex de los argumentos de la ruta y actualiza el índice si es necesario
  void _leerTabIndexDeArgumentos() {
    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final tabIndex = args['tabIndex'] as int?;
      if (tabIndex != null && tabIndex >= 0 && tabIndex < _pantallas.length) {
        if (_indiceActual != tabIndex) {
          setState(() => _indiceActual = tabIndex);
          _refrescarPedidosSiEsTab(tabIndex);
        }
      }
    }
  }

  /// Configura el listener de Firebase Cloud Messaging para actualizaciones de pedidos
  void _configurarNotificacionesPush() {
    // Escuchar notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '[Push Cliente] Notificación recibida: ${message.data}',
        name: 'PantallaInicio',
      );
      _manejarPushPedido(message);
    });

    // Escuchar notificaciones cuando la app está en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        '[Push Cliente] App abierta desde notificación: ${message.data}',
        name: 'PantallaInicio',
      );
      _manejarPushPedido(message);
    });
  }

  /// Maneja las notificaciones push relacionadas con pedidos
  void _manejarPushPedido(RemoteMessage message) {
    if (!mounted) return;

    final data = Map<String, dynamic>.from(message.data);
    final tipoEvento = data['tipo_evento']?.toString();
    final accion = data['accion']?.toString();

    developer.log(
      '[Push Cliente] Procesando - tipo_evento: $tipoEvento, accion: $accion',
      name: 'PantallaInicio',
    );

    // CASO 1: Actualización de estado de pedido
    if (tipoEvento == 'pedido_actualizado' ||
        accion == 'actualizar_estado_pedido') {
      final pedidoIdRaw = data['pedido_id'];
      final nuevoEstado = data['nuevo_estado']?.toString();
      final estadoDisplay = data['estado_display']?.toString();
      final numeroPedido = data['numero_pedido']?.toString() ?? '';
      final repartidorNombre =
          data['repartidor_nombre']?.toString() ?? 'Repartidor';

      if (pedidoIdRaw != null && nuevoEstado != null && estadoDisplay != null) {
        final pedidoId = int.tryParse(pedidoIdRaw.toString());
        if (pedidoId != null) {
          _actualizarEstadoPedido(
            pedidoId: pedidoId,
            nuevoEstado: nuevoEstado,
            estadoDisplay: estadoDisplay,
          );

          // Mostrar SnackBar informativo al usuario
          _mostrarNotificacionEstado(
            numeroPedido: numeroPedido,
            nuevoEstado: nuevoEstado,
            repartidorNombre: repartidorNombre,
          );
        }
      }
    }
  }

  /// Actualiza el estado de un pedido en el provider
  void _actualizarEstadoPedido({
    required int pedidoId,
    required String nuevoEstado,
    required String estadoDisplay,
  }) {
    if (!mounted) return;

    final pedidoProvider = context.read<PedidoProvider>();
    pedidoProvider.actualizarEstadoPedidoPush(
      pedidoId: pedidoId,
      nuevoEstado: nuevoEstado,
      estadoDisplay: estadoDisplay,
    );

    developer.log(
      '[Push Cliente] Pedido #$pedidoId actualizado a: $estadoDisplay',
      name: 'PantallaInicio',
    );
  }

  /// Muestra un toast iOS informando al usuario del cambio de estado
  void _mostrarNotificacionEstado({
    required String numeroPedido,
    required String nuevoEstado,
    required String repartidorNombre,
  }) {
    if (!mounted) return;

    String mensaje;

    switch (nuevoEstado.toLowerCase()) {
      case 'asignado':
        mensaje = 'Pedido #$numeroPedido aceptado por $repartidorNombre';
        break;
      case 'en_camino':
        mensaje = 'Tu pedido #$numeroPedido está en camino';
        break;
      case 'entregado':
      case 'finalizado':
        mensaje = 'Pedido #$numeroPedido entregado con éxito';
        break;
      default:
        mensaje = 'Pedido #$numeroPedido actualizado';
    }

    // Usar ToastService con acción para ver pedidos
    ToastService().showSuccess(
      context,
      mensaje,
      actionLabel: 'Ver',
      onActionTap: () {
        // Cambiar a la pestaña de pedidos
        setState(() {
          _indiceActual = 2; // Índice de PantallaMisPedidos
        });
        _refrescarPedidosSiEsTab(2);
      },
      duration: const Duration(seconds: 4),
    );
  }

  void _refrescarPedidosSiEsTab(int indice) {
    if (indice == 2) {
      // Refrescar lista para mostrar pedidos nuevos al entrar
      context.read<PedidoProvider>().cargarPedidos(refresh: true);
    }
  }

  /// Cambia la pantalla activa cuando el usuario toca un item del navbar
  /// Primero hace pop a root en el tab actual, luego cambia al nuevo tab
  void _cambiarPantalla(int indice) {
    // Primero hacer pop a root en el tab actual (si hay pantallas apiladas)
    _popToRootOnTab(_indiceActual);

    if (_indiceActual != indice) {
      // También hacer pop a root en el tab destino (por si acaso quedó algo)
      _popToRootOnTab(indice);
      setState(() {
        _indiceActual = indice;
      });
      _refrescarPedidosSiEsTab(indice);
    } else if (indice == 2) {
      // Si ya está en pedidos y toca de nuevo, forzar recarga rápida
      _refrescarPedidosSiEsTab(indice);
    }
  }

  /// Hace pop a la pantalla root del tab especificado
  void _popToRootOnTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _navigatorKeys.length) {
      final navigator = _navigatorKeys[tabIndex].currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _indiceActual,
        onTap: _cambiarPantalla,
        backgroundColor: JPCupertinoColors.surface(context),
        activeColor: JPCupertinoColors.primary(context),
        inactiveColor: JPCupertinoColors.systemGrey(context),
        iconSize: 24.0,
        border: Border(
          top: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cube_box), // O usar paperplane
            activeIcon: Icon(CupertinoIcons.cube_box_fill),
            label: 'Envíos', // CAMBIO DE ETIQUETA
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bag),
            activeIcon: Icon(CupertinoIcons.bag_fill),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'Perfil',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          navigatorKey: _navigatorKeys[index],
          routes: Map.from(Rutas.obtenerRutas())..remove(Rutas.root),
          builder: (context) {
            return _pantallas[index];
          },
        );
      },
    );
  }
}
