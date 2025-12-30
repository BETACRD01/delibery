import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/jp_theme.dart';

/// Card específica para pedidos tipo Courier (Encargos)
/// Muestra origen -> destino y detalles del paquete
class JPCourierCard extends StatelessWidget {
  final String numeroPedido;
  final String estado;
  final String estadoDisplay;
  final String direccionOrigen;
  final String direccionDestino;
  final DateTime creadoEn;
  final double total;
  final VoidCallback? onTap;
  final Widget? actionButton;

  const JPCourierCard({
    super.key,
    required this.numeroPedido,
    required this.estado,
    required this.estadoDisplay,
    required this.direccionOrigen,
    required this.direccionDestino,
    required this.creadoEn,
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
            // Header: Icono Courier + #Pedido + Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.cube_box_fill,
                    size: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Encargo #$numeroPedido',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                ),
                _buildEstadoBadge(context),
              ],
            ),

            const SizedBox(height: 12),

            // Ruta: Origen -> Destino
            _buildRutaVisual(context),

            const SizedBox(height: 12),

            // Fecha
            Row(
              children: [
                Icon(
                  CupertinoIcons.time,
                  size: 14,
                  color: JPCupertinoColors.secondaryLabel(context),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatFecha(creadoEn),
                  style: TextStyle(
                    fontSize: 12,
                    color: JPCupertinoColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: JPConstants.spacingItem),
            Container(height: 0.5, color: JPCupertinoColors.separator(context)),
            const SizedBox(height: JPConstants.spacingItem),

            // Footer
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

  Widget _buildRutaVisual(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPuntoRuta(
          context,
          icon: Icons.my_location,
          color: CupertinoColors.systemGrey,
          text: direccionOrigen,
          isOrigin: true,
        ),
        Container(
          margin: const EdgeInsets.only(left: 11),
          height: 12,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: JPCupertinoColors.separator(context),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
          ),
        ),
        _buildPuntoRuta(
          context,
          icon: Icons.location_on,
          color: CupertinoColors.activeBlue,
          text: direccionDestino,
          isOrigin: false,
        ),
      ],
    );
  }

  Widget _buildPuntoRuta(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    required bool isOrigin,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: JPCupertinoColors.label(context),
              fontWeight: isOrigin ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    Color color;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = const Color(0xFFFF9500);
        break;
      case 'en_ruta':
        color = const Color(0xFF34C759);
        break;
      case 'entregado':
        color = const Color(0xFF34C759);
        break;
      case 'cancelado':
        color = const Color(0xFFFF3B30);
        break;
      default:
        color = const Color(0xFF8E8E93);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        estadoDisplay,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inDays == 0) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}
