// lib/screens/admin/dashboard/widgets/dashboard_app_bar.dart
import 'package:flutter/material.dart';
import '../constants/dashboard_colors.dart';
import '../../../../config/rutas.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final int solicitudesPendientesCount;
  final VoidCallback onRefresh;

  const DashboardAppBar({
    super.key,
    required this.tabController,
    required this.solicitudesPendientesCount,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Panel de Administración'),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [DashboardColors.morado, DashboardColors.moradoOscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        _buildNotificationButton(context),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Actualizar',
        ),
      ],
      bottom: TabBar(
        controller: tabController,
        indicatorColor: Colors.white,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Resumen', icon: Icon(Icons.dashboard, size: 20)),
          Tab(text: 'Actividad', icon: Icon(Icons.history, size: 20)),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            if (solicitudesPendientesCount > 0) {
              Rutas.irA(context, Rutas.adminSolicitudesRol);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No hay notificaciones pendientes'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          tooltip: solicitudesPendientesCount > 0
              ? 'Ver $solicitudesPendientesCount solicitudes pendientes'
              : 'Sin notificaciones',
        ),
        if (solicitudesPendientesCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: DashboardColors.rojo,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$solicitudesPendientesCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
