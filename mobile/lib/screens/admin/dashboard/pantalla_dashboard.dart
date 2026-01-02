import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../config/routing/rutas.dart';
import '../../../controllers/admin/dashboard_controller.dart';
import '../../../theme/app_colors_primary.dart';
import '../../../providers/core/theme_provider.dart';
import 'tabs/actividad_tab.dart';
import 'tabs/resumen_tab.dart';
import 'widgets/dashboard_drawer.dart';
import '../../../services/auth/session_cleanup.dart';
import 'constants/dashboard_colors.dart';

class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({super.key});

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends State<PantallaDashboard> {
  int _currentIndex = 0;
  late DashboardController _controller;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.cargarDatos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _seleccionarYSubirFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (!mounted) return;
        Navigator.pop(context); // Cerrar drawer antes de mostrar loading/error

        await _controller.actualizarFotoPerfil(File(image.path));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto de perfil actualizada'),
            backgroundColor: DashboardColors.verde,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: DashboardColors.rojo,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DashboardController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: bgColor,
            drawer: DashboardDrawer(
              usuario: controller.usuario,
              solicitudesPendientesCount: controller.solicitudesPendientesCount,
              onSeccionNoDisponible: _mostrarSeccionNoDisponible,
              onCerrarSesion: _cerrarSesion,
              onActualizarFoto: _seleccionarYSubirFoto,
              onSolicitudesTap: () async {
                Navigator.pop(context); // Cerrar drawer
                controller.marcarSolicitudesPendientesVistas();
                await Rutas.irA(context, Rutas.adminSolicitudesRol);
              },
            ),
            appBar: AppBar(
              title: const Text('Dashboard'),
              backgroundColor: bgColor,
              scrolledUnderElevation: 0,
              centerTitle: true,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              actions: [
                if (controller.solicitudesPendientesCount > 0)
                  IconButton(
                    icon: Badge(
                      label: Text('${controller.solicitudesPendientesCount}'),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: AppColorsPrimary.main,
                      ),
                    ),
                    onPressed: () async {
                      controller.marcarSolicitudesPendientesVistas();
                      await Rutas.irA(context, Rutas.adminSolicitudesRol);
                    },
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: AppColorsPrimary.main,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'No hay notificaciones pendientes',
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.settings, color: AppColorsPrimary.main),
                  onPressed: () => Rutas.irA(context, Rutas.adminAjustes),
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: bgColor,
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _currentIndex,
                      children: const {
                        0: Text('Resumen'),
                        1: Text('Actividad'),
                      },
                      onValueChanged: (val) {
                        setState(() {
                          _currentIndex = val ?? 0;
                        });
                      },
                      thumbColor: isDark
                          ? const Color(0xFF636366)
                          : Colors.white,
                      backgroundColor: isDark
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFF767680).withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Expanded(
                  child: controller.loading
                      ? const Center(child: CupertinoActivityIndicator())
                      : controller.error != null
                      ? _buildError(controller)
                      : _currentIndex == 0
                      ? const ResumenTab()
                      : const ActividadTab(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(DashboardController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            controller.error ?? 'Error desconocido',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            child: const Text('Reintentar'),
            onPressed: () => controller.cargarDatos(),
          ),
        ],
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
      if (!mounted) return;
      await SessionCleanup.clearProviders(context);
      await _controller.cerrarSesion();
      if (!mounted) return;
      await Rutas.irAYLimpiar(context, Rutas.login);
    }
  }
}
