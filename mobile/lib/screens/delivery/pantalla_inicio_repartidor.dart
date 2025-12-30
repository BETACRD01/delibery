// lib/screens/delivery/pantalla_inicio_repartidor.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/rutas.dart';
import '../../models/repartidor.dart';
import '../../models/pedido_repartidor.dart';
import '../../models/entrega_historial.dart';
import '../../widgets/mapa_pedidos_widget.dart';
import '../../controllers/delivery/repartidor_controller.dart';
import 'widgets/lista_vacia_widget.dart';
import 'widgets/card_encargo_disponible.dart';
import 'widgets/card_encargo_activo.dart';
import '../../services/auth/session_cleanup.dart';
import '../../widgets/ratings/dialogo_calificar_cliente.dart';
import '../../widgets/role/role_selector_modal.dart';
import 'pantalla_ver_comprobante.dart';

/// ✅ REFACTORIZADA: Pantalla principal para REPARTIDORES (iOS Native Style)
/// UI limpia estilo iPhone que delega toda la lógica al controller
class PantallaInicioRepartidor extends StatefulWidget {
  const PantallaInicioRepartidor({super.key});

  @override
  State<PantallaInicioRepartidor> createState() =>
      _PantallaInicioRepartidorState();
}

class _PantallaInicioRepartidorState extends State<PantallaInicioRepartidor> {
  // ============================================
  // CONTROLLER Y TABS
  // ============================================
  late final RepartidorController _controller;
  int? _ultimoPedidoNuevo;
  Map<String, dynamic>? _ultimoPayload;

  // ============================================
  // COLORES iOS STYLE
  // ============================================
  static const Color _accent = Color(0xFF0CB7F2); // Celeste corporativo
  static const Color _success = Color(0xFF34C759);
  static const Color _rojo = Color(0xFFFF3B30);

