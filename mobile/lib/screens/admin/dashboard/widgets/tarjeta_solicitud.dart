// lib/screens/admin/dashboard/widgets/tarjeta_solicitud.dart
import 'package:flutter/material.dart';
import '../../../../models/solicitud_cambio_rol.dart';
import '../constants/dashboard_colors.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar con icono según el rol
              CircleAvatar(
                radius: 24,
                backgroundColor: solicitud.esProveedor
                    ? DashboardColors.verde
                    : DashboardColors.azul,
                child: Icon(
                  solicitud.iconoRol,
                  color: Colors.white,
                  size: 24,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          solicitud.iconoRol,
                          size: 14,
                          color: DashboardColors.gris,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          solicitud.rolTexto,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DashboardColors.gris,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: DashboardColors.gris,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          solicitud.diasPendienteTexto ?? 'Hoy',
                          style: const TextStyle(
                            fontSize: 12,
                            color: DashboardColors.gris,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: solicitud.colorEstado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: solicitud.colorEstado,
                    width: 1,
                  ),
                ),
                child: Text(
                  solicitud.estadoTexto,
                  style: TextStyle(
                    color: solicitud.colorEstado,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}