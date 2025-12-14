// lib/screens/admin/pantalla_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/rutas.dart';
import '../../controllers/admin/dashboard_controller.dart';
import 'dashboard/widgets/dashboard_app_bar.dart';
import 'dashboard/widgets/dashboard_drawer.dart';
import 'dashboard/tabs/resumen_tab.dart';
import 'dashboard/tabs/actividad_tab.dart';
import 'dashboard/constants/dashboard_colors.dart';

class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({super.key});

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends State<PantallaDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = DashboardController();
    _controller.cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DashboardController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: DashboardAppBar(
              tabController: _tabController,
              solicitudesPendientesCount: controller.solicitudesPendientesCount,
              onRefresh: () => controller.cargarDatos(),
            ),
            drawer: DashboardDrawer(
              usuario: controller.usuario,
              solicitudesPendientesCount: controller.solicitudesPendientesCount,
              onSeccionNoDisponible: _mostrarSeccionNoDisponible,
              onCerrarSesion: _cerrarSesion,
            ),
            body: controller.loading
                ? _buildCargando()
                : controller.error != null
                    ? _buildError(controller)
                    : _buildContenido(),
          );
        },
      ),
    );
  }

  Widget _buildContenido() {
    return TabBarView(
      controller: _tabController,
      children: const [
        ResumenTab(),
        ActividadTab(),
      ],
    );
  }

  Widget _buildCargando() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: DashboardColors.morado),
          SizedBox(height: 16),
          Text('Cargando dashboard...'),
        ],
      ),
    );
  }

  Widget _buildError(DashboardController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DashboardColors.rojo.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              controller.error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.cargarDatos(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSeccionNoDisponible(String seccion) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$seccion estará disponible pronto'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await Rutas.mostrarDialogo<bool>(
      context,
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Rutas.volver(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Rutas.volver(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardColors.rojo,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _controller.cerrarSesion();
      if (mounted) {
        Rutas.irAYLimpiar(context, Rutas.login);
      }
    }
  }
}
