import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../controllers/user/perfil_controller.dart';

/// 🔔 PANTALLA DE GESTIÓN DE NOTIFICACIONES
/// Diseño: Clean UI
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  late final PerfilController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PerfilController();
    _controller.cargarDatosCompletos(); // Cargar estado actual de las notificaciones
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: JPColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Si está cargando, mostrar indicador
          if (_controller.isLoading && !_controller.tieneDatos) {
            return const Center(child: CircularProgressIndicator(color: JPColors.primary));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elige qué notificaciones deseas recibir',
                  style: TextStyle(color: JPColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchItem(
                        icon: Icons.notifications_active_outlined,
                        title: 'Pedidos y Entregas',
                        subtitle: 'Actualizaciones sobre el estado de tu orden',
                        value: _controller.perfil?.notificacionesPedido ?? true,
                        onChanged: (v) => _controller.actualizarNotificaciones(notificacionesPedido: v),
                      ),
                      Divider(height: 1, indent: 50, color: Colors.grey.shade100),
                      _buildSwitchItem(
                        icon: Icons.local_offer_outlined,
                        title: 'Promociones y Ofertas',
                        subtitle: 'Descuentos exclusivos y novedades',
                        value: _controller.perfil?.notificacionesPromociones ?? true,
                        onChanged: (v) => _controller.actualizarNotificaciones(notificacionesPromociones: v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: JPColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: JPColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: JPColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: JPColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: JPColors.textSecondary),
            )
          : null,
    );
  }
}