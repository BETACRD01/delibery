// lib/widgets/cards/jp_order_card.dart

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 📦 ORDER CARD - Card de pedido unificada estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

/// Card de pedido con estilo iOS consistente
///
/// Características:
/// - BorderRadius 14px
/// - Sombra sutil adaptativa
/// - Header: número de pedido + badge de estado
/// - Info rows: proveedor, fecha, items
/// - Divider sutil
/// - Footer: total + botón de acción
/// - Tap: navegación con CupertinoPageRoute (sin ripple)
class JPOrderCard extends StatelessWidget {
  final String numeroPedido;
  final String estado;
  final String? estadoDisplay;
  final String? proveedorNombre;
  final DateTime creadoEn;
  final int cantidadItems;
  final double total;
  final VoidCallback? onTap;
  final Widget? actionButton;

  const JPOrderCard({
    super.key,
    required this.numeroPedido,
    required this.estado,
    this.estadoDisplay,
    this.proveedorNombre,
    required this.creadoEn,
    required this.cantidadItems,
    required this.total,
    this.onTap,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: JPCupertinoColors.surface(context),
          borderRadius: BorderRadius.circular(JPConstants.radiusCard),
          boxShadow: JPConstants.cardShadow(context),
        ),
        padding: const EdgeInsets.all(JPConstants.spacingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: número + badge estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#$numeroPedido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                ),
                _buildEstadoBadge(context),
              ],
            ),
            const SizedBox(height: JPConstants.spacingItem),
            // Info rows
            if (proveedorNombre != null) ...[
              _buildInfoRow(
                context,
                icon: CupertinoIcons.cube_box,
                text: proveedorNombre!,
              ),
              const SizedBox(height: 6),
            ],
            _buildInfoRow(
              context,
              icon: CupertinoIcons.calendar,
              text: _formatFecha(creadoEn),
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              context,
              icon: CupertinoIcons.bag,
              text: '$cantidadItems item${cantidadItems > 1 ? 's' : ''}',
            ),
            // Divider
            const SizedBox(height: JPConstants.spacingItem),
            Container(
              height: 0.5,
              color: JPCupertinoColors.separator(context),
            ),
            const SizedBox(height: JPConstants.spacingItem),
            // Footer: total + botón
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: JPCupertinoColors.secondaryLabel(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: JPCupertinoColors.label(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionButton != null) actionButton!,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          size: JPConstants.iconSizeSmall,
          color: JPCupertinoColors.secondaryLabel(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    final (color, displayText) = _getEstadoColorAndText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _getEstadoColorAndText() {
    final displayText = estadoDisplay ?? _getDefaultEstadoDisplay(estado);

    // Retornar (color, texto)
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return (const Color(0xFFFF9500), displayText); // Orange
      case 'confirmado':
        return (const Color(0xFF007AFF), displayText); // Blue
      case 'en_preparacion':
        return (const Color(0xFF00C7BE), displayText); // Cyan
      case 'en_ruta':
        return (const Color(0xFF34C759), displayText); // Green
      case 'entregado':
        return (const Color(0xFF34C759), displayText); // Green
      case 'cancelado':
        return (const Color(0xFFFF3B30), displayText); // Red
      default:
        return (const Color(0xFF8E8E93), displayText); // Grey
    }
  }

  String _getDefaultEstadoDisplay(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmado':
        return 'Confirmado';
      case 'en_preparacion':
        return 'En Preparación';
      case 'en_ruta':
        return 'En Ruta';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inDays == 0) {
      if (diff.inHours < 1) {
        return 'Hace ${diff.inMinutes} min';
      }
      return 'Hace ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(fecha);
    }
  }
}
