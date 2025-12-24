// lib/screens/supplier/tabs/promociones_tab.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/promocion_model.dart';
import '../../../theme/app_colors_primary.dart';
import '../screens/pantalla_promociones_proveedor.dart';

class PromocionesTab extends StatefulWidget {
  const PromocionesTab({super.key});

  @override
  State<PromocionesTab> createState() => _PromocionesTabState();
}

class _PromocionesTabState extends State<PromocionesTab> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        child: SafeArea(
          child: Consumer<SupplierController>(
            builder: (context, controller, _) {
              // Mostrar indicador de carga tipo iOS mientras se cargan los datos
              if (controller.loading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(radius: 14),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando...',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!controller.verificado) {
                return _buildEstadoVacio(
                  context,
                  icon: CupertinoIcons.checkmark_seal,
                  titulo: 'Verificación pendiente',
                  mensaje: 'Debes estar verificado para gestionar promociones.',
                  color: CupertinoColors.activeOrange,
                );
              }

              if (controller.error != null) {
                return _buildErrorState(context, controller);
              }

              if (controller.promociones.isEmpty) {
                return _buildEstadoVacio(
                  context,
                  icon: CupertinoIcons.tag,
                  titulo: 'Sin promociones',
                  mensaje:
                      'Crea tu primera promoción para destacar en el catálogo.',
                  color: CupertinoColors.systemGrey,
                  showButton: true,
                );
              }

              return Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => controller.refrescar(),
                      color: AppColorsPrimary.main,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: controller.promociones.length,
                        itemBuilder: (context, index) {
                          final promo = controller.promociones[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPromoCard(context, controller, promo),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promociones',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Destaca tus productos con ofertas especiales',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _abrirFormulario(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColorsPrimary.main,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    SupplierController controller,
    PromocionModel promo,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _mostrarOpcionesPromo(context, promo),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            _buildBanner(context, promo),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          promo.titulo,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildBadgeEstado(promo.activa),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    promo.descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip(promo),
                      const SizedBox(width: 8),
                      if (promo.textoTiempoRestante.isNotEmpty)
                        Expanded(
                          child: Text(
                            promo.textoTiempoRestante,
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        promo.descuento,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: promo.color,
                        ),
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

  Widget _buildBanner(BuildContext context, PromocionModel promo) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(color: promo.color.withValues(alpha: 0.15)),
        child: promo.imagenUrl != null
            ? Image.network(
                promo.imagenUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildBannerPlaceholder(promo),
              )
            : _buildBannerPlaceholder(promo),
      ),
    );
  }

  Widget _buildBannerPlaceholder(PromocionModel promo) {
    return Center(
      child: Icon(
        CupertinoIcons.tag_fill,
        size: 40,
        color: promo.color.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildBadgeEstado(bool activa) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activa
            ? CupertinoColors.activeGreen.withValues(alpha: 0.15)
            : CupertinoColors.systemGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        activa ? 'Activa' : 'Pausada',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: activa
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildChip(PromocionModel promo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: promo.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        promo.tipoNavegacion.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: promo.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEstadoVacio(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String mensaje,
    required Color color,
    bool showButton = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            if (showButton) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: () => _abrirFormulario(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Crear Promoción'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SupplierController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 48,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error ?? 'No se pudo cargar las promociones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => controller.refrescar(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Reintentar'),
                ],
              ),
            ),
          ],
        ),
      ),
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

  void _mostrarOpcionesPromo(BuildContext context, PromocionModel promo) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(promo.titulo),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _abrirFormulario(context, promo: promo);
            },
            child: const Text('Editar'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleActiva(context, promo);
            },
            child: Text(
              promo.activa ? 'Pausar promoción' : 'Activar promoción',
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmarEliminar(context, promo);
            },
            child: const Text('Eliminar'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, PromocionModel promo) {
    // Guardamos referencia al controller ANTES de abrir el diálogo
    final controller = context.read<SupplierController>();

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar promoción'),
        content: Text('¿Estás seguro de eliminar "${promo.titulo}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await controller.eliminarPromocion(
                int.parse(promo.id),
              );
              if (!context.mounted) return;
              _showToast(
                context,
                ok ? 'Promoción eliminada' : 'Error al eliminar',
                ok,
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActiva(BuildContext context, PromocionModel promo) async {
    final ok = await context.read<SupplierController>().cambiarEstadoPromocion(
      int.parse(promo.id),
      !promo.activa,
    );
    if (!context.mounted) return;
    _showToast(
      context,
      ok ? 'Promoción actualizada' : 'Error al actualizar',
      ok,
    );
  }

  void _showToast(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? CupertinoColors.activeGreen
            : CupertinoColors.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
