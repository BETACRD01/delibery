// lib/screens/user/carrito/carrito_header.dart

import 'package:flutter/cupertino.dart';
import '../../../../../theme/primary_colors.dart';
import '../../../theme/jp_theme.dart';

class CarritoHeader extends StatelessWidget {
  final int cantidadItems;
  final int cantidadTotal;

  const CarritoHeader({
    super.key,
    required this.cantidadItems,
    required this.cantidadTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.cart_fill,
            color: AppColorsPrimary.main,
          ),
          const SizedBox(width: 12),
          Text(
            '$cantidadItems productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: JPCupertinoColors.label(context),
            ),
          ),
          const Spacer(),
          Text(
            '$cantidadTotal items',
            style: TextStyle(
              fontSize: 14,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}
