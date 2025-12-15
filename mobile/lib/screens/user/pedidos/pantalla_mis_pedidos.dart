import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido_model.dart';
import '../../../providers/proveedor_pedido.dart';
import 'pedido_detalle_screen.dart';
import '../../../widgets/util/utils_pedidos.dart'; 

class PantallaMisPedidos extends StatefulWidget {
  const PantallaMisPedidos({super.key});

  @override
  State<PantallaMisPedidos> createState() => _PantallaMisPedidosState();
}

class _PantallaMisPedidosState extends State<PantallaMisPedidos> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPedidos(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _cargarPedidos({bool refresh = false}) {
    context.read<PedidoProvider>().cargarPedidos(
      refresh: refresh,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Cargar más cuando falten 200px para llegar al final
    if (maxScroll - currentScroll <= 200) {
      context.read<PedidoProvider>().cargarPedidos(
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9), // Fondo suave y uniforme
      appBar: AppBar(
        title: const Text('Mis Pedidos', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0.2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => _cargarPedidos(refresh: true),
          )
        ],
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, provider, child) {
          if (provider.error != null && provider.pedidos.isEmpty) {
            return _buildError(provider.error!);
          }

          if (provider.pedidos.isEmpty && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pedidos.isEmpty) {
            return _buildSinPedidos();
          }

          return RefreshIndicator(
            onRefresh: () async => _cargarPedidos(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: provider.pedidos.length + (provider.hasMore ? 1 : 0),
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == provider.pedidos.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return _buildTarjetaPedido(provider.pedidos[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTarjetaPedido(PedidoListItem pedido) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PedidoDetalleScreen(pedidoId: pedido.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: Numero y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pedido.numeroPedido,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  PedidoUtils.buildEstadoBadge(pedido.estado, pedido.estadoDisplay),
                ],
              ),
              const SizedBox(height: 10),

              // Información del proveedor
              if (pedido.proveedorNombre != null)
                _buildInfoRow(Icons.storefront_outlined, pedido.proveedorNombre!),

              const SizedBox(height: 6),
              
              // Fecha y Items
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.calendar_today_outlined,
                      _formatearFecha(pedido.creadoEn),
                    ),
                  ),
                  _buildInfoRow(
                    Icons.shopping_bag_outlined,
                    '${pedido.cantidadItems} items',
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),

              // Footer: Total y Acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text(
                        '\$${pedido.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  _buildBotonAccion(pedido),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonAccion(PedidoListItem pedido) {
    if (pedido.estado == 'en_ruta') {
      return FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PedidoDetalleScreen(pedidoId: pedido.id)),
        ),
        icon: const Icon(Icons.map, size: 16),
        label: const Text('Rastrear'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    return TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PedidoDetalleScreen(pedidoId: pedido.id)),
      ),
      child: const Text('Ver Detalles'),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Algo salió mal', style: TextStyle(fontSize: 18, color: Colors.grey[800])),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                context.read<PedidoProvider>().limpiarError();
                _cargarPedidos(refresh: true);
              },
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinPedidos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('No hay pedidos', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])
          ),
          const SizedBox(height: 8),
          Text(
            'Desliza hacia abajo o toca actualizar para recargar',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    // Función simple de formateo, idealmente usar intl
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
