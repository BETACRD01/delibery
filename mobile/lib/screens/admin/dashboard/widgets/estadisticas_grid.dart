// lib/screens/admin/dashboard/widgets/estadisticas_grid.dart
import 'package:flutter/material.dart';
import '../../../../controllers/admin/dashboard_controller.dart';
import '../constants/dashboard_colors.dart';
import '../../../../config/rutas.dart';

class EstadisticasGrid extends StatelessWidget {
  final DashboardController controller;

  const EstadisticasGrid({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2, // Cambiado de 1.5 a 1.2 para dar más altura
      children: [
        _buildCardEstadistica(
          'Usuarios Totales',
          controller.totalUsuarios.toString(),
          Icons.people,
          DashboardColors.azul,
          '+12 este mes',
        ),
        _buildCardEstadistica(
          'Proveedores',
          controller.totalProveedores.toString(),
          Icons.store,
          DashboardColors.verde,
          '${controller.proveedoresPendientes} pendientes',
        ),
        InkWell(
          onTap: () {
            controller.marcarSolicitudesPendientesVistas();
            Rutas.irA(context, Rutas.adminSolicitudesRol);
          },
          borderRadius: BorderRadius.circular(16),
          child: _buildCardEstadistica(
            'Solicitudes',
            controller.solicitudesPendientesCount.toString(),
            Icons.assignment,
            DashboardColors.naranja,
            'Pendientes de revisar',
          ),
        ),
        _buildCardEstadistica(
          'Repartidores',
          controller.totalRepartidores.toString(),
          Icons.delivery_dining,
          DashboardColors.naranja,
          '${controller.totalRepartidores - 2} activos',
        ),
        _buildCardEstadistica(
          'Ventas Totales',
          '\$${controller.ventasTotales.toStringAsFixed(2)}',
          Icons.attach_money,
          DashboardColors.verde,
          '+8% vs mes anterior',
        ),
        _buildCardEstadistica(
          'Pedidos Activos',
          controller.pedidosActivos.toString(),
          Icons.shopping_cart,
          DashboardColors.morado,
          'En proceso',
        ),
      ],
    );
  }
}

  Widget _buildCardEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    String subtitulo,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10), // Reducido de 16 a 10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color, size: 20), // Reducido de 24 a 20
            ),
            const Spacer(), // Reemplaza mainAxisAlignment.spaceBetween
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18, // Reducido de 20 a 18
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]), // Reducido de 12 a 11
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]), // Reducido de 10 a 9
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
