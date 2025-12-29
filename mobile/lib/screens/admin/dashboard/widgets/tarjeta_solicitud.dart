// lib/screens/admin/dashboard/widgets/tarjeta_solicitud.dart
import 'package:flutter/material.dart';
import '../../../../models/solicitud_cambio_rol.dart';
import '../constants/dashboard_colors.dart';

import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';

class TarjetaSolicitud extends StatelessWidget {
  final SolicitudCambioRol solicitud;
  final VoidCallback onTap;

  const TarjetaSolicitud({
    super.key,
    required this.solicitud,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        // No shadow to mimic iOS grouped list items, or very subtle one
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar con icono según el rol
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (solicitud.esProveedor
                                ? DashboardColors.verde
                                : DashboardColors.azul)
                            .withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Icon(
                      solicitud.iconoRol,
                      color: solicitud.esProveedor
                          ? DashboardColors.verde
                          : DashboardColors.azul,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.usuarioNombre ?? solicitud.usuarioEmail,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solicitud.esProveedor
                            ? 'Solicita ser Proveedor'
                            : 'Solicita ser Repartidor',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
