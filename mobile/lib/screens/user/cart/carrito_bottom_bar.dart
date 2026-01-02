// lib/screens/user/carrito/carrito_bottom_bar.dart

import 'package:flutter/cupertino.dart';
import '../../../theme/jp_theme.dart';

class CarritoBottomBar extends StatelessWidget {
  final String subtotalText;
  final bool loading;
  final VoidCallback onContinuar;

  const CarritoBottomBar({
    super.key,
    required this.subtotalText,
    required this.loading,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 16,
                    color: JPCupertinoColors.secondaryLabel(context),
                  ),
                ),
                Text(
                  subtotalText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: JPCupertinoColors.label(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: loading ? null : onContinuar,
                child: const Text(
                  'Continuar al Pago',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
