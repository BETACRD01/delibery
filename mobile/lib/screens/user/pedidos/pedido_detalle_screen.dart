import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/pedido_model.dart';
import '../../../providers/proveedor_pedido.dart';
import '../../../services/pago/pago_service.dart';
import '../../../widgets/ratings/dialogo_calificar_proveedor.dart';
import '../../../widgets/ratings/dialogo_calificar_repartidor.dart';
import 'pantalla_subir_comprobante.dart';
import 'pantalla_ver_comprobante_usuario.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final int pedidoId;

  const PedidoDetalleScreen({super.key, required this.pedidoId});

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  bool _isCancelling = false;
  final bool _enviandoCalificacion = false;
  final PagoService _pagoService = PagoService();
  @override
  void initState() {
    super.initState();
    // CORRECCIÓN 1: Limpiar estado sucio al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<PedidoProvider>();
        // Primero borramos cualquier error viejo de la memoria para evitar el parpadeo rojo
        provider.limpiarError();
        // Luego pedimos los datos frescos
        provider.cargarDetalle(widget.pedidoId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedBackground = CupertinoColors.systemGroupedBackground
        .resolveFrom(context);
    return Scaffold(
      backgroundColor: groupedBackground,
      appBar: AppBar(
        title: Text(
          'Detalle del pedido',
          style: TextStyle(
            color: CupertinoColors.label.resolveFrom(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: groupedBackground,
        foregroundColor: CupertinoColors.label.resolveFrom(context),
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, provider, child) {
          // CORRECCIÓN 2: Prioridad a la Carga
          // Si está cargando, mostramos el círculo SIEMPRE,
          // ignorando cualquier error viejo que pueda existir en memoria.
          if (provider.isLoading) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          // Si ya terminó de cargar y TODAVÍA hay error, ahí sí lo mostramos
          if (provider.error != null) {
            return _buildError(provider.error ?? 'Error desconocido');
          }

          final pedido = provider.pedidoActual;
          if (pedido == null) {
            return const Center(child: Text('No se encontró el pedido'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Al refrescar manual, también limpiamos errores
              provider.limpiarError();
              await provider.cargarDetalle(widget.pedidoId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderStatus(pedido),
                  const SizedBox(height: 16),

                  _buildDireccionesCard(pedido),
                  const SizedBox(height: 16),

                  if (pedido.proveedor != null) ...[
                    _buildProveedorCard(pedido),
                    const SizedBox(height: 8),
                  ],

                  if (pedido.estado == 'entregado' &&
                      pedido.puedeCalificarProveedor) ...[
                    _buildCalificacionProveedorCTA(pedido),
                    const SizedBox(height: 16),
                  ] else if (pedido.calificacionProveedor != null) ...[
                    _buildCalificacionProveedorResumen(pedido),
                    const SizedBox(height: 16),
                  ],

                  if (pedido.repartidor != null) ...[
                    _buildRepartidorCard(pedido),
                    const SizedBox(height: 8),
                  ],

                  if (pedido.estado == 'entregado' &&
                      pedido.puedeCalificarRepartidor) ...[
                    _buildCalificacionCTA(pedido),
                    const SizedBox(height: 16),
                  ] else if (pedido.calificacionRepartidor != null) ...[
                    _buildCalificacionResumen(pedido),
                    const SizedBox(height: 16),
                  ],

                  if (pedido.imagenEvidencia != null) ...[
                    _buildEvidenciaCard(pedido),
                    const SizedBox(height: 16),
                  ],

                  if (pedido.estado == 'cancelado') ...[
                    _buildCancelacionCard(pedido),
                    const SizedBox(height: 16),
                  ],

                  _buildAccionesCard(pedido),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Ocurrió un problema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final provider = context.read<PedidoProvider>();
                provider.limpiarError();
                provider.cargarDetalle(widget.pedidoId);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalificacionCTA(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto de perfil del repartidor
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            child:
                pedido.repartidor?.fotoPerfil != null &&
                    pedido.repartidor!.fotoPerfil!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: pedido.repartidor!.fotoPerfil!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CupertinoActivityIndicator(radius: 10),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.delivery_dining,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.delivery_dining,
                    color: Colors.green,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Califica al repartidor',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: _enviandoCalificacion
                ? null
                : () async {
                    final result = await showCupertinoModalPopup<bool>(
                      context: context,
                      builder: (context) => DialogoCalificarRepartidor(
                        pedidoId: pedido.id,
                        repartidorNombre:
                            pedido.repartidor?.nombre ?? 'Repartidor',
                        repartidorFoto: pedido.repartidor?.fotoPerfil,
                      ),
                    );
                    if (result == true && mounted) {
                      // Recargar el pedido para actualizar la UI
                      setState(() {});
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Calificar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionResumen(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Calificado: ${pedido.calificacionRepartidor?.toStringAsFixed(1) ?? ''} ⭐',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionProveedorCTA(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto de perfil del proveedor
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            child:
                pedido.proveedor?.fotoPerfil != null &&
                    pedido.proveedor!.fotoPerfil!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: pedido.proveedor!.fotoPerfil!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CupertinoActivityIndicator(radius: 10),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.store_mall_directory_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.store_mall_directory_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Califica al proveedor',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await showCupertinoModalPopup<bool>(
                context: context,
                builder: (context) => DialogoCalificarProveedor(
                  pedidoId: pedido.id,
                  proveedorId: pedido.proveedor?.id ?? 0,
                  proveedorNombre: pedido.proveedor?.nombre ?? 'Proveedor',
                  proveedorFoto: pedido.proveedor?.fotoPerfil,
                ),
              );
              if (result == true && mounted) {
                // Recargar el pedido para actualizar la UI
                final provider = context.read<PedidoProvider>();
                provider.limpiarError();
                await provider.cargarDetalle(widget.pedidoId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Calificar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionProveedorResumen(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Proveedor calificado: ${pedido.calificacionProveedor?.toStringAsFixed(1) ?? ''} ⭐',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE UI (Cards y Secciones) ---

  Widget _buildHeaderStatus(Pedido pedido) {
    final color = _getColorEstado(pedido.estado);
    final subtotal = pedido.items.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final comision = pedido.tarifaServicio;
    final envio = pedido.datosEnvio;
    final costoEnvio = envio?.costoEnvio ?? 0;
    final recargoNocturno = (envio?.recargoNocturnoAplicado ?? false)
        ? (envio?.recargoNocturno ?? 0)
        : 0;
    final tiempoEstimado = envio?.tiempoEstimadoMins;

    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estado Actual',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pedido.estadoDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Pago', pedido.metodoPagoDisplay),
          if (tiempoEstimado != null && tiempoEstimado > 0)
            _buildInfoRow('Tiempo estimado', '$tiempoEstimado min'),
          const Divider(height: 24),
          // Resumen tipo factura: items + desglose
          if (pedido.items.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Productos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            ...pedido.items.map((item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductoItemRow(item, pedido),
                  const SizedBox(height: 4),
                ],
              );
            }),
            const Divider(height: 20),
            _buildInfoRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
            if (costoEnvio > 0)
              _buildInfoRow(
                'Costo de envío',
                '\$${costoEnvio.toStringAsFixed(2)}',
              ),
            if (recargoNocturno > 0)
              _buildInfoRow(
                'Recargo nocturno',
                '\$${recargoNocturno.toStringAsFixed(2)}',
              ),
            if (comision > 0)
              _buildInfoRow(
                'Comisión de servicio',
                '\$${comision.toStringAsFixed(2)}',
              ),
            // Calcular total incluyendo recargo nocturno (sumado al total base del pedido)
            _buildInfoRow(
              'Total',
              '\$${(pedido.total + recargoNocturno).toStringAsFixed(2)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDireccionesCard(Pedido pedido) {
    return _buildSurfaceCard(
      child: Column(
        children: [
          if (pedido.direccionOrigen != null) ...[
            _buildRowIcon(Icons.store, 'Retiro', pedido.direccionOrigen!),
            const SizedBox(height: 12),
          ],
          _buildRowIcon(Icons.location_on, 'Entrega', pedido.direccionEntrega),
        ],
      ),
    );
  }

  Widget _buildRowIcon(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductoItemRow(ItemPedido item, Pedido pedido) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '${item.cantidad}x ${item.productoNombre}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          '\$${item.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProveedorCard(Pedido pedido) {
    return _buildContactoCard(
      titulo: 'Proveedor',
      nombre: pedido.proveedor!.nombre,
      detalle:
          pedido.proveedor!.direccion ??
          pedido.proveedor!.telefono ??
          'Sin información',
      icono: Icons.store_mall_directory_rounded,
      color: Colors.orange,
      fotoPerfil: pedido.proveedor!.fotoPerfil,
      onWhatsapp: pedido.proveedor!.telefono != null
          ? () => _abrirWhatsapp(pedido.proveedor!.telefono, pedido)
          : null,
      onCall: pedido.proveedor!.telefono != null
          ? () => _llamar(pedido.proveedor!.telefono)
          : null,
    );
  }

  Widget _buildRepartidorCard(Pedido pedido) {
    return _buildContactoCard(
      titulo: 'Repartidor',
      nombre: pedido.repartidor!.nombre,
      detalle: pedido.repartidor!.telefono ?? 'Sin teléfono',
      icono: Icons.delivery_dining,
      color: Colors.green,
      fotoPerfil: pedido.repartidor!.fotoPerfil,
      onWhatsapp: pedido.repartidor!.telefono != null
          ? () => _abrirWhatsapp(pedido.repartidor!.telefono, pedido)
          : null,
      onCall: pedido.repartidor!.telefono != null
          ? () => _llamar(pedido.repartidor!.telefono)
          : null,
    );
  }

  Widget _buildContactoCard({
    required String titulo,
    required String nombre,
    required String detalle,
    required IconData icono,
    required Color color,
    String? fotoPerfil,
    VoidCallback? onWhatsapp,
    VoidCallback? onCall,
  }) {
    return _buildSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: fotoPerfil != null && fotoPerfil.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: fotoPerfil,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CupertinoActivityIndicator(radius: 12),
                      errorWidget: (context, url, error) =>
                          Icon(icono, color: color, size: 24),
                    ),
                  )
                : Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          if (onWhatsapp != null)
            IconButton(
              icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
              onPressed: onWhatsapp,
              tooltip: 'Contactar por WhatsApp',
            ),
          if (onCall != null)
            IconButton(
              icon: const Icon(FontAwesomeIcons.phone, color: Colors.blueGrey),
              onPressed: onCall,
              tooltip: 'Llamar',
            ),
        ],
      ),
    );
  }

  Widget _buildEvidenciaCard(Pedido pedido) {
    return _buildSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Foto de Entrega',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            child: Image.network(
              pedido.imagenEvidencia!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelacionCard(Pedido pedido) {
    return _buildSurfaceCard(
      backgroundColor: CupertinoColors.systemRed
          .resolveFrom(context)
          .withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cancel, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Pedido Cancelado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Por', pedido.canceladoPor ?? 'Desconocido'),
          _buildInfoRow(
            'Motivo',
            pedido.motivoCancelacion ?? 'No especificado',
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesCard(Pedido pedido) {
    final isCancelVisible =
        pedido.estado != 'cancelado' && pedido.puedeSerCancelado;
    final isTransfer = pedido.metodoPago.toLowerCase() == 'transferencia';
    final sinComprobante =
        pedido.transferenciaComprobanteUrl == null ||
        pedido.transferenciaComprobanteUrl!.isEmpty;
    final bool repartidorAsignado =
        pedido.repartidor != null || pedido.aceptadoPorRepartidor;
    final bool requierSubirComprobante =
        isTransfer &&
        sinComprobante &&
        repartidorAsignado &&
        pedido.pagoId != null;
    final bool mostrarSubirComprobante = requierSubirComprobante;
    final bool mostrarComprobanteCargado = isTransfer && !sinComprobante;

    if (!isCancelVisible &&
        !mostrarSubirComprobante &&
        !mostrarComprobanteCargado) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mostrarSubirComprobante)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () => _abrirSubirComprobante(pedido),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Subir comprobante'),
              ),
              const SizedBox(height: 6),
              Text(
                'Aqui veras los datos del repartidor para transferir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        if (mostrarSubirComprobante && isCancelVisible)
          const SizedBox(height: 10),
        if (mostrarComprobanteCargado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemGroupedBackground
                  .resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Comprobante registrado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                ),
                if (pedido.transferenciaComprobanteUrl != null)
                  IconButton(
                    onPressed: () async {
                      final url = pedido.transferenciaComprobanteUrl;
                      if (url == null || url.isEmpty) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaVerComprobanteUsuario(
                            comprobanteUrl: url,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    color: Colors.green[700],
                  ),
              ],
            ),
          ),
        if (mostrarComprobanteCargado && isCancelVisible)
          const SizedBox(height: 16),
        if (isCancelVisible)
          OutlinedButton.icon(
            onPressed: _isCancelling
                ? null
                : () => _mostrarDialogoCancelar(pedido),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isCancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CupertinoActivityIndicator(radius: 14),
                  )
                : const Icon(Icons.cancel_outlined),
            label: Text(_isCancelling ? 'Procesando...' : 'Cancelar Pedido'),
          ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceCard({
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  void _mostrarDialogoCancelar(Pedido pedido) async {
    final motivoController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                hintText: 'Ej: Demora mucho',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El motivo es muy corto')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isCancelling = true);

      final success = await context.read<PedidoProvider>().cancelarPedido(
        pedidoId: pedido.id,
        motivo: motivoController.text,
      );

      if (!mounted) return;
      setState(() => _isCancelling = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido cancelado'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar vista para mostrar el nuevo estado
        final provider = context.read<PedidoProvider>();
        provider.limpiarError();
        await provider.cargarDetalle(widget.pedidoId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<PedidoProvider>().error ?? 'Error al cancelar',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirSubirComprobante(Pedido pedido) async {
    if (pedido.pagoId == null) return;
    final pagoId = pedido.pagoId!;

    try {
      final datos = await _pagoService.obtenerDatosBancariosPago(pagoId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PantallaSubirComprobante(pagoId: pagoId, datosBancarios: datos),
        ),
      );
      // Al volver, refrescamos el detalle para actualizar el estado del comprobante
      if (!mounted) return;
      final provider = context.read<PedidoProvider>();
      provider.limpiarError();
      await provider.cargarDetalle(pedido.id);
    } catch (e) {
      if (!mounted) return;

      // Extraer mensaje limpio del error
      String mensaje = 'No se pudo obtener datos bancarios';
      if (e.toString().contains('ApiException:')) {
        // Extraer solo el mensaje de ApiException
        final match = RegExp(
          r'ApiException: (.+?) \|',
        ).firstMatch(e.toString());
        if (match != null) {
          mensaje = match.group(1) ?? mensaje;
        }
      } else {
        mensaje = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmado':
        return Colors.orange;
      case 'en_preparacion':
        return Colors.blue;
      case 'en_ruta':
        return Colors.cyan;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _abrirWhatsapp(String? telefono, Pedido pedido) async {
    if (telefono == null || telefono.isEmpty) return;
    final numero = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final mensaje = Uri.encodeComponent(
      'Hola, soy el cliente del pedido #${pedido.numeroPedido}.',
    );
    final url = Uri.parse('https://wa.me/$numero?text=$mensaje');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _llamar(String? telefono) async {
    if (telefono == null || telefono.isEmpty) return;
    final numero = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$numero');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
