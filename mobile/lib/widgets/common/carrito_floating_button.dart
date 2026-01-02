// lib/widgets/common/carrito_floating_button.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:provider/provider.dart';

import '../../config/routing/rutas.dart';
import '../../providers/cart/proveedor_carrito.dart';
import '../../theme/app_colors_primary.dart';

/// FAB del Carrito estilo iOS
///
/// Muestra un botón flotante con el ícono del carrito y la cantidad de items.
/// Este widget debe aparecer en las pantallas de inicio y navegación.
class CarritoFloatingButton extends StatelessWidget {
  const CarritoFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Consumer<ProveedorCarrito>(
        builder: (context, carrito, _) {
          final cantidad = carrito.cantidadTotal;

          return GestureDetector(
            onTap: () => Rutas.irACarrito(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono del carrito con badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        CupertinoIcons.cart_fill,
                        color: AppColorsPrimary.main,
                        size: 24,
                      ),
                      if (cantidad > 0)
                        Positioned(
                          right: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 20),
                            child: Text(
                              cantidad > 9 ? '9+' : '$cantidad',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Texto "Mi Pedido"
                  Text(
                    'Mi Pedido',
                    style: TextStyle(
                      color: AppColorsPrimary.main,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
