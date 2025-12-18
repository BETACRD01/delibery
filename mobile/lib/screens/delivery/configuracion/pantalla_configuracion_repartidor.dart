// lib/screens/delivery/configuracion/pantalla_configuracion_repartidor.dart

import 'package:flutter/material.dart';

import '../../../services/usuarios_service.dart';

/// ⚙️ Pantalla de Configuración del Repartidor con lenguaje visual iOS.
class PantallaConfiguracionRepartidor extends StatefulWidget {
  const PantallaConfiguracionRepartidor({super.key});

  @override
  State<PantallaConfiguracionRepartidor> createState() =>
      _PantallaConfiguracionRepartidorState();
}

class _PantallaConfiguracionRepartidorState
    extends State<PantallaConfiguracionRepartidor> {
  static const Color _background = Color(0xFFF2F4F8);
  static const Color _cardSurface = Colors.white;
  static const Color _accent = Color(0xFF0A84FF);
  static const Color _success = Color(0xFF34C759);
  static const Color _danger = Color(0xFFEA3E3E);
  static const double _cardRadius = 18;

  final UsuarioService _usuarioService = UsuarioService();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool notificacionesPush = true;
  bool notificacionesEmail = true;
  bool notificacionesMarketing = true;
  bool modoOscuro = false;
  bool ubicacionEnTiempoReal = true;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await _usuarioService.obtenerPreferenciasNotificaciones();
      if (!mounted) return;
      setState(() {
        notificacionesPush = prefs['notificaciones_push'] ?? true;
        notificacionesEmail = prefs['notificaciones_email'] ?? true;
        notificacionesMarketing = prefs['notificaciones_marketing'] ?? true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las preferencias: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _actualizarPreferencia(String clave, bool valor) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = await _usuarioService
          .actualizarPreferenciasNotificaciones({clave: valor});
      if (!mounted) return;
      setState(() {
        notificacionesPush = resp['notificaciones_push'] ?? notificacionesPush;
        notificacionesEmail = resp['notificaciones_email'] ?? notificacionesEmail;
        notificacionesMarketing =
            resp['notificaciones_marketing'] ?? notificacionesMarketing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferencias guardadas'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error guardando preferencias: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron guardar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          'Preferencias del repartidor',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Controla tus alertas, tono y hábitos desde un entorno limpio.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 18),
                        if (_error != null) _buildErrorBanner(),
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alertas y avisos',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Divider(height: 24),
                              _buildSwitchTile(
                                title: 'Notificaciones push',
                                subtitle: 'Alertas de nuevos pedidos',
                                value: notificacionesPush,
                                enabled: !_busy,
                                onChanged: (v) =>
                                    _actualizarPreferencia('notificaciones_push', v),
                              ),
                              _buildSwitchTile(
                                title: 'Email',
                                subtitle: 'Novedades y reportes',
                                value: notificacionesEmail,
                                enabled: !_busy,
                                onChanged: (v) =>
                                    _actualizarPreferencia('notificaciones_email', v),
                              ),
                              _buildSwitchTile(
                                title: 'Promociones',
                                subtitle: 'Ofertas y recordatorios',
                                value: notificacionesMarketing,
                                enabled: !_busy,
                                onChanged: (v) => _actualizarPreferencia(
                                    'notificaciones_marketing', v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preferencias de la app',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Divider(height: 24),
                              _buildSwitchTile(
                                title: 'Modo oscuro',
                                subtitle: 'Encender el tema oscuro',
                                value: modoOscuro,
                                thumbColor: _accent,
                                onChanged: (v) => setState(() => modoOscuro = v),
                              ),
                              _buildSwitchTile(
                                title: 'Ubicación en vivo',
                                subtitle: 'Actualizar posición automáticamente',
                                value: ubicacionEnTiempoReal,
                                thumbColor: _accent,
                                onChanged: (v) =>
                                    setState(() => ubicacionEnTiempoReal = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Soporte y privacidad',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Divider(height: 24),
                              _buildListTile(
                                icon: Icons.privacy_tip,
                                title: 'Política de privacidad',
                                onTap: () => _mostrarDialogoBasico(
                                  context,
                                  'Política de Privacidad',
                                  'Tu información siempre está cifrada y solo se usa para mejorar el servicio.',
                                ),
                              ),
                              _buildListTile(
                                icon: Icons.description,
                                title: 'Términos del servicio',
                                onTap: () => _mostrarDialogoBasico(
                                  context,
                                  'Términos del Servicio',
                                  'Usar la aplicación implica aceptar las reglas establecidas para repartidores.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildResetButton(),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFDDE4F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    Color? thumbColor,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: thumbColor ?? _success,
      activeTrackColor: (thumbColor ?? _success).withValues(alpha: 0.45),
      inactiveTrackColor: Colors.grey[300],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: _accent.withValues(alpha: 0.12),
        child: Icon(icon, color: _accent, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.restart_alt),
        label: const Text('Restablecer configuración'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _danger,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          setState(() {
            notificacionesPush = true;
            notificacionesEmail = true;
            notificacionesMarketing = true;
            modoOscuro = false;
            ubicacionEnTiempoReal = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración restablecida'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: _danger,
            onPressed: _cargarPreferencias,
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoBasico(
    BuildContext context,
    String titulo,
    String contenido,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(contenido),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
