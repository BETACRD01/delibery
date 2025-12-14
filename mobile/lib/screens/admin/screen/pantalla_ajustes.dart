import 'package:flutter/material.dart';

import '../dashboard/constants/dashboard_colors.dart';
import '../../../config/rutas.dart';

class PantallaAjustesAdmin extends StatefulWidget {
  const PantallaAjustesAdmin({super.key});

  @override
  State<PantallaAjustesAdmin> createState() => _PantallaAjustesAdminState();
}

class _PantallaAjustesAdminState extends State<PantallaAjustesAdmin> {
  bool _notificacionesEmail = true;
  bool _notificacionesPush = true;
  bool _modoSilencio = false;
  bool _temaOscuro = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes del Administrador'),
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSection(
            titulo: 'Notificaciones',
            children: [
              _buildSwitchTile(
                title: 'Email',
                subtitle: 'Recibir alertas y reportes por correo',
                value: _notificacionesEmail,
                onChanged: (v) => setState(() => _notificacionesEmail = v),
              ),
              _buildSwitchTile(
                title: 'Push',
                subtitle: 'Avisos en tiempo real sobre operaciones',
                value: _notificacionesPush,
                onChanged: (v) => setState(() => _notificacionesPush = v),
              ),
              _buildSwitchTile(
                title: 'Modo silencio',
                subtitle: 'Desactiva sonidos en horarios nocturnos',
                value: _modoSilencio,
                onChanged: (v) => setState(() => _modoSilencio = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            titulo: 'Preferencias de la app',
            children: [
              _buildSwitchTile(
                title: 'Tema oscuro',
                subtitle: 'Usar paleta oscura en el dashboard',
                value: _temaOscuro,
                onChanged: (v) => setState(() => _temaOscuro = v),
              ),
              _buildActionTile(
                icon: Icons.language,
                title: 'Idioma',
                subtitle: 'Español',
                onTap: _mostrarPendiente,
              ),
              _buildActionTile(
                icon: Icons.dashboard_customize,
                title: 'Personalizar cards',
                subtitle: 'Ordenar o ocultar widgets del dashboard',
                onTap: _mostrarPendiente,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            titulo: 'Seguridad',
            children: [
          _buildActionTile(
            icon: Icons.lock,
            title: 'Cambiar contraseña',
            subtitle: 'Actualiza tu clave de administrador',
            onTap: () => Rutas.irA(context, Rutas.adminCambiarPassword),
          ),
          _buildActionTile(
            icon: Icons.lock_reset,
            title: 'Resetear contraseña de usuario',
            subtitle: 'Clientes, proveedores o repartidores',
            onTap: () => Rutas.irA(context, Rutas.adminResetPasswordUsuario),
          ),
              _buildActionTile(
                icon: Icons.security,
                title: 'Actividad reciente',
                subtitle: 'Revisa ingresos y acciones de tu cuenta',
                onTap: _mostrarPendiente,
              ),
              _buildActionTile(
                icon: Icons.phonelink_lock,
                title: 'Dispositivos conectados',
                subtitle: 'Gestiona sesiones activas',
                onTap: _mostrarPendiente,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardColors.morado,
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                Text(
                  'Panel del administrador',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configura notificaciones, seguridad y apariencia.',
                  style: TextStyle(color: DashboardColors.gris),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: DashboardColors.morado,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: DashboardColors.grisClaro.withValues(alpha: 0.6),
        child: Icon(icon, color: DashboardColors.morado),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _mostrarPendiente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta opción estará disponible pronto'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
