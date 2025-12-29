import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/preferencias_provider.dart';
import '../../../../theme/app_colors_primary.dart';
import '../../../config/rutas.dart';

class PantallaAjustesAdmin extends StatefulWidget {
  const PantallaAjustesAdmin({super.key});

  @override
  State<PantallaAjustesAdmin> createState() => _PantallaAjustesAdminState();
}

class _PantallaAjustesAdminState extends State<PantallaAjustesAdmin> {
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: bgColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColorsPrimary.main),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 32),
          _buildSectionHeader('GENERAL'),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              Consumer<PreferenciasProvider>(
                builder: (context, prefs, _) {
                  if (prefs.cargando) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  return Column(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.dark_mode,
                        iconColor: Colors.indigo,
                        title: 'Modo Oscuro',
                        value: Provider.of<ThemeProvider>(context).isDarkMode,
                        onChanged: (v) => Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).toggleTheme(v),
                        isFirst: true,
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        icon: Icons.notifications,
                        iconColor: Colors.redAccent,
                        title: 'Notificaciones Push',
                        value: prefs.notificacionesPush,
                        onChanged: (v) => prefs.updatePush(v),
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        icon: Icons.email,
                        iconColor: Colors.blue,
                        title: 'Notificaciones Email',
                        value: prefs.notificacionesEmail,
                        onChanged: (v) => prefs.updateEmail(v),
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        icon: Icons.do_not_disturb_on,
                        iconColor: Colors.purple,
                        title: 'Modo Silencio',
                        value: prefs.modoSilencio,
                        onChanged: (v) => prefs.updateModoSilencio(v),
                        isLast: true,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('ADMINISTRACIÓN'),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildActionTile(
                icon: Icons.category,
                iconColor: Colors.orange,
                title: 'Categorías',
                onTap: () => Rutas.irA(context, Rutas.adminGestionCategorias),
                isFirst: true,
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.local_shipping,
                iconColor: Colors.teal,
                title: 'Configuración Envíos',
                onTap: () => Rutas.irA(context, Rutas.adminEnviosConfig),
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.devices,
                iconColor: Colors.blueGrey,
                title: 'Dispositivos',
                onTap: () => Rutas.irA(context, Rutas.adminDispositivos),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('SEGURIDAD'),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              _buildActionTile(
                icon: Icons.lock,
                iconColor: Colors.grey,
                title: 'Cambiar Contraseña',
                onTap: () => Rutas.irA(context, Rutas.adminCambiarPassword),
                isFirst: true,
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.lock_reset,
                iconColor: Colors.grey,
                title: 'Reset Password Usuario',
                onTap: () =>
                    Rutas.irA(context, Rutas.adminResetPasswordUsuario),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isFirst ? 10 : 0),
        topRight: Radius.circular(isFirst ? 10 : 0),
        bottomLeft: Radius.circular(isLast ? 10 : 0),
        bottomRight: Radius.circular(isLast ? 10 : 0),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildIcon(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: AppColorsPrimary.main,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isFirst ? 10 : 0),
        topRight: Radius.circular(isFirst ? 10 : 0),
        bottomLeft: Radius.circular(isLast ? 10 : 0),
        bottomRight: Radius.circular(isLast ? 10 : 0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildIcon(icon, iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
