import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/pedido_model.dart';
import '../../../providers/proveedor_pedido.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final int pedidoId;

  const PedidoDetalleScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  bool _isCancelling = false;

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

                  if (pedido.repartidor != null) ...[
                    _buildRepartidorCard(pedido),
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

  // --- WIDGETS DE UI (Cards y Secciones) ---

  Widget _buildHeaderStatus(Pedido pedido) {
    final color = _getColorEstado(pedido.estado);
    final subtotal = pedido.items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final comision = pedido.gananciaApp;
    final envio = pedido.datosEnvio;
    final costoEnvio = envio?.costoEnvio ?? 0;
    final recargoNocturno = (envio?.recargoNocturnoAplicado ?? false) ? (envio?.recargoNocturno ?? 0) : 0;
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const Text('Productos', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...pedido.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.cantidad}x ${item.productoNombre}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )),
            const Divider(height: 20),
            _buildInfoRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
            if (costoEnvio > 0) _buildInfoRow('Costo de envío', '\$${costoEnvio.toStringAsFixed(2)}'),
            if (recargoNocturno > 0) _buildInfoRow('Recargo nocturno', '\$${recargoNocturno.toStringAsFixed(2)}'),
            if (comision > 0) _buildInfoRow('Comisión de servicio', '\$${comision.toStringAsFixed(2)}'),
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
            _buildRowIcon(Icons.location_on, 'Entrega', pedido.direccionEntrega),
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
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
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
        title: Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
            child: Text('Foto de Entrega', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Image.network(
              pedido.imagenEvidencia!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(
                height: 200, 
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
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
                Text('Pedido Cancelado', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900], fontSize: 16)
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Por', pedido.canceladoPor ?? 'Desconocido'),
            _buildInfoRow('Motivo', pedido.motivoCancelacion ?? 'No especificado'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesCard(Pedido pedido) {
    if (pedido.estado == 'cancelado' || !pedido.puedeSerCancelado) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isCancelling ? null : () => _mostrarDialogoCancelar(pedido),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _isCancelling 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.cancel_outlined),
        label: Text(_isCancelling ? 'Procesando...' : 'Cancelar Pedido'),
      ),
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
                  const SnackBar(content: Text('El motivo es muy corto'))
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
          const SnackBar(content: Text('Pedido cancelado'), backgroundColor: Colors.green)
        );
        // Recargar vista para mostrar el nuevo estado
        final provider = context.read<PedidoProvider>();
        provider.limpiarError();
        provider.cargarDetalle(widget.pedidoId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<PedidoProvider>().error ?? 'Error al cancelar'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmado': return Colors.orange;
      case 'en_preparacion': return Colors.blue;
      case 'en_ruta': return Colors.cyan;
      case 'entregado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _abrirWhatsapp(String? telefono, Pedido pedido) async {
    if (telefono == null || telefono.isEmpty) return;
    final numero = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final mensaje = Uri.encodeComponent(
        'Hola, soy el cliente del pedido #${pedido.numeroPedido}.');
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
