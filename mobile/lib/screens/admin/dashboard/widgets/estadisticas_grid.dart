// lib/screens/admin/dashboard/widgets/estadisticas_grid.dart
import 'package:flutter/material.dart';
import '../../../../controllers/admin/dashboard_controller.dart';
import '../constants/dashboard_colors.dart';
import '../../../../config/rutas.dart';

import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';

class EstadisticasGrid extends StatelessWidget {
  final DashboardController controller;

  const EstadisticasGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildCardEstadistica(
          context,
          'Usuarios',
          controller.totalUsuarios.toString(),
          Icons.people,
          DashboardColors.azul,
          '+12 este mes',
          isDark,
        ),
        _buildCardEstadistica(
          context,
          'Proveedores',
          controller.totalProveedores.toString(),
          Icons.store,
          DashboardColors.verde,
          '${controller.proveedoresPendientes} pendientes',
          isDark,
        ),
        InkWell(
          onTap: () {
            controller.marcarSolicitudesPendientesVistas();
            Rutas.irA(context, Rutas.adminSolicitudesRol);
          },
          borderRadius: BorderRadius.circular(16),
          child: _buildCardEstadistica(
            context,
            'Solicitudes',
            controller.solicitudesPendientesCount.toString(),
            Icons.assignment,
            DashboardColors.naranja,
            'Pendientes',
            isDark,
          ),
        ),
        _buildCardEstadistica(
          context,
          'Repartidores',
          controller.totalRepartidores.toString(),
          Icons.delivery_dining,
          DashboardColors.naranja,
          '${controller.totalRepartidores - 2} activos',
          isDark,
        ),
        _buildCardEstadistica(
          context,
          'Ventas',
          '\$${controller.ventasTotales.toStringAsFixed(0)}', // Removed cents for cleaner look
          Icons.attach_money,
          DashboardColors.verde,
          '+8% vs mes anterior',
          isDark,
        ),
        _buildCardEstadistica(
          context,
          'Pedidos',
          controller.pedidosActivos.toString(),
          Icons.shopping_cart,
          DashboardColors.morado,
          'En proceso',
          isDark,
        ),
      ],
    );
  }

  Widget _buildCardEstadistica(
    BuildContext context,
    String titulo,
    String valor,
    IconData icono,
    Color color,
    String subtitulo,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: color, size: 20),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
