// lib/screens/user/pantalla_inicio.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import 'inicio/pantalla_home.dart';
import 'super/pantalla_super.dart';
import 'pedidos/pantalla_mis_pedidos.dart';
import 'perfil/pantalla_perfil.dart';
import '../../providers/proveedor_pedido.dart';

/// Pantalla principal que contiene el BottomNavigationBar y gestiona
/// la navegación entre las 4 pantallas principales de la aplicación
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  /// Índice de la pantalla actualmente seleccionada
  int _indiceActual = 0;

  /// Lista de pantallas que se mantienen en memoria
  final List<Widget> _pantallas = const [
    // ✅ CORREGIDO: Usamos PantallaHome (el contenido) en lugar de PantallaInicio (el contenedor)
    PantallaHome(),

    PantallaSuper(),
    PantallaMisPedidos(),
    PantallaPerfil(),
  ];

  @override
  void initState() {
    super.initState();
    // Configurar listener de notificaciones push para clientes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configurarNotificacionesPush();
    });
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
    if (tipoEvento == 'pedido_actualizado' || accion == 'actualizar_estado_pedido') {
      final pedidoIdRaw = data['pedido_id'];
      final nuevoEstado = data['nuevo_estado']?.toString();
      final estadoDisplay = data['estado_display']?.toString();
      final numeroPedido = data['numero_pedido']?.toString() ?? '';
      final repartidorNombre = data['repartidor_nombre']?.toString() ?? 'Repartidor';

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

  /// Muestra un SnackBar informando al usuario del cambio de estado
  void _mostrarNotificacionEstado({
    required String numeroPedido,
    required String nuevoEstado,
    required String repartidorNombre,
  }) {
    if (!mounted) return;

    String mensaje;
    IconData icono;
    Color color;

    switch (nuevoEstado.toLowerCase()) {
      case 'asignado':
        mensaje = '¡Pedido #$numeroPedido aceptado por $repartidorNombre!';
        icono = Icons.check_circle;
        color = Colors.green;
        break;
      case 'en_camino':
        mensaje = '¡Tu pedido #$numeroPedido está en camino!';
        icono = Icons.local_shipping;
        color = Colors.blue;
        break;
      case 'entregado':
      case 'finalizado':
        mensaje = '¡Pedido #$numeroPedido entregado con éxito!';
        icono = Icons.done_all;
        color = Colors.green;
        break;
      default:
        mensaje = 'Pedido #$numeroPedido actualizado';
        icono = Icons.info;
        color = Colors.orange;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            // Cambiar a la pestaña de pedidos
            setState(() {
              _indiceActual = 2; // Índice de PantallaMisPedidos
            });
          },
        ),
      ),
    );
  }

  /// Cambia la pantalla activa cuando el usuario toca un item del navbar
  void _cambiarPantalla(int indice) {
    if (_indiceActual != indice) {
      setState(() {
        _indiceActual = indice;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene el estado de los widgets (scroll, datos cargados, etc.)
      body: IndexedStack(
        index: _indiceActual, 
        children: _pantallas
      ),

      // Barra de navegación inferior
      bottomNavigationBar: _construirBottomNavBar(context),
    );
  }

  /// Construye el BottomNavigationBar con los 4 items principales
  Widget _construirBottomNavBar(BuildContext context) {
    final colorPrimario = Theme.of(context).primaryColor;

    return Container(
      // Sombra superior para separar visualmente el contenido del navbar
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        // Configuración general
        currentIndex: _indiceActual,
        onTap: _cambiarPantalla,
        type: BottomNavigationBarType.fixed,

        // Colores
        selectedItemColor: colorPrimario,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,

        // Estilo de los labels
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

        // Elevación
        elevation: 0, // Usamos la sombra del Container

        // Items de navegación
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
            tooltip: 'Ir a Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Super',
            tooltip: 'JP Super',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Pedidos',
            tooltip: 'Ver mis pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
            tooltip: 'Ver perfil',
          ),
        ],
      ),
    );
  }
}