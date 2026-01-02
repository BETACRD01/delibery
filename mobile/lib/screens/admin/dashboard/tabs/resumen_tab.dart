// lib/screens/admin/dashboard/tabs/resumen_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/admin/dashboard_controller.dart';
import '../../../../providers/core/theme_provider.dart';
import '../../../../theme/primary_colors.dart';
import '../widgets/estadisticas_grid.dart';
import '../widgets/solicitudes_section.dart';

class ResumenTab extends StatelessWidget {
  const ResumenTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        return RefreshIndicator(
          onRefresh: controller.cargarDatos,
          color: AppColorsPrimary.main,
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSeccionTitulo('Estadísticas Generales', isDark),
                    const SizedBox(height: 12),
                    EstadisticasGrid(controller: controller),
                    const SizedBox(height: 32),
                    if (controller.solicitudesPendientesCount > 0) ...[
                      _buildSeccionTitulo('Solicitudes Pendientes', isDark),
                      const SizedBox(height: 12),
                      SolicitudesSection(controller: controller),
                      const SizedBox(height: 24),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeccionTitulo(String titulo, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
