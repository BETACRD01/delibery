// lib/screens/supplier/tabs/promociones_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/promocion_model.dart';
import '../screens/pantalla_promociones_proveedor.dart';

class PromocionesTab extends StatefulWidget {
  const PromocionesTab({super.key});

  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  State<PromocionesTab> createState() => _PromocionesTabState();
}

class _PromocionesTabState extends State<PromocionesTab> {
  static const Color _alerta = Color(0xFFF59E0B);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, _) {
        if (!controller.verificado) {
          return _buildEstadoVacio(
            icono: Icons.verified_user_outlined,
            titulo: 'Verificación pendiente',
            mensaje: 'Debes estar verificado para gestionar promociones.',
            color: _alerta,
            accion: FilledButton.icon(
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear promoción'),
            ),
          );
        }

        if (controller.error != null) {
          return _buildErrorState(context, controller);
        }

        if (controller.promociones.isEmpty) {
          return _buildEstadoVacio(
            icono: Icons.campaign_outlined,
            titulo: 'Sin promociones',
            mensaje: 'Crea tu primera promoción para destacar en el catálogo.',
            color: PromocionesTab._textoSecundario,
            accion: FilledButton.icon(
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear promoción'),
            ),
          );
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(child: _buildHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final promo = controller.promociones[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPromoCard(context, controller, promo),
                    );
                  },
                  childCount: controller.promociones.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promociones activas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Destaca tus productos con banners, envíos o combos',
                style: TextStyle(fontSize: 14, color: PromocionesTab._textoSecundario),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => _abrirFormulario(context),
          icon: const Icon(Icons.add),
          label: const Text('Nueva promo'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    SupplierController controller,
    PromocionModel promo,
  ) {
    return GestureDetector(
      onTap: () => _abrirFormulario(context, promo: promo),
      child: Container(
        decoration: BoxDecoration(
          color: promo.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: promo.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildBanner(promo),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.titulo,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: promo.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    promo.descripcion,
                    style: const TextStyle(fontSize: 14, color: PromocionesTab._textoSecundario),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(promo),
                      const SizedBox(width: 8),
                      if (promo.textoTiempoRestante.isNotEmpty)
                        Text(
                          promo.textoTiempoRestante,
                          style: const TextStyle(fontSize: 12, color: PromocionesTab._textoSecundario),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        promo.descuento,
                        style: TextStyle(fontWeight: FontWeight.w700, color: promo.color),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleAccion(context, value, promo),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'editar', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(promo.activa ? 'Desactivar' : 'Publicar'),
                          ),
                          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(PromocionModel promo) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        color: promo.color.withValues(alpha: 0.12),
        image: promo.imagenUrl != null
            ? DecorationImage(
                image: NetworkImage(promo.imagenUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          promo.activa ? 'Activa' : 'Pausada',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildChip(PromocionModel promo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: promo.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        promo.tipoNavegacion.toUpperCase(),
        style: TextStyle(fontSize: 11, color: promo.color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEstadoVacio({
    required IconData icono,
    required String titulo,
    required String mensaje,
    required Color color,
    Widget? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 64, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: PromocionesTab._textoSecundario)),
            if (accion != null) ...[
              const SizedBox(height: 16),
              accion,
            ],
          ],
        ),
      ),
    );
  }

  void _handleAccion(BuildContext context, String value, PromocionModel promo) {
    switch (value) {
      case 'editar':
        _abrirFormulario(context, promo: promo);
        break;
      case 'eliminar':
        _confirmarEliminar(context, promo);
        break;
      case 'toggle':
        _toggleActiva(context, promo);
        break;
    }
  }

  void _openSnack(BuildContext context, String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  void _abrirFormulario(BuildContext context, {PromocionModel? promo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => buildFormularioPromocion(promo: promo),
    );
  }

  void _confirmarEliminar(BuildContext context, PromocionModel promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar promoción'),
        content: Text('¿Eliminar "${promo.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<SupplierController>().eliminarPromocion(int.parse(promo.id));
              if (!context.mounted) return;
              _openSnack(context, ok ? 'Promoción eliminada' : 'No se pudo eliminar', ok ? Colors.green : Colors.red);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActiva(BuildContext context, PromocionModel promo) async {
    final ok = await context.read<SupplierController>().cambiarEstadoPromocion(int.parse(promo.id), !promo.activa);
    if (!context.mounted) return;
    _openSnack(context, ok ? 'Promoción actualizada' : 'No se pudo actualizar', ok ? Colors.green : Colors.red);
  }

  Widget _buildErrorState(BuildContext context, SupplierController controller) {
    final mensaje = controller.error ?? 'No se pudo cargar la información de promociones.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 14),
            const Text(
              'Ups, algo salió mal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: PromocionesTab._textoSecundario),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () => controller.refrescarProductos(),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _mostrarDetalleError(context, mensaje),
                  child: const Text('Ver detalles'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalleError(BuildContext context, String mensaje) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle del error'),
        content: Text(
          mensaje,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

}
