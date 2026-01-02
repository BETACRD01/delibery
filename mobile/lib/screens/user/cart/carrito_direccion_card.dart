// lib/screens/user/carrito/carrito_direccion_card.dart

import 'package:flutter/cupertino.dart';
import '../../../../../theme/primary_colors.dart';
import '../../../theme/jp_theme.dart';

class CarritoDireccionCard extends StatelessWidget {
  final String titulo;
  final String? direccionCompleta;
  final bool esPredeterminada;

  const CarritoDireccionCard({
    super.key,
    required this.titulo,
    required this.direccionCompleta,
    required this.esPredeterminada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColorsPrimary.main.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.location_solid,
              color: AppColorsPrimary.main,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: JPCupertinoColors.label(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (direccionCompleta != null &&
                    direccionCompleta!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    direccionCompleta!,
                    style: TextStyle(
                      fontSize: 13,
                      color: JPCupertinoColors.secondaryLabel(context),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (esPredeterminada) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsPrimary.main.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Predeterminada',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColorsPrimary.main,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
