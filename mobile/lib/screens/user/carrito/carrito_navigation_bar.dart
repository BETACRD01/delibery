// lib/screens/user/carrito/carrito_navigation_bar.dart

import 'package:flutter/cupertino.dart';
import '../../../theme/jp_theme.dart';

class CarritoNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  final bool estaVacio;
  final VoidCallback onLimpiar;

  const CarritoNavigationBar({
    super.key,
    required this.estaVacio,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: JPCupertinoColors.surface(context),
      middle: const Text('Mi Carrito'),
      trailing: estaVacio
          ? const SizedBox.shrink()
          : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onLimpiar,
              child: Icon(
                CupertinoIcons.trash,
                color: JPCupertinoColors.systemRed(context),
              ),
            ),
      border: Border(
        bottom: BorderSide(
          color: JPCupertinoColors.separator(context),
          width: 0.5,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return true;
  }
}
