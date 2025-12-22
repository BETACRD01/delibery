// lib/screens/user/carrito/carrito_resumen_row.dart

import 'package:flutter/cupertino.dart';
import '../../../theme/jp_theme.dart';

class ResumenRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const ResumenRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: JPCupertinoColors.label(context),
              ),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: JPCupertinoColors.label(context),
            ),
          ),
        ],
      ),
    );
  }
}
