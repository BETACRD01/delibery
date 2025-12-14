// lib/screens/admin/dashboard/widgets/dashboard_drawer.dart
import 'package:flutter/material.dart';
import '../constants/dashboard_colors.dart';
import '../../../../config/rutas.dart';

class DashboardDrawer extends StatelessWidget {
  final Map<String, dynamic>? usuario;
  final int solicitudesPendientesCount;
  final Function(String) onSeccionNoDisponible;
  final VoidCallback onCerrarSesion;

  const DashboardDrawer({
    super.key,
    required this.usuario,
    required this.solicitudesPendientesCount,
    required this.onSeccionNoDisponible,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            color: DashboardColors.morado,
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          _buildMenuItem(
            context,
            icon: Icons.people,
            title: 'Gestión de Usuarios',
            color: DashboardColors.azul,
            onTap: () {
              Navigator.pop(context);
              Rutas.irA(context, Rutas.adminUsuariosGestion);
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.store,
            title: 'Proveedores',
            color: DashboardColors.verde,
            onTap: () {
              Navigator.pop(context);
              Rutas.irA(context, Rutas.adminProveedoresGestion);
            },
          ),
          _buildSolicitudesMenuItem(context),
          _buildMenuItem(
            context,
            icon: Icons.delivery_dining,
            title: 'Repartidores',
            color: DashboardColors.naranja,
            onTap: () {
              Navigator.pop(context);
              Rutas.irA(context, Rutas.adminRepartidoresGestion);
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.card_giftcard,
            title: 'Gestión de Rifas',
            color: Colors.purple,
            onTap: () {
              Navigator.pop(context);
              Rutas.irA(context, Rutas.adminRifasGestion);
            },
          ),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: 'Configuración',
            color: DashboardColors.gris,
            onTap: () {
              Navigator.pop(context);
              Rutas.irA(context, Rutas.adminAjustes);
            },
          ),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            color: DashboardColors.rojo,
            onTap: onCerrarSesion,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [DashboardColors.morado, DashboardColors.moradoOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      currentAccountPicture: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.admin_panel_settings, size: 40, color: DashboardColors.morado),
      ),
      accountName: Text(
        '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      accountEmail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(usuario?['email'] ?? ''),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ADMINISTRADOR',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _buildSolicitudesMenuItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.assignment, color: DashboardColors.naranja),
      title: const Text('Solicitudes de Rol'),
      trailing: solicitudesPendientesCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: DashboardColors.rojo,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$solicitudesPendientesCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        Rutas.irA(context, Rutas.adminSolicitudesRol);
      },
    );
  }
}
