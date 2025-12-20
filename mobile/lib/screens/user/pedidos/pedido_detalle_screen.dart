import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/pedido_model.dart';
import '../../../providers/proveedor_pedido.dart';
import '../../../services/pago_service.dart';
import 'pantalla_subir_comprobante.dart';
import '../../../widgets/ratings/dialogo_calificar_repartidor.dart';
import '../../../widgets/ratings/dialogo_calificar_producto.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final int pedidoId;

  const PedidoDetalleScreen({super.key, required this.pedidoId});

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  bool _isCancelling = false;
  final bool _enviandoCalificacion = false;
  bool _enviandoCalificacionProveedor = false;
  // Obsoleto: flujos de calificación migrados a DialogoCalificarProducto
  // bool _enviandoCalificacionProducto = false;
  final TextEditingController _comentarioCtrl = TextEditingController();
  final TextEditingController _comentarioProveedorCtrl =
      TextEditingController();
  final TextEditingController _comentarioProductoCtrl = TextEditingController();
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
  void dispose() {
    _comentarioCtrl.dispose();
    _comentarioProveedorCtrl.dispose();
    _comentarioProductoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Pedido #${widget.pedidoId}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, provider, child) {
          // CORRECCIÓN 2: Prioridad a la Carga
          // Si está cargando, mostramos el círculo SIEMPRE,
          // ignorando cualquier error viejo que pueda existir en memoria.
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
        color: Colors.white,
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
          const Icon(Icons.star_rate_rounded, color: Colors.amber),
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
                        repartidorNombre: pedido.repartidor?.nombre ?? 'Repartidor',
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
        color: Colors.white,
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
        color: Colors.white,
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
          const Icon(Icons.store_mall_directory_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Califica los productos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: _enviandoCalificacionProveedor
                ? null
                : () => _mostrarSheetCalificacionProveedor(pedido),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Productos calificados: ${pedido.calificacionProveedor?.toStringAsFixed(1) ?? ''} ⭐',
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estado Actual',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
            const Text(
              'Productos',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...pedido.items.map((item) {
              final comentario = item.calificacionProductoInfo?.comentario;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductoItemRow(item, pedido),
                  if (comentario != null && comentario.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 6),
                      child: Text(
                        comentario,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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
            _buildInfoRow('Total', '\$${pedido.total.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }

  Widget _buildDireccionesCard(Pedido pedido) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (pedido.direccionOrigen != null) ...[
              _buildRowIcon(Icons.store, 'Retiro', pedido.direccionOrigen!),
              const SizedBox(height: 12),
            ],
            _buildRowIcon(
              Icons.location_on,
              'Entrega',
              pedido.direccionEntrega,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowIcon(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductoItemRow(ItemPedido item, Pedido pedido) {
    final rating = item.calificacionProductoInfo?.estrellas;
    final bool puedeCalificar =
        item.puedeCalificarProducto && pedido.estado == 'entregado';

    return InkWell(
      onTap: puedeCalificar
          ? () async {
              final result = await showCupertinoModalPopup<bool>(
                context: context,
                builder: (context) => DialogoCalificarProducto(
                  pedidoId: pedido.id,
                  items: [item],
                ),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            }
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '${item.cantidad}x ${item.productoNombre}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (rating != null) ...[
            _buildStarsRow(rating),
            const SizedBox(width: 6),
            Text(
              '${rating.toStringAsFixed(1)} ⭐',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
          ],
          if (rating == null && puedeCalificar)
            OutlinedButton(
              onPressed: () async {
                final result = await showCupertinoModalPopup<bool>(
                  context: context,
                  builder: (context) => DialogoCalificarProducto(
                    pedidoId: pedido.id,
                    items: [item],
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Calificar', style: TextStyle(fontSize: 12)),
            ),
          Text(
            '\$${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStarsRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return Icon(
          isFilled ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildRepartidorCard(Pedido pedido) {
    return _buildContactoCard(
      titulo: 'Repartidor',
      nombre: pedido.repartidor!.nombre,
      detalle: pedido.repartidor!.telefono ?? 'Sin teléfono',
      icono: Icons.delivery_dining,
      color: Colors.green,
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
    VoidCallback? onWhatsapp,
    VoidCallback? onCall,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onWhatsapp != null)
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.green),
                onPressed: onWhatsapp,
                tooltip: 'Contactar por WhatsApp',
              ),
            if (onCall != null)
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.blueGrey),
                onPressed: onCall,
                tooltip: 'Llamar',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenciaCard(Pedido pedido) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Foto de Entrega',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Image.network(
              pedido.imagenEvidencia!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
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
    return Card(
      color: Colors.red[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    color: Colors.red[900],
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
            label: const Text('Subir comprobante de transferencia'),
          ),
        if (mostrarSubirComprobante && isCancelVisible)
          const SizedBox(height: 10),
        if (mostrarComprobanteCargado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      if (url != null && await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    icon: const Icon(Icons.visibility),
                    color: Colors.green[700],
                  ),
              ],
            ),
          ),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Flexible(
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
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
        provider.cargarDetalle(widget.pedidoId);
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

  // Obsoleto: reemplazado por DialogoCalificarRepartidor
  // Future<void> _mostrarSheetCalificacion(Pedido pedido) async {}


  Future<void> _mostrarSheetCalificacionProveedor(Pedido pedido) async {
    double rating = 5;
    _comentarioProveedorCtrl.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Califica los productos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isFilled = index < rating;
                      return IconButton(
                        iconSize: 34,
                        onPressed: () =>
                            setStateModal(() => rating = index + 1.0),
                        icon: Icon(
                          isFilled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.orange,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comentarioProveedorCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Comentario (opcional)',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _enviandoCalificacionProveedor
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              await _enviarCalificacionProveedor(
                                pedido,
                                rating.round(),
                                _comentarioProveedorCtrl.text,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _enviandoCalificacionProveedor
                            ? 'Enviando...'
                            : 'Enviar',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Obsoleto: reemplazado por DialogoCalificarProducto
  // Future<void> _mostrarSheetCalificacionProducto(
  //   Pedido pedido,
  //   ItemPedido item,
  // ) async {}


  Future<void> _enviarCalificacionProveedor(
    Pedido pedido,
    int rating,
    String comentario,
  ) async {
    setState(() => _enviandoCalificacionProveedor = true);
    final provider = context.read<PedidoProvider>();

    final ok = await provider.calificarProveedor(
      pedidoId: pedido.id,
      estrellas: rating,
      comentario: comentario,
    );

    setState(() => _enviandoCalificacionProveedor = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu calificación!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al calificar'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener datos bancarios: $e')),
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