  // Dynamic Colors
  Color get _surface =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);
  Color get _cardBg =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
  Color get _cardBorder => CupertinoColors.separator.resolveFrom(context);
  Color get _textPrimary => CupertinoColors.label.resolveFrom(context);
  Color get _textSecondary =>
      CupertinoColors.secondaryLabel.resolveFrom(context);
  Color get _shadowColor =>
      CupertinoTheme.brightnessOf(context) == Brightness.dark
      ? Colors.transparent
      : const Color(0x1A000000);

  // ============================================
  // CICLO DE VIDA
  // ============================================

  @override
  void initState() {
    super.initState();
    _controller = RepartidorController();
    _inicializar();
    _suscribirPushPedidos();
  }

  @override
  void dispose() {
    _pedidoSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ============================================
  // INICIALIZACIÓN
  // ============================================

  Future<void> _inicializar() async {
    final accesoValido = await _controller.verificarAccesoYCargarDatos();

    if (!mounted) return;

    if (!accesoValido) {
      _manejarAccesoDenegado();
      return;
    }

    // Cargar pendientes y pedidos activos iniciales en paralelo
    await Future.wait([
      _controller.cargarPedidosDisponibles(),
      _controller.cargarPedidosActivos(),
    ]);

    // Iniciar smart polling automático
    _controller.startSmartPolling();
  }

  // ============================================
  // NOTIFICACIONES PUSH (NUEVO PEDIDO)
  // ============================================

  StreamSubscription<RemoteMessage>? _pedidoSub;

  void _suscribirPushPedidos() {
    _pedidoSub = FirebaseMessaging.onMessage.listen(_manejarPushPedido);
    // Si la app se abrió desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_manejarPushPedido);
  }

  void _manejarPushPedido(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    if (data.isEmpty) {
      debugPrint('[Push Repartidor] Sin data útil en el mensaje, se ignora');
      return;
    }

    final tipoEvento = data['tipo_evento']?.toString();
    final accion = data['accion']?.toString();

    // CASO 1: Pedido aceptado por otro repartidor - removerlo de la lista
    if (tipoEvento == 'pedido_aceptado' ||
        accion == 'remover_pedido_disponible') {
      final pedidoIdRaw = data['pedido_id'];
      if (pedidoIdRaw != null) {
        final pedidoId = int.tryParse(pedidoIdRaw.toString());
        if (pedidoId != null) {
          _removerPedidoDisponible(pedidoId);
        }
      }
      return;
    }

    // CASO 2: Nuevo pedido disponible
    final tipo = (data['tipo'] ?? data['type'] ?? accion ?? tipoEvento)
        ?.toString();
    final pedidoIdRaw =
        data['pedido_id'] ?? data['pedido'] ?? data['order_id'] ?? data['id'];
    if (pedidoIdRaw == null) return;

    // Solo atender eventos de nuevo pedido para repartidor
    const tiposValidos = {'nuevo_pedido', 'pedido_disponible', 'new_order'};
    final esRepartidor =
        tipoEvento == 'repartidor' || accion == 'ver_pedido_disponible';
    if (!esRepartidor && tipo != null && !tiposValidos.contains(tipo)) return;

    final pedidoId = int.tryParse(pedidoIdRaw.toString());
    if (pedidoId == null) return;

    if (!mounted) return;

    setState(() {
      _ultimoPedidoNuevo = pedidoId;
      _ultimoPayload = data;
    });

    // Notificación iOS estilo banner con animación
    _mostrarNotificacionNuevoPedido(pedidoId, data);

    // Diálogo de detalle después de un momento
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _mostrarDialogoNuevoPedido(pedidoId, data);
      }
    });
  }

  /// Remueve un pedido de la lista de disponibles cuando otro repartidor lo acepta
  void _removerPedidoDisponible(int pedidoId) {
    if (!mounted) return;

    // Remover del controller
    _controller.removerPedidoDisponible(pedidoId);

    debugPrint(
      '[Push Repartidor] Pedido #$pedidoId removido - fue aceptado por otro repartidor',
    );
  }

  /// Muestra una notificación estilo iOS banner animada
  void _mostrarNotificacionNuevoPedido(
    int pedidoId,
    Map<String, dynamic> data,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificacionBanner(
        pedidoId: pedidoId,
        data: data,
        onTap: () {
          overlayEntry.remove();
          _mostrarDialogoNuevoPedido(pedidoId, data);
        },
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _mostrarDialogoNuevoPedido(
    int pedidoId,
    Map<String, dynamic> data,
  ) async {
    final cliente = data['cliente']?.toString() ?? 'Cliente';
    final total = data['total']?.toString() ?? '—';

    await showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.bell_fill, color: _accent, size: 22),
            SizedBox(width: 8),
            Text('Nuevo Pedido'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedido #$pedidoId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('Cliente: $cliente'),
              if (total != '—') ...[
                const SizedBox(height: 6),
                Text(
                  'Total: $total',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '¿Quieres aceptar este pedido?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            isDestructiveAction: true,
            child: const Text('Ignorar'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _aceptarPedido(pedidoId);
            },
            isDefaultAction: true,
            child: const Text('Aceptar Pedido'),
          ),
        ],
      ),
    );
  }

  Future<void> _aceptarPedido(int pedidoId) async {
    try {
      // El controller ahora devuelve el detalle completo del pedido con datos sensibles
      final detallePedido = await _controller.aceptarPedido(pedidoId);
      if (!mounted) return;

      final exito = detallePedido != null;

      if (exito) {
        setState(() {
          if (_ultimoPedidoNuevo == pedidoId) {
            _ultimoPedidoNuevo = null;
            _ultimoPayload = null;
          }
        });

        // Mostrar notificación de éxito estilo iOS
        if (!mounted) return;
        _mostrarNotificacionExito(
          'Pedido Aceptado',
          'Pedido #${detallePedido.numeroPedido}\n'
              'Cliente: ${detallePedido.cliente.nombre}\n'
              'Destino: ${detallePedido.direccionEntrega}',
        );

        // Recargar datos
        await _controller.cargarDatos();
      } else {
        final mensajeError =
            _controller.error ?? 'No se pudo aceptar el pedido';
        _mostrarNotificacionError(mensajeError);
      }
    } catch (e) {
      if (!mounted) return;
      final mensajeError = _controller.error ?? 'Error aceptando el pedido';
      _mostrarNotificacionError(mensajeError);
    }
  }

  void _mostrarNotificacionExito(String titulo, String mensaje) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: _success,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            isDefaultAction: true,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarNotificacionError(String mensaje) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.xmark_circle_fill, color: _rojo, size: 22),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            isDefaultAction: true,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _manejarAccesoDenegado() {
    final error = _controller.error;
    final rolIncorrecto = error?.contains('Rol incorrecto') ?? false;

    if (rolIncorrecto) {
      _mostrarDialogoAccesoDenegado();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Rutas.irAYLimpiar(context, Rutas.login);
      });
    }
  }

  Future<void> _mostrarDialogoAccesoDenegado() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.block, color: _rojo),
                SizedBox(width: 12),
                Text('Acceso Denegado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta sección es exclusiva para repartidores.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(_controller.error ?? ''),
                const SizedBox(height: 8),
                const Text(
                  'Serás redirigido a tu pantalla correspondiente.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Rutas.irAYLimpiar(context, Rutas.login);
      }
    });
  }

  // ============================================
  // ACCIONES
  // ============================================

  void _abrirMapaPedidos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapaPedidosScreen()),
    );
  }

  Future<void> _cambiarDisponibilidad() async {
    final nuevoEstado = _controller.estaDisponible
        ? EstadoRepartidor.fueraServicio
        : EstadoRepartidor.disponible;

    // Mostrar indicador de carga
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CupertinoActivityIndicator(radius: 16)),
      ),
    );

    final exito = await _controller.cambiarEstado(nuevoEstado);

    if (!mounted) return;
    Navigator.pop(context); // Cerrar indicador

    if (exito) {
      // Mostrar toast overlay (funciona en Cupertino)
      _mostrarToast(
        _controller.estaDisponible
            ? 'Ahora estás disponible'
            : 'Te has pausado',
        icono: _controller.estaDisponible
            ? CupertinoIcons.checkmark_circle_fill
            : CupertinoIcons.pause_circle_fill,
        color: _controller.estaDisponible ? _success : _textSecondary,
      );
    } else {
      _mostrarNotificacionError(_controller.error ?? 'Error al cambiar estado');
    }
  }

  void _mostrarToast(String mensaje, {IconData? icono, Color? color}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 40,
        right: 40,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color ?? _success,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.power, color: _rojo, size: 22),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, true),
            isDestructiveAction: true,
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) return;

      // Mostrar indicador de carga
      unawaited(
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const Center(child: CupertinoActivityIndicator(radius: 20)),
        ),
      );

      if (!mounted) return;
      await SessionCleanup.clearProviders(context);
      await _controller.cerrarSesion();

      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador

      await Rutas.irAYLimpiar(context, Rutas.login);
    }
  }

  // ============================================
  // FUNCIONES DE WHATSAPP Y NAVEGACIÓN
  // ============================================

  /// Construye el mensaje prellenado para WhatsApp con toda la información del pedido
  String _construirMensajePedido(PedidoDetalladoRepartidor pedido) {
    final buffer = StringBuffer();

    buffer.writeln('🚚 Hola, soy tu repartidor de Deliber.');
    buffer.writeln('');
    buffer.writeln('📋 *Pedido ID:* #${pedido.numeroPedido}');
    buffer.writeln('📦 *Tipo:* ${pedido.tipoDisplay}');

    // Marcar explícitamente si es pedido nocturno
    if (pedido.tipo.toLowerCase().contains('nocturno')) {
      buffer.writeln('�� *Horario:* NOCTURNO (22:00 - 06:00)');
    }

    buffer.writeln('');

    // Detalles de productos/servicios
    if (pedido.items?.isNotEmpty ?? false) {
      buffer.writeln('📝 *Detalle:*');
      for (final item in pedido.items!) {
        buffer.writeln(
          '   • ${item.cantidad}x ${item.productoNombre} - \$${item.subtotal.toStringAsFixed(2)}',
        );
      }
      buffer.writeln('');
    } else if (pedido.descripcion != null && pedido.descripcion!.isNotEmpty) {
      buffer.writeln('📝 *Descripción:* ${pedido.descripcion}');
      buffer.writeln('');
    }

    // Totales
    buffer.writeln('💰 *Subtotal:* \$${pedido.subtotal.toStringAsFixed(2)}');
    buffer.writeln(
      '🚗 *Costo de envío:* \$${pedido.costoEnvio.toStringAsFixed(2)}',
    );

    if (pedido.descuento != null && pedido.descuento! > 0) {
      buffer.writeln(
        '🎟️ *Descuento:* -\$${pedido.descuento!.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('💵 *Total:* \$${pedido.total.toStringAsFixed(2)}');
    buffer.writeln('💳 *Método de pago:* ${pedido.metodoPago}');
    buffer.writeln('');

    // Ubicaciones
    buffer.writeln('📍 *Recogida:* ${pedido.proveedor.nombre}');
    if (pedido.proveedor.direccion != null) {
      buffer.writeln('   ${pedido.proveedor.direccion}');
    }
    buffer.writeln('');
    buffer.writeln('🏠 *Entrega:* ${pedido.direccionEntrega}');

    // Notas especiales si existen
    if (pedido.descripcion != null &&
        pedido.descripcion!.isNotEmpty &&
        (pedido.items?.isEmpty ?? true)) {
      buffer.writeln('');
      buffer.writeln('📌 *Nota especial:* ${pedido.descripcion}');
    }

    buffer.writeln('');
    buffer.writeln('Estoy en camino para realizar tu entrega. 🚴‍♂️');

    return buffer.toString();
  }

  /// Abre Google Maps con el destino del pedido
  Future<void> _abrirNavegacion(PedidoDetalladoRepartidor pedido) async {
    Uri? url;

    // Determinar destino según estado
    final estado = pedido.estado.toLowerCase();
    final irAEntregar = estado == 'en_camino';
    final esDirecto = pedido.tipo.toLowerCase() == 'directo';

    if (!irAEntregar) {
      // ESTADO: Yendo a Recoger
      if (esDirecto) {
        // COURIER: Usar dirección de origen (texto)
        if (pedido.direccionOrigen != null &&
            pedido.direccionOrigen!.isNotEmpty) {
          final q = Uri.encodeComponent(pedido.direccionOrigen!);
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$q',
          );
        }
      } else {
        // PROVEEDOR: Usar lat/lon o dirección del proveedor
        if (pedido.proveedor.latitud != null &&
            pedido.proveedor.longitud != null) {
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${pedido.proveedor.latitud},${pedido.proveedor.longitud}',
          );
        } else if (pedido.proveedor.direccion != null) {
          final q = Uri.encodeComponent(pedido.proveedor.direccion!);
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$q',
          );
        }
      }
    }

    // Si no se asignó URL arriba (o es irAEntregar), intentar destino final
    if (url == null) {
      // ESTADO: Yendo a Entregar (o fallback)
      if (pedido.latitudDestino != null && pedido.longitudDestino != null) {
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${pedido.latitudDestino},${pedido.longitudDestino}',
        );
      } else if (pedido.direccionEntrega.isNotEmpty) {
        final direccionCodificada = Uri.encodeComponent(
          pedido.direccionEntrega,
        );
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$direccionCodificada',
        );
      }
    }

    if (url == null) {
      if (!mounted) return;
      _mostrarNotificacionError('No hay información de ubicación disponible');
      return;
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir Google Maps';
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarNotificacionError('Error al abrir navegación: $e');
    }
  }

  /// Realiza una llamada telefónica al cliente
  Future<void> _llamarCliente(String? telefono) async {
    if (telefono == null || telefono.isEmpty) {
      if (!mounted) return;
      _mostrarNotificacionError('No hay teléfono registrado para este cliente');
      return;
    }

    // Limpiar el número
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$telefonoLimpio');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'No se pudo realizar la llamada';
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarNotificacionError('Error al realizar la llamada: $e');
    }
  }

  /// Abre WhatsApp con un mensaje prellenado
  Future<void> _abrirWhatsAppCliente(PedidoDetalladoRepartidor pedido) async {
    final telefono = pedido.cliente.telefono;
    if (telefono == null || telefono.isEmpty) {
      if (!mounted) return;
      _mostrarNotificacionError('No hay teléfono registrado para este cliente');
      return;
    }

    // Limpiar el número (quitar espacios, guiones, paréntesis)
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');

    // Construir el mensaje con toda la información del pedido
    final mensaje = _construirMensajePedido(pedido);

    // URL de WhatsApp con el número y mensaje prellenado
    final url = Uri.parse(
      'https://wa.me/$telefonoLimpio?text=${Uri.encodeComponent(mensaje)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarNotificacionError('Error al abrir WhatsApp: $e');
    }
  }

  // ============================================
  // UI - BUILD PRINCIPAL (iOS STYLE)
  // ============================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: CupertinoColors.systemBackground,
            activeColor: _accent,
            inactiveColor: CupertinoColors.systemGrey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.square_list),
                label: 'Pendientes',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.location_fill),
                label: 'En Curso',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.time),
                label: 'Historial',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person_circle),
                label: 'Perfil',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              builder: (context) {
                switch (index) {
                  case 0:
                    return _buildTabPendientes();
                  case 1:
                    return _buildTabEnCurso();
                  case 2:
                    return _buildTabHistorial();
                  case 3:
                    return _buildTabPerfil();
                  default:
                    return _buildTabPendientes();
                }
              },
            );
          },
        );
      },
    );
  }

  // ============================================
  // TABS iOS STYLE
  // ============================================

  Widget _buildTabPendientes() {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        navigationBar: _buildNavBar('Pedidos Disponibles'),
        child: SafeArea(
          child: _controller.loading
              ? _buildCargando()
              : _buildPedidosPendientes(),
        ),
      ),
    );
  }

  Widget _buildTabEnCurso() {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        navigationBar: _buildNavBar('En Curso'),
        child: SafeArea(
          child: _controller.loading
              ? _buildCargando()
              : _buildPedidosEnCurso(),
        ),
      ),
    );
  }

  Widget _buildTabHistorial() {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        navigationBar: _buildNavBar('Historial'),
        child: SafeArea(
          child: _controller.loading ? _buildCargando() : _buildHistorial(),
        ),
      ),
    );
  }

  Widget _buildTabPerfil() {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        navigationBar: _buildNavBar('Mi Perfil'),
        child: SafeArea(child: _buildPerfilContent()),
      ),
    );
  }

  // ============================================
  // NAVIGATION BAR iOS STYLE
  // ============================================

  CupertinoNavigationBar _buildNavBar(String title) {
    return CupertinoNavigationBar(
      backgroundColor: CupertinoColors.systemBackground.withValues(alpha: 0.9),
      border: null,
      middle: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEstadoChip(),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _controller.cargarDatos(),
            child: const Icon(CupertinoIcons.refresh, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _controller.estaDisponible
            ? _success.withValues(alpha: 0.15)
            : CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controller.estaDisponible
              ? _success
              : CupertinoColors.systemGrey3,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _controller.estaDisponible
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.pause_circle_fill,
            color: _controller.estaDisponible
                ? _success
                : CupertinoColors.systemGrey,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _controller.estadoActual.nombre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _controller.estaDisponible
                  ? _success
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PERFIL CONTENT
  // ============================================

  Widget _buildPerfilContent() {
    if (_controller.perfil == null) {
      return const Center(child: Text('Cargando perfil...'));
    }

    final perfil = _controller.perfil!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.1),
                  border: Border.all(color: _accent, width: 3),
                ),
                child:
                    perfil.fotoPerfil != null && perfil.fotoPerfil!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          perfil.fotoPerfil!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                CupertinoIcons.person_fill,
                                size: 50,
                                color: _accent,
                              ),
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.person_fill,
                        size: 50,
                        color: _accent,
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                perfil.nombreCompleto,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                perfil.email,
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
              const SizedBox(height: 24),
              // Botón de disponibilidad
              _buildBotonDisponibilidad(),
              const SizedBox(height: 20),
              // Opciones de menú
              _buildMenuOptions(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotonDisponibilidad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        color: _controller.estaDisponible
            ? _success
            : CupertinoColors.systemGrey,
        borderRadius: BorderRadius.circular(12),
        onPressed: _cambiarDisponibilidad,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _controller.estaDisponible
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.pause_circle_fill,
              color: CupertinoColors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _controller.estaDisponible ? 'Disponible' : 'Pausado',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Column(
      children: [
        _buildMenuTile(
          icon: CupertinoIcons.map_fill,
          title: 'Ver Mapa de Pedidos',
          onTap: _abrirMapaPedidos,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CupertinoColors.systemPurple,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildMenuTile(
          icon: CupertinoIcons.money_dollar_circle,
          title: 'Ganancias',
          onTap: () => Navigator.pushNamed(context, Rutas.repartidorGanancias),
        ),
        _buildMenuTile(
          icon: CupertinoIcons.person_circle,
          title: 'Mi Perfil',
          onTap: () =>
              Navigator.pushNamed(context, Rutas.repartidorPerfilEditar),
        ),
        _buildMenuTile(
          icon: CupertinoIcons.settings,
          title: 'Configuración',
          onTap: () =>
              Navigator.pushNamed(context, Rutas.repartidorConfiguracion),
        ),
        _buildMenuTile(
          icon: CupertinoIcons.question_circle,
          title: 'Ayuda y Soporte',
          onTap: () => Navigator.pushNamed(context, Rutas.repartidorAyuda),
        ),
        const SizedBox(height: 20),
        // Cambiar Rol
        _buildMenuTile(
          icon: CupertinoIcons.arrow_right_arrow_left,
          title: 'Cambiar Rol',
          subtitle: 'Cliente / Proveedor',
          onTap: () => showRoleSelectorModal(context),
        ),
        _buildMenuTile(
          icon: CupertinoIcons.arrow_right_square,
          title: 'Cerrar Sesión',
          onTap: _cerrarSesion,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? _rojo : _accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? _rojo : _textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ESTADOS DE CARGA Y ERROR
  // ============================================

  Widget _buildCargando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          const SizedBox(height: 16),
          Text('Cargando datos...', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSurfaceCard({
    required Widget child,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 16),
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: _shadowColor, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  // ============================================
  // TABS DE CONTENIDO
  // ============================================

  Widget _buildPedidosPendientes() {
    final pendientes = _controller.pendientes ?? [];

    // Separar encargos y pedidos
    final encargos = pendientes
        .where((p) => p.tipo.toLowerCase() == 'directo')
        .toList();
    final pedidos = pendientes
        .where((p) => p.tipo.toLowerCase() != 'directo')
        .toList();

    final banner = (_ultimoPedidoNuevo != null)
        ? _buildBannerPush(_ultimoPedidoNuevo!, _ultimoPayload)
        : null;

    if (pendientes.isEmpty && banner == null) {
      return const ListaVaciaWidget(
        icono: CupertinoIcons.tray,
        mensaje: 'No hay pedidos pendientes',
        submensaje: 'Los nuevos pedidos aparecerán aquí',
        accionBoton: null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _controller.cargarPedidosDisponibles();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (banner != null) banner,

          // === SECCIÓN ENCARGOS ===
          if (encargos.isNotEmpty) ...[
            _buildSeccionHeader(
              icono: CupertinoIcons.paperplane_fill,
              titulo: 'Encargos',
              subtitulo:
                  '${encargos.length} disponible${encargos.length > 1 ? 's' : ''}',
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 12),
            ...encargos.map(_buildCardPedidoDisponible),
          ],

          // === SECCIÓN PEDIDOS ===
          if (pedidos.isNotEmpty) ...[
            if (encargos.isNotEmpty) const SizedBox(height: 20),
            _buildSeccionHeader(
              icono: CupertinoIcons.cube_box_fill,
              titulo: 'Pedidos',
              subtitulo:
                  '${pedidos.length} disponible${pedidos.length > 1 ? 's' : ''}',
              color: _accent,
            ),
            const SizedBox(height: 12),
            ...pedidos.map(_buildCardPedidoDisponible),
          ],
        ],
      ),
    );
  }

  /// Header de sección con icono y contador
  Widget _buildSeccionHeader({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPush(int pedidoId, Map<String, dynamic>? payload) {
    final total = payload?['total']?.toString();
    final cliente = payload?['cliente']?.toString();

    return _buildSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.sparkles, color: _accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Nuevo encargo #$pedidoId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (cliente != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cliente: $cliente',
                style: TextStyle(color: _textSecondary),
              ),
            ],
            if (total != null) ...[
              const SizedBox(height: 4),
              Text(
                'Total: $total',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _ultimoPedidoNuevo = null;
                        _ultimoPayload = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: BorderSide(color: _cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ignorar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _aceptarPedido(pedidoId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPedidoDisponible(PedidoDisponible pedido) {
    // Determinar si es un encargo (envío directo) o pedido de proveedor
    final esEncargo = pedido.tipo.toLowerCase() == 'directo';

    // Si es encargo, usar el nuevo widget especializado
    if (esEncargo) {
      return CardEncargoDisponible(
        encargo: pedido,
        onAceptar: () => _aceptarPedido(pedido.id),
        onRechazar: () => _controller.rechazarPedido(pedido.id),
      );
    }

    // Pedido regular: usar el card existente
    final titulo = '${pedido.proveedorNombre} • #${pedido.numeroPedido}';
    final iconoPedido = CupertinoIcons.cube_box_fill;
    final colorIcono = _accent;

    return _buildSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconoPedido, color: colorIcono, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${pedido.distanciaKm.toStringAsFixed(1)} km',
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location_solid,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pedido.zonaEntrega,
                    style: TextStyle(color: _textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${pedido.tiempoEstimadoMin} min est.',
                  style: TextStyle(color: _textSecondary),
                ),
                const SizedBox(width: 16),
                const Icon(
                  CupertinoIcons.money_dollar,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '\$${pedido.totalConRecargo.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.creditcard,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pago: ${pedido.metodoPago}',
                  style: TextStyle(color: _textPrimary),
                ),
                if (pedido.comisionRepartidor != null) ...[
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.money_dollar_circle_fill,
                    size: 16,
                    color: _success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ganancia \$${pedido.comisionRepartidor!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.rechazarPedido(pedido.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      side: BorderSide(color: _cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Rechazar',
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _aceptarPedido(pedido.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPedidosEnCurso() {
    final pedidosActivos = _controller.pedidosActivos ?? [];

    // Separar encargos y pedidos activos
    final encargosActivos = pedidosActivos
        .where((p) => p.tipo.toLowerCase() == 'directo')
        .toList();
    final pedidosRegulares = pedidosActivos
        .where((p) => p.tipo.toLowerCase() != 'directo')
        .toList();

    if (pedidosActivos.isEmpty) {
      return const ListaVaciaWidget(
        icono: CupertinoIcons.cube_box,
        mensaje: 'No tienes entregas en curso',
        submensaje: 'Acepta un pedido para comenzar',
        accionBoton: null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _controller.cargarPedidosActivos();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === SECCIÓN ENCARGOS EN CURSO ===
          if (encargosActivos.isNotEmpty) ...[
            _buildSeccionHeader(
              icono: CupertinoIcons.paperplane_fill,
              titulo: 'Encargos en Curso',
              subtitulo:
                  '${encargosActivos.length} activo${encargosActivos.length > 1 ? 's' : ''}',
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 12),
            ...encargosActivos.map(_buildCardPedidoActivo),
          ],

          // === SECCIÓN PEDIDOS EN CURSO ===
          if (pedidosRegulares.isNotEmpty) ...[
            if (encargosActivos.isNotEmpty) const SizedBox(height: 20),
            _buildSeccionHeader(
              icono: CupertinoIcons.cube_box_fill,
              titulo: 'Pedidos en Curso',
              subtitulo:
                  '${pedidosRegulares.length} activo${pedidosRegulares.length > 1 ? 's' : ''}',
              color: _accent,
            ),
            const SizedBox(height: 12),
            ...pedidosRegulares.map(_buildCardPedidoActivo),
          ],
        ],
      ),
    );
  }

  Widget _buildCardPedidoActivo(PedidoDetalladoRepartidor pedido) {
    // Determinar si es un encargo (envío directo) o pedido de proveedor
    final esEncargo = pedido.tipo.toLowerCase() == 'directo';

    // Si es encargo, usar el nuevo widget especializado con flujo de dos etapas
    if (esEncargo) {
      return CardEncargoActivo(
        encargo: pedido,
        onMarcarRecogido: () => _marcarEnCamino(pedido),
        onMarcarEntregado: () => _mostrarDialogoMarcarEntregado(pedido),
        onNavegar: () => _abrirNavegacion(pedido),
        onLlamar: () => _llamarCliente(pedido.cliente.telefono),
        onWhatsApp: () => _abrirWhatsAppCliente(pedido),
        onVerComprobante:
            pedido.pagoId != null &&
                (pedido.transferenciaComprobanteUrl ?? '').isNotEmpty
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PantallaVerComprobante(pagoId: pedido.pagoId!),
                  ),
                );
              }
            : null,
      );
    }

    // Pedido regular: usar el card existente
    final tipoLabel = '';
    final iconoPedido = CupertinoIcons.cube_box_fill;
    final colorBadge = _success;

    return _buildSurfaceCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorBadge.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconoPedido, size: 18, color: colorBadge),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$tipoLabel#${pedido.numeroPedido}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildChipEstado(pedido.estado),
              ],
            ),
            const SizedBox(height: 12),
            _buildSeccion(
              icono: CupertinoIcons.person_fill,
              titulo: 'Cliente',
              contenido: pedido.cliente.nombre,
            ),
            if (pedido.cliente.telefono != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.phone_fill,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pedido.cliente.telefono!,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.phone_circle_fill,
                      color: _success,
                      size: 22,
                    ),
                    onPressed: () => _llamarCliente(pedido.cliente.telefono),
                    tooltip: 'Llamar al cliente',
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366),
                      size: 24,
                    ),
                    onPressed: () => _abrirWhatsAppCliente(pedido),
                    tooltip: 'Enviar mensaje por WhatsApp',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _buildSeccion(
              icono: CupertinoIcons.location_solid,
              titulo: 'Dirección de entrega',
              contenido: pedido.direccionEntrega,
            ),
            if ((pedido.instruccionesEntrega ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSeccion(
                icono: Icons.info_outline,
                titulo: 'Instrucciones',
                contenido: pedido.instruccionesEntrega!,
              ),
            ],
            if (pedido.metodoPago.toLowerCase() == 'transferencia') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: _accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pago por transferencia',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            (pedido.transferenciaComprobanteUrl ?? '')
                                    .isNotEmpty
                                ? 'Comprobante listo'
                                : 'Pendiente',
                            style: TextStyle(
                              color:
                                  (pedido.transferenciaComprobanteUrl ?? '')
                                      .isNotEmpty
                                  ? Colors.green[800]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor:
                              (pedido.transferenciaComprobanteUrl ?? '')
                                  .isNotEmpty
                              ? Colors.green.withValues(alpha: 0.14)
                              : Colors.orange.withValues(alpha: 0.14),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (pedido.pagoId != null &&
                        (pedido.transferenciaComprobanteUrl ?? '').isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PantallaVerComprobante(
                                pagoId: pedido.pagoId!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Ver comprobante'),
                      )
                    else
                      Text(
                        'Aún no hay comprobante subido por el cliente.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildSeccion(
              icono: Icons.store,
              titulo: 'Proveedor',
              contenido: pedido.proveedor.nombre,
            ),
            if (pedido.items?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              const Text(
                'Productos',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...pedido.items!.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.cantidad}x ${item.productoNombre}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total del pedido:'),
                      Text(
                        '\$${pedido.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (pedido.comisionRepartidor != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tu ganancia (envío):',
                          style: TextStyle(color: _success),
                        ),
                        Text(
                          '\$${pedido.comisionRepartidor!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _success,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirNavegacion(pedido),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navegar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: BorderSide(color: _accent.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildBotonAccionPedido(pedido)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion({
    required IconData icono,
    required String titulo,
    required String contenido,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(contenido, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipEstado(String estado) {
    Color color;
    String texto;

    switch (estado.toLowerCase()) {
      case 'asignado':
        color = const Color(0xFF2196F3); // Azul
        texto = 'Asignado';
        break;
      case 'en_camino':
        color = _accent;
        texto = 'En Camino';
        break;
      case 'entregado':
        color = _success;
        texto = 'Entregado';
        break;
      default:
        color = Colors.grey;
        texto = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBotonAccionPedido(PedidoDetalladoRepartidor pedido) {
    final estadoLower = pedido.estado.toLowerCase();

    // Si el pedido está pendiente o asignado, mostrar botón "En Camino"
    if (estadoLower == 'pendiente_repartidor' ||
        estadoLower == 'asignado_repartidor') {
      return ElevatedButton.icon(
        onPressed: () => _marcarEnCamino(pedido),
        icon: const Icon(Icons.local_shipping),
        label: const Text('En Camino'),
        style: ElevatedButton.styleFrom(backgroundColor: _accent),
      );
    }

    // Si el pedido está en camino, mostrar botón "Entregado"
    if (estadoLower == 'en_camino') {
      return ElevatedButton.icon(
        onPressed: () => _mostrarDialogoMarcarEntregado(pedido),
        icon: const Icon(Icons.check_circle),
        label: const Text('Entregado'),
        style: ElevatedButton.styleFrom(backgroundColor: _success),
      );
    }

    // Si ya está entregado, mostrar chip de estado
    if (estadoLower == 'entregado') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _success),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: _success, size: 20),
            SizedBox(width: 8),
            Text(
              'Entregado',
              style: TextStyle(color: _success, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Estado no reconocido
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.info_outline),
      label: Text('Estado: ${pedido.estado}'),
    );
  }

  Future<void> _marcarEnCamino(PedidoDetalladoRepartidor pedido) async {
    final esEncargo = pedido.tipo.toLowerCase() == 'directo';
    final tipoTexto = esEncargo ? 'encargo' : 'pedido';
    final destinoTexto = esEncargo ? 'punto de entrega' : 'cliente';

    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.car_fill, color: _accent, size: 22),
            SizedBox(width: 8),
            Text('En Camino'),
          ],
        ),
        content: Text(
          '¿Confirmas que ya recogiste el $tipoTexto #${pedido.numeroPedido} y estás en camino hacia el $destinoTexto?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDefaultAction: true,
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) return;

      // Mostrar indicador de carga
      await showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CupertinoActivityIndicator(radius: 20)),
      );

      // Marcar como en camino
      final exito = await _controller.marcarPedidoEnCamino(
        pedido.id,
        mostrarLoading: false,
      );

      if (!mounted) return;

      // Cerrar indicador de carga
      Navigator.pop(context);

      if (exito) {
        _mostrarNotificacionExito(
          'En Camino',
          'Pedido #${pedido.numeroPedido} marcado como en camino',
        );
      } else {
        final errorMsg = _controller.error ?? 'Error al marcar como en camino';
        _mostrarNotificacionError(errorMsg);
      }
    }
  }

  Future<void> _mostrarDialogoMarcarEntregado(
    PedidoDetalladoRepartidor pedido,
  ) async {
    final esEncargo = pedido.tipo.toLowerCase() == 'directo';
    final tipoTexto = esEncargo ? 'encargo' : 'pedido';

    final esTransferencia = pedido.metodoPago.toLowerCase() == 'transferencia';
    final tieneComprobante =
        (pedido.transferenciaComprobanteUrl ?? '').isNotEmpty;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Confirmar Entrega'),
            contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Confirmas que el $tipoTexto #${pedido.numeroPedido} fue entregado exitosamente?',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payment, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Método de pago: ${pedido.metodoPago}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (esTransferencia) ...[
                    const SizedBox(height: 12),
                    if (!tieneComprobante)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'El cliente aún no ha subido el comprobante de transferencia.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: _success,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Comprobante recibido',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (pedido.pagoId != null)
                            TextButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext, null);
                                      Navigator.push(
                                        dialogContext,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PantallaVerComprobante(
                                                pagoId: pedido.pagoId!,
                                              ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Ver comprobante'),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (esTransferencia && !tieneComprobante) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No puedes entregar sin comprobante de transferencia del cliente',
                              ),
                              backgroundColor: _rojo,
                            ),
                          );
                          return;
                        }
                        setStateDialog(() => isSubmitting = true);
                        final exito = await _controller.marcarPedidoEntregado(
                          pedidoId: pedido.id,
                          mostrarLoading: false,
                        );
                        if (!mounted || !dialogContext.mounted) return;
                        Navigator.pop(dialogContext, exito);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: _success),
                child: isSubmitting
                    ? const CupertinoActivityIndicator(
                        color: Colors.white,
                        radius: 10,
                      )
                    : const Text('Confirmar Entrega'),
              ),
            ],
          ),
        );
      },
    );

    if (resultado == null || !mounted) return;
    if (resultado) {
      // Notificación de éxito
      _mostrarNotificacionExito(
        'Pedido Entregado',
        'Pedido #${pedido.numeroPedido} marcado como entregado exitosamente',
      );

      // Mostrar diálogo de calificación del cliente después de entregar
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => DialogoCalificarCliente(
          pedidoId: pedido.id,
          clienteNombre: pedido.cliente.nombre,
          clienteFoto: pedido.cliente.foto,
        ),
      );

      return;
    }
    final errorMsg = _controller.error ?? 'Error al marcar como entregado';
    _mostrarNotificacionError(errorMsg);
  }

  Widget _buildHistorial() {
    // Cargar historial la primera vez que se abre el tab
    // CORREGIDO: Agregar flag para evitar loop infinito
    if (_controller.historialEntregas == null &&
        !_controller.loadingHistorial &&
        _controller.error == null) {
      Future.microtask(() => _controller.cargarHistorialEntregas());
    }

    if (_controller.loadingHistorial) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    // Mostrar error si hubo problemas al cargar
    if (_controller.error != null && _controller.historialEntregas == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: _rojo.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar el historial',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _controller.error ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _controller.cargarHistorialEntregas(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
              ),
            ],
          ),
        ),
      );
    }

    final entregas = _controller.entregas;

    if (entregas.isEmpty) {
      return const ListaVaciaWidget(
        icono: Icons.history,
        mensaje: 'Historial vacío',
        submensaje: 'Tus entregas completadas aparecerán aquí',
      );
    }

    return Column(
      children: [
        // Estadísticas del historial
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accent.withValues(alpha: 0.1),
                _success.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstadisticaHistorial(
                Icons.delivery_dining,
                'Entregas',
                '${_controller.totalEntregasHistorial}',
                _accent,
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _buildEstadisticaHistorial(
                Icons.payments,
                'Comisiones',
                'Bs ${_controller.totalComisionesHistorial.toStringAsFixed(2)}',
                _success,
              ),
            ],
          ),
        ),
        // Lista de entregas
        Expanded(
          child: RefreshIndicator(
            color: _accent,
            onRefresh: _controller.recargarHistorial,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entregas.length,
              itemBuilder: (context, index) {
                final entrega = entregas[index];
                return _buildCardEntrega(entrega);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticaHistorial(
    IconData icono,
    String titulo,
    String valor,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icono, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCardEntrega(EntregaHistorial entrega) {
    return _buildSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: entrega.tieneComprobante
              ? () => _mostrarComprobanteCompleto(entrega)
              : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${entrega.id}',
                            style: const TextStyle(
                              color: _success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: _success,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Entregado',
                          style: TextStyle(
                            color: _success,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      entrega.fechaFormateada,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entrega.clienteNombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entrega.clienteDireccion,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total del pedido',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bs ${entrega.montoTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tu comisión',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Bs ${entrega.comisionRepartidor.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (entrega.tieneComprobante) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, color: _success, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Comprobante adjunto',
                        style: TextStyle(
                          fontSize: 12,
                          color: _success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getColorMetodoPago(
                      entrega.metodoPago,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconoMetodoPago(entrega.metodoPago),
                        size: 14,
                        color: _getColorMetodoPago(entrega.metodoPago),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getNombreMetodoPago(entrega.metodoPago),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getColorMetodoPago(entrega.metodoPago),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorMetodoPago(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return _success;
      case 'tarjeta':
        return Colors.blue;
      case 'transferencia':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoMetodoPago(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return Icons.money;
      case 'tarjeta':
        return Icons.credit_card;
      case 'transferencia':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _getNombreMetodoPago(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      default:
        return metodo;
    }
  }

  void _mostrarComprobanteCompleto(EntregaHistorial entrega) {
    if (entrega.urlComprobante == null || entrega.urlComprobante!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  entrega.urlComprobante!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: _rojo),
                          SizedBox(height: 16),
                          Text('Error al cargar la imagen'),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: const CupertinoActivityIndicator(radius: 14),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cerrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// WIDGET DE NOTIFICACIÓN BANNER iOS STYLE
// ============================================

class _NotificacionBanner extends StatefulWidget {
  final int pedidoId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificacionBanner({
    required this.pedidoId,
    required this.data,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificacionBanner> createState() => _NotificacionBannerState();
}

class _NotificacionBannerState extends State<_NotificacionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.data['cliente']?.toString() ?? 'Cliente';
    final total = widget.data['total']?.toString() ?? '—';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -500) {
                _handleDismiss();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(left: 12, right: 12, top: 50),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icono animado
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.bell_fill,
                            color: CupertinoColors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Contenido
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.sparkles,
                                    color: Colors.yellowAccent,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'NUEVO PEDIDO DISPONIBLE',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pedido #${widget.pedidoId}',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cliente: $cliente',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                              if (total != '—') ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Total: $total',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Botón cerrar
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _handleDismiss,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: CupertinoColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
