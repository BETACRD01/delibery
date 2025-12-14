// lib/screens/supplier/tabs/promociones_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/promocion_model.dart';
import '../screens/pantalla_promociones_proveedor.dart';

class PromocionesTab extends StatelessWidget {
  const PromocionesTab({super.key});

  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, _) {
        if (!controller.verificado) {
          return _buildEstadoVacio(
            icono: Icons.verified_user_outlined,
            titulo: 'Verificación pendiente',
            mensaje: 'Debes estar verificado para gestionar promociones.',
          );
        }

        if (controller.promociones.isEmpty) {
          return _buildEstadoVacio(
            icono: Icons.campaign_outlined,
            titulo: 'Sin promociones',
            mensaje: 'Crea tu primera promoción para destacar en el catálogo.',
            accion: FilledButton.icon(
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear promoción'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refrescarProductos(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.promociones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final promo = controller.promociones[index];
              return _buildPromoCard(context, promo);
            },
          ),
        );
      },
    );
  }

  Widget _buildPromoCard(BuildContext context, PromocionModel promo) {
    final color = promo.color;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildImagen(promo.imagenUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.titulo,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  promo.descripcion,
                  style: const TextStyle(fontSize: 12, color: _textoSecundario),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  promo.descuento,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                if (promo.textoTiempoRestante.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    promo.textoTiempoRestante,
                    style: const TextStyle(fontSize: 11, color: _textoSecundario),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAccion(context, value, promo),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'toggle', child: Text(promo.activa ? 'Desactivar' : 'Activar')),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagen(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 60,
        height: 60,
        color: Colors.white,
        child: url != null && url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24);

  Widget _buildEstadoVacio({
    required IconData icono,
    required String titulo,
    required String mensaje,
    Widget? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 64, color: _textoSecundario.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: _textoSecundario)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Promoción eliminada' : 'No se pudo eliminar'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Promoción actualizada' : 'No se pudo actualizar'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }
}
