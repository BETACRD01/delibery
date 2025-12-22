// lib/screens/user/carrito/carrito_empty_state.dart

import 'package:flutter/cupertino.dart';
import '../../../theme/jp_theme.dart';

class CarritoEmptyState extends StatelessWidget {
  const CarritoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemBlue(
                  context,
                ).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.cart,
                size: 80,
                color: JPCupertinoColors.systemBlue(
                  context,
                ).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.label(context),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
