// lib/screens/user/perfil/solicitudes_rol/widgets/tarjeta_seleccion_rol.dart

import 'package:flutter/cupertino.dart';
import '../../../../../models/solicitud_cambio_rol.dart';

/// 🎴 TARJETA PARA SELECCIONAR ROL
/// Diseño: iOS Native Style
class TarjetaSeleccionRol extends StatelessWidget {
  final RolSolicitable rol;
  final bool seleccionado;
  final VoidCallback onTap;

  const TarjetaSeleccionRol({
    super.key,
    required this.rol,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Definir color según el rol
    final color = rol == RolSolicitable.proveedor
        ? CupertinoColors.systemBlue
        : CupertinoColors.systemGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado
                ? color
                : CupertinoColors.separator.resolveFrom(context),
            width: seleccionado ? 2.5 : 1,
          ),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ícono + Título + Checkmark
            Row(
              children: [
                // Icono circular
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(rol.icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),

                // Título del Rol
                Expanded(
                  child: Text(
                    rol.label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: seleccionado
                          ? color
                          : CupertinoColors.label.resolveFrom(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // Checkmark circular
                Icon(
                  seleccionado
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: seleccionado
                      ? color
                      : CupertinoColors.systemGrey3.resolveFrom(context),
                  size: 28,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Divider sutil
            Container(
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),

            const SizedBox(height: 16),

            // Descripción
            Text(
              _getDescripcion(rol),
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                height: 1.4,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 16),

            // Beneficios en chips
            _buildBeneficios(rol, color, context),
          ],
        ),
      ),
    );
  }

  String _getDescripcion(RolSolicitable rol) {
    return rol == RolSolicitable.proveedor
        ? 'Vende tus productos, gestiona tu inventario y llega a más clientes.'
        : 'Realiza entregas en tu zona, maneja tus horarios y gana comisiones.';
  }

  Widget _buildBeneficios(
    RolSolicitable rol,
    Color color,
    BuildContext context,
  ) {
    final beneficios = rol == RolSolicitable.proveedor
        ? [
            {'icon': CupertinoIcons.cube_box, 'text': 'Catálogo propio'},
            {'icon': CupertinoIcons.graph_square, 'text': 'Estadísticas'},
            {'icon': CupertinoIcons.money_dollar_circle, 'text': 'Más ventas'},
          ]
        : [
            {'icon': CupertinoIcons.clock, 'text': 'Horario flexible'},
            {'icon': CupertinoIcons.money_dollar, 'text': 'Gana por envío'},
            {'icon': CupertinoIcons.location, 'text': 'Tu zona'},
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: beneficios.map((beneficio) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: seleccionado
                ? color.withValues(alpha: 0.1)
                : CupertinoColors.tertiarySystemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
            border: seleccionado
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                beneficio['icon'] as IconData,
                size: 16,
                color: seleccionado
                    ? color
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 6),
              Text(
                beneficio['text'] as String,
                style: TextStyle(
                  color: seleccionado
                      ? color
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.08,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
