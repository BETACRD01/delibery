// lib/screens/admin/dashboard/tabs/resumen_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/admin/dashboard_controller.dart';
import '../widgets/estadisticas_grid.dart';
import '../widgets/solicitudes_section.dart';

class ResumenTab extends StatelessWidget {
  const ResumenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        return RefreshIndicator(
          onRefresh: controller.cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeccionTitulo('Estadísticas Generales'),
                const SizedBox(height: 12),
                EstadisticasGrid(controller: controller),
                const SizedBox(height: 24),
                if (controller.solicitudesPendientesCount > 0) ...[
                  _buildSeccionTitulo('Solicitudes Pendientes de Aprobación'),
                  const SizedBox(height: 12),
                  SolicitudesSection(controller: controller),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
