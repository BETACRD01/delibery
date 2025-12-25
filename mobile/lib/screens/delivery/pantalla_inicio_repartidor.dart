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
import 'widgets/repartidor_drawer.dart';
import 'widgets/lista_vacia_widget.dart';
import '../../services/auth/session_cleanup.dart';
import '../../widgets/ratings/dialogo_calificar_cliente.dart';
import 'pantalla_ver_comprobante.dart';

/// ✅ REFACTORIZADA: Pantalla principal para REPARTIDORES
/// UI limpia que delega toda la lógica al controller
class PantallaInicioRepartidor extends StatefulWidget {
  const PantallaInicioRepartidor({super.key});

  @override
  State<PantallaInicioRepartidor> createState() =>
      _PantallaInicioRepartidorState();
}

class _PantallaInicioRepartidorState extends State<PantallaInicioRepartidor>
    with SingleTickerProviderStateMixin {
  // ============================================
  // CONTROLLER Y TABS
  // ============================================
  late final RepartidorController _controller;
  late final TabController _tabController;
  int? _ultimoPedidoNuevo;
  Map<String, dynamic>? _ultimoPayload;

  // ============================================
  // COLORES
  // ============================================
  static const Color _accent = Color(0xFF0A84FF);
  static const Color _success = Color(0xFF34C759);
  static const Color _rojo = Color(0xFFF44336);
  static const Color _surface = Color(0xFFF2F4F7);
  static const Color _cardBorder = Color(0xFFE1E4EB);
  static const Color _shadowColor = Color(0x1A000000);

  // ============================================
  // CICLO DE VIDA
  // ============================================

  @override
  void initState() {
    super.initState();
    _controller = RepartidorController();
    _tabController = TabController(length: 3, vsync: this);
    _inicializar();
    _suscribirPushPedidos();
  }

  @override
  void dispose() {
    _pedidoSub?.cancel();
    _tabController.dispose();
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

    // Mover al tab de pendientes para que sea visible
    _tabController.index = 0;
    setState(() {
      _ultimoPedidoNuevo = pedidoId;
      _ultimoPayload = data;
    });

    // Aviso rápido
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nuevo encargo #$pedidoId disponible'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => _mostrarDialogoNuevoPedido(pedidoId, data),
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    // Diálogo de detalle
    _mostrarDialogoNuevoPedido(pedidoId, data);
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

  Future<void> _mostrarDialogoNuevoPedido(
    int pedidoId,
    Map<String, dynamic> data,
  ) async {
    final cliente = data['cliente']?.toString() ?? 'Cliente';
    final total = data['total']?.toString() ?? '—';

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo pedido disponible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedido #$pedidoId'),
            const SizedBox(height: 6),
            Text('Cliente: $cliente'),
            if (total != '—') ...[
              const SizedBox(height: 6),
              Text('Total: $total'),
            ],
            const SizedBox(height: 12),
            const Text(
              '¿Quieres aceptarlo?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ignorar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _aceptarPedido(pedidoId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _success),
            child: const Text('Aceptar'),
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

        // Cambiar a la pestaña "En Curso" para que el usuario vea el pedido aceptado
        _tabController.animateTo(1);

        // Mostrar mensaje con información del pedido aceptado
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido #${detallePedido.numeroPedido} aceptado\n'
              'Cliente: ${detallePedido.cliente.nombre}\n'
              'Destino: ${detallePedido.direccionEntrega}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final mensajeError =
            _controller.error ?? 'No se pudo aceptar el pedido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final mensajeError = _controller.error ?? 'Error aceptando el pedido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
      );
    }
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

    final exito = await _controller.cambiarEstado(nuevoEstado);

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _controller.getIconoEstado(nuevoEstado),
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Estado actualizado: ${nuevoEstado.nombre}'),
              ),
            ],
          ),
          backgroundColor: _controller.getColorEstado(nuevoEstado),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.error ?? 'Error al cambiar estado'),
          backgroundColor: _rojo,
        ),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await Rutas.mostrarDialogo<bool>(
      context,
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Rutas.volver(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Rutas.volver(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _rojo),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) return;
      await SessionCleanup.clearProviders(context);
      await _controller.cerrarSesion();
      if (!mounted) return;
      await Rutas.irAYLimpiar(context, Rutas.login);
    }
  }

  // ============================================
  // FUNCIONES DE WHATSAPP Y NAVEGACIÓN
  // ============================================

  /// Abre WhatsApp con un mensaje prellenado con información del pedido
  Future<void> _abrirWhatsAppCliente(PedidoDetalladoRepartidor pedido) async {
    final telefono = pedido.cliente.telefono;
    if (telefono == null || telefono.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay teléfono registrado para este cliente'),
          backgroundColor: _rojo,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir WhatsApp: $e'),
          backgroundColor: _rojo,
        ),
      );
    }
  }

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

    // Prioridad 1: Usar coordenadas GPS si están disponibles
    if (pedido.latitudDestino != null && pedido.longitudDestino != null) {
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${pedido.latitudDestino},${pedido.longitudDestino}',
      );
    }
    // Prioridad 2: Usar la dirección de entrega
    else if (pedido.direccionEntrega.isNotEmpty) {
      final direccionCodificada = Uri.encodeComponent(pedido.direccionEntrega);
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$direccionCodificada',
      );
    }

    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay información de ubicación disponible'),
          backgroundColor: _rojo,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir navegación: $e'),
          backgroundColor: _rojo,
        ),
      );
    }
  }

  /// Realiza una llamada telefónica al cliente
  Future<void> _llamarCliente(String? telefono) async {
    if (telefono == null || telefono.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay teléfono registrado para este cliente'),
          backgroundColor: _rojo,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al realizar la llamada: $e'),
          backgroundColor: _rojo,
        ),
      );
    }
  }

  // ============================================
  // UI - BUILD PRINCIPAL
  // ============================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _surface,
          appBar: _buildAppBar(),
          drawer: _buildDrawer(),
          body: _buildBody(),
        );
      },
    );
  }

  // ============================================
  // APP BAR
  // ============================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Dashboard',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: [
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: _abrirMapaPedidos,
          tooltip: 'Ver mapa de pedidos',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _controller.getIconoEstado(_controller.estadoActual),
                        color: _controller.estaDisponible
                            ? _success
                            : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _controller.estadoActual.nombre,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _controller.cargarDatos(),
          tooltip: 'Actualizar',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              tabs: const [
                Tab(text: 'Pendientes'),
                Tab(text: 'En curso'),
                Tab(text: 'Historial'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // DRAWER
  // ============================================

  Widget _buildDrawer() {
    return RepartidorDrawer(
      perfil: _controller.perfil,
      estaDisponible: _controller.estaDisponible,
      onCambiarDisponibilidad: _cambiarDisponibilidad,
      onAbrirMapa: _abrirMapaPedidos,
      onCerrarSesion: _cerrarSesion,
    );
  }

  // ============================================
  // BODY
  // ============================================

  Widget _buildBody() {
    if (_controller.loading) {
      return _buildCargando();
    }

    if (_controller.error != null && _controller.perfil == null) {
      return _buildError();
    }

    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPedidosPendientes(),
              _buildPedidosEnCurso(),
              _buildHistorial(),
            ],
          ),
        ),
      ],
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

  Widget _buildError() {
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
            Text(
              _controller.error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _inicializar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
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

    final banner = (_ultimoPedidoNuevo != null)
        ? _buildBannerPush(_ultimoPedidoNuevo!, _ultimoPayload)
        : null;

    if (pendientes.isEmpty && banner == null) {
      return const ListaVaciaWidget(
        icono: Icons.inbox,
        mensaje: 'No hay pedidos pendientes',
        submensaje: 'Los nuevos pedidos aparecerán aquí',
        accionBoton: null,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (banner != null) banner,
        ...pendientes.map(_buildCardPedidoDisponible),
      ],
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
                const Icon(Icons.new_releases, color: _accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Nuevo encargo #$pedidoId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (cliente != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cliente: $cliente',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            if (total != null) ...[
              const SizedBox(height: 4),
              Text(
                'Total: $total',
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey.shade300),
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
                const Icon(Icons.delivery_dining, color: _accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pedido.proveedorNombre} • #${pedido.numeroPedido}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${pedido.distanciaKm.toStringAsFixed(1)} km',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pedido.zonaEntrega,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${pedido.tiempoEstimadoMin} min est.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '\$${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Pago: ${pedido.metodoPago}',
                  style: const TextStyle(color: Colors.black87),
                ),
                if (pedido.comisionRepartidor != null) ...[
                  const Spacer(),
                  const Icon(Icons.monetization_on, size: 16, color: _success),
                  const SizedBox(width: 4),
                  Text(
                    'Comisión \$${pedido.comisionRepartidor!.toStringAsFixed(2)}',
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
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Rechazar',
                      style: TextStyle(color: Colors.black87),
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

    if (pedidosActivos.isEmpty) {
      return const ListaVaciaWidget(
        icono: Icons.delivery_dining,
        mensaje: 'No tienes entregas en curso',
        submensaje: 'Acepta un pedido para comenzar',
        accionBoton: null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _controller.cargarPedidosActivos();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pedidosActivos.length,
        itemBuilder: (context, index) {
          return _buildCardPedidoActivo(pedidosActivos[index]);
        },
      ),
    );
  }

  Widget _buildCardPedidoActivo(PedidoDetalladoRepartidor pedido) {
    return _buildSurfaceCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _success.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining,
                        size: 18,
                        color: _success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '#${pedido.numeroPedido}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildChipEstado(pedido.estado),
              ],
            ),
            const SizedBox(height: 12),
            _buildSeccion(
              icono: Icons.person,
              titulo: 'Cliente',
              contenido: pedido.cliente.nombre,
            ),
            if (pedido.cliente.telefono != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pedido.cliente.telefono!,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: _success, size: 22),
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
              icono: Icons.location_on,
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
                          'Tu comisión:',
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como En Camino'),
        content: Text(
          '¿Confirmas que ya recogiste el pedido #${pedido.numeroPedido} y estás en camino hacia el cliente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) return;

      // Mostrar indicador de carga
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CupertinoActivityIndicator(radius: 14)),
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido #${pedido.numeroPedido} marcado como en camino',
            ),
            backgroundColor: _accent,
          ),
        );
      } else {
        final errorMsg = _controller.error ?? 'Error al marcar como en camino';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: _rojo),
        );
      }
    }
  }

  Future<void> _mostrarDialogoMarcarEntregado(
    PedidoDetalladoRepartidor pedido,
  ) async {
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
                    '¿Confirmas que el pedido #${pedido.numeroPedido} fue entregado exitosamente?',
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
                                          builder: (_) => PantallaVerComprobante(
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
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido #${pedido.numeroPedido} marcado como entregado',
          ),
          backgroundColor: _success,
        ),
      );

      // Mostrar diálogo de calificación del cliente después de entregar
      await Future.delayed(const Duration(milliseconds: 500));
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMsg), backgroundColor: _rojo),
    );
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
