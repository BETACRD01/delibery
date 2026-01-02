// lib/screens/delivery/home/pantalla_inicio_repartidor.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
// Models
import '../../../models/orders/pedido_repartidor.dart';
import '../../../models/entities/repartidor.dart';

// Services & Providers
import '../../../services/auth/session_cleanup.dart';

// Widgets & Helpers
import '../../../widgets/maps/mapa_pedidos_widget.dart';
import '../../delivery/widgets/card_encargo_activo.dart';
import '../../delivery/widgets/card_encargo_disponible.dart';
import '../../delivery/widgets/lista_vacia_widget.dart';

// Screens
import '../ganancias/pantalla_ganancias_repartidor.dart';
import '../historial/pantalla_historial_repartidor.dart';
import '../perfil/pantalla_perfil_repartidor.dart';
import '../soporte/pantalla_ayuda_soporte_repartidor.dart';

// Controllers
import '../../../controllers/delivery/repartidor_controller.dart';
import '../../../config/routing/rutas.dart';

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
    // 1. Mostrar Dialog de Carga
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return CupertinoAlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CupertinoActivityIndicator(),
                SizedBox(height: 10),
                Text('Asignando pedido...'),
              ],
            ),
          );
        },
      ),
    );

    try {
      // El controller ahora devuelve el detalle completo del pedido con datos sensibles
      final detallePedido = await _controller.aceptarPedido(pedidoId);

      // 2. Cerrar Dialog de Carga
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      final exito = detallePedido != null;

      if (exito) {
        setState(() {
          if (_ultimoPedidoNuevo == pedidoId) {
            _ultimoPedidoNuevo = null;
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
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      _mostrarNotificacionError('Error de conexión: $e');
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

  /// Abre Google Maps con el destino del pedido
  Future<void> _abrirNavegacion(PedidoDetalladoRepartidor pedidoIn) async {
    // Asegurar que usamos la versión más reciente del pedido (estado actualizado)
    final pedido =
        _controller.pedidosActivos?.firstWhere(
          (p) => p.id == pedidoIn.id,
          orElse: () => pedidoIn,
        ) ??
        pedidoIn;

    Uri? url;

    // Determinar destino según estado
    final estado = pedido.estado.toLowerCase();
    final irAEntregar = estado == 'en_camino';
    final esDirecto = pedido.tipo.toLowerCase() == 'directo';

    if (!irAEntregar) {
      // ESTADO: Yendo a Recoger
      if (esDirecto) {
        // COURIER: Priorizar coordenadas de origen, luego dirección (texto)
        if (pedido.latitudOrigen != null && pedido.longitudOrigen != null) {
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${pedido.latitudOrigen},${pedido.longitudOrigen}',
          );
        } else if (pedido.direccionOrigen != null &&
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

    if (url != null) {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _mostrarNotificacionError('No se pudo abrir mapas');
      }
    } else {
      if (!mounted) return;
      _mostrarNotificacionError('No hay ubicación o coordenadas disponibles');
    }
  }

  // ============================================
  // UI PRINCIPAL
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior personalizada (iOS Style)
              _buildAppBarImpl(),

              // Contenido principal
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    if (_controller.loading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    if (_controller.error != null) {
                      return _buildErrorState();
                    }

                    // Si no hay pedidos activos, mostramos lista de disponibles (si hay) o empty state
                    final hayActivos =
                        _controller.pedidosActivos?.isNotEmpty ?? false;
                    final hayDisponibles =
                        _controller.pendientes?.isNotEmpty ?? false;

                    if (!hayActivos && !hayDisponibles) {
                      return const ListaVaciaWidget(
                        mensaje:
                            'No hay pedidos disponibles por el momento. Mantente en línea.',
                        submensaje: 'Te avisaremos cuando haya nuevos pedidos.',
                        icono: CupertinoIcons.cube_box,
                      );
                    }

                    return RefreshIndicator.adaptive(
                      onRefresh: _controller.cargarDatos,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Pedidos Activos (EN CURSO)
                            if (hayActivos) ...[
                              _buildSeccionHeader('EN CURSO'),
                              ..._controller.pedidosActivos!.map(
                                (p) => CardEncargoActivo(
                                  encargo: p,
                                  onNavegar: () => _abrirNavegacion(p),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // 2. Pedidos Disponibles
                            if (hayDisponibles) ...[
                              _buildSeccionHeader('NUEVOS PEDIDOS'),
                              ..._controller.pendientes!.map(
                                (p) => CardEncargoDisponible(
                                  encargo: p,
                                  onAceptar: () => _aceptarPedido(p.id),
                                  onRechazar: () {
                                    // Lógica para rechazar o ignorar
                                    _removerPedidoDisponible(p.id);
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(_controller.error ?? 'Error desconocido'),
          const SizedBox(height: 16),
          CupertinoButton(
            child: const Text('Reintentar'),
            onPressed: () => _controller.cargarDatos(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // WIDGETS INTERNOS
  // ============================================

  /// Barra superior personalizada
  Widget _buildAppBarImpl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: _cardBorder, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar y Estado
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PantallaEditarPerfilRepartidor(),
                    ), // Corrected class name
                  );
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: CupertinoColors.systemGrey5,
                      backgroundImage: _controller.perfil?.fotoPerfilUrl != null
                          ? NetworkImage(_controller.perfil!.fotoPerfilUrl!)
                          : null,
                      child: _controller.perfil?.fotoPerfilUrl == null
                          ? const Icon(
                              CupertinoIcons.person_fill,
                              color: CupertinoColors.systemGrey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _controller.estaDisponible
                              ? _success
                              : CupertinoColors.systemGrey,
                          shape: BoxShape.circle,
                          border: Border.all(color: _surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Saludo y Switch Estado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${_controller.perfil?.nombreCompleto ?? "Repartidor"}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: _cambiarDisponibilidad,
                      child: Container(
                        color: Colors.transparent, // Hitbox
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _controller.estaDisponible
                                  ? 'En línea'
                                  : 'Desconectado',
                              style: TextStyle(
                                fontSize: 13,
                                color: _controller.estaDisponible
                                    ? _success
                                    : _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.chevron_down,
                              size: 12,
                              color: _textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de Acción
              Row(
                children: [
                  _buildIconButton(
                    icon: CupertinoIcons.map_fill,
                    onTap: _abrirMapaPedidos,
                    badge: (_controller.pendientes?.length ?? 0) > 0,
                  ),
                  const SizedBox(width: 12),
                  // Botón flotante para acceder a menú rápido o acciones globales
                  _buildIconButton(
                    icon: CupertinoIcons.ellipsis_circle,
                    onTap: _mostrarMenuOpciones,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: _textPrimary, size: 22),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _rojo,
                  shape: BoxShape.circle,
                  border: Border.all(color: _surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarMenuOpciones() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PantallaGananciasRepartidor(),
                ),
              );
            },
            child: const Text('Mis Ganancias'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PantallaHistorialRepartidor(),
                ),
              );
            },
            child: const Text('Historial de Entregas'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PantallaAyudaSoporteRepartidor(),
                ), // Corrected class name
              );
            },
            child: const Text('Soporte'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _cerrarSesion();
            },
            isDestructiveAction: true,
            child: const Text('Cerrar Sesión'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
}

class _NotificacionBanner extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          tween: Tween(begin: -100.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(offset: Offset(0, value), child: child);
          },
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0CB7F2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.cube_box,
                      color: Color(0xFF0CB7F2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¡Nuevo Pedido Disponible!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca para ver detalles del pedido #$pedidoId',
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: CupertinoColors.tertiaryLabel,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
