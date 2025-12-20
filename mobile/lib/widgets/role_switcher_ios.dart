// lib/widgets/role_switcher_ios.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoleSwitcherIOS extends StatelessWidget {
  final Map<String, String> opciones;
  final String? rolSeleccionado;
  final bool cargando;
  final ValueChanged<String> onChanged;

  const RoleSwitcherIOS({
    super.key,
    required this.opciones,
    required this.rolSeleccionado,
    required this.onChanged,
    this.cargando = false,
  });

  IconData _iconForRole(String rol) {
    switch (rol.toUpperCase()) {
      case 'PROVEEDOR':
        return CupertinoIcons.cube_box_fill;
      case 'REPARTIDOR':
        return CupertinoIcons.car_fill;
      default:
        return CupertinoIcons.person_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (opciones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No hay roles disponibles',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 14,
          ),
        ),
      );
    }

    final selected = opciones.keys.contains(rolSeleccionado)
        ? rolSeleccionado
        : opciones.keys.first;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: opciones.entries.map((entry) {
          final isSelected = entry.key == selected;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CupertinoColors.systemBackground.resolveFrom(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iconForRole(entry.key),
                      size: 16,
                      color: isSelected
                          ? CupertinoColors.systemBlue.resolveFrom(context)
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? CupertinoColors.systemBlue.resolveFrom(context)
                            : CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
