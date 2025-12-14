
// lib/screens/admin/dashboard/widgets/solicitudes_section.dart
import 'package:flutter/material.dart';
import '../../../../controllers/admin/dashboard_controller.dart';
import '../constants/dashboard_colors.dart';
import '../../../../config/rutas.dart';
import '../../../../models/solicitud_cambio_rol.dart';
import 'tarjeta_solicitud.dart';
import 'detalle_solicitud_modal.dart';

class SolicitudesSection extends StatelessWidget {
  final DashboardController controller;

  const SolicitudesSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tarjeta de resumen
        _buildTarjetaResumen(context),
        const SizedBox(height: 16),

        // Lista de solicitudes (máximo 5)
        ...controller.solicitudesPendientes.take(5).map((solicitud) {
          return TarjetaSolicitud(
            solicitud: solicitud,
            onTap: () => _mostrarDetalleSolicitud(context, solicitud),
          );
        }),

        // Ver todas las solicitudes
        if (controller.solicitudesPendientesCount > 5) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Rutas.irA(context, Rutas.adminSolicitudesRol);
            },
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              'Ver todas (${controller.solicitudesPendientesCount} solicitudes)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTarjetaResumen(BuildContext context) {
    return Card(
      elevation: 2,
      color: DashboardColors.naranja.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DashboardColors.naranja, width: 2),
      ),
      child: InkWell(
        onTap: () {
          Rutas.irA(context, Rutas.adminSolicitudesRol);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardColors.naranja,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_late,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.solicitudesPendientesCount} solicitudes pendientes de revisión',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Toca aquí para revisar y aprobar',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: DashboardColors.naranja),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleSolicitud(
    BuildContext context,
    SolicitudCambioRol solicitud,
  ) {
    DetalleSolicitudModal.mostrar(
      context: context,
      solicitud: solicitud,
      onAceptar: () async {
        await controller.aceptarSolicitud(solicitud.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Solicitud aceptada exitosamente'),
              backgroundColor: DashboardColors.verde,
            ),
          );
        }
      },
      onRechazar: (motivo) async {
        await controller.rechazarSolicitud(solicitud.id, motivo);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Solicitud rechazada'),
              backgroundColor: DashboardColors.naranja,
            ),
          );
        }
      },
    );
  }
}