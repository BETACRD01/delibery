// lib/screens/delivery/configuracion/pantalla_configuracion_repartidor.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/usuarios/usuarios_service.dart';

/// ⚙️ Pantalla de Configuración del Repartidor con lenguaje visual iOS.
class PantallaConfiguracionRepartidor extends StatefulWidget {
  const PantallaConfiguracionRepartidor({super.key});

  @override
  State<PantallaConfiguracionRepartidor> createState() =>
      _PantallaConfiguracionRepartidorState();
}

class _PantallaConfiguracionRepartidorState
    extends State<PantallaConfiguracionRepartidor> {
  static const Color _accent = Color(0xFF0CB7F2); // Celeste corporativo
  static const Color _success = Color(0xFF34C759);
  static const Color _danger = Color(0xFFFF3B30);

  // Dynamic Colors
  Color get _background =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);
  Color get _cardSurface =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
  Color get _textPrimary => CupertinoColors.label.resolveFrom(context);

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
      final resp = await _usuarioService.actualizarPreferenciasNotificaciones({
        clave: valor,
      });
      if (!mounted) return;
      setState(() {
        notificacionesPush = resp['notificaciones_push'] ?? notificacionesPush;
        notificacionesEmail =
            resp['notificaciones_email'] ?? notificacionesEmail;
        notificacionesMarketing =
            resp['notificaciones_marketing'] ?? notificacionesMarketing;
      });
      _mostrarToast(
        'Preferencias guardadas',
        icono: CupertinoIcons.checkmark_circle_fill,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error guardando preferencias: $e';
      });
      _mostrarToast(
        'No se pudieron guardar',
        color: _danger,
        icono: CupertinoIcons.exclamationmark_circle_fill,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _mostrarToast(String mensaje, {IconData? icono, Color? color}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color ?? _success,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _background,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Configuración'),
          backgroundColor: _cardSurface,
          border: const Border(
            bottom: BorderSide(color: Color(0x4D000000), width: 0.0),
          ), // Sin borde visible o muy sutil
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CupertinoActivityIndicator(radius: 14))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferencias',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Personaliza tu experiencia de entrega.',
                              style: TextStyle(
                                fontSize: 16,
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_error != null) _buildErrorBanner(),

                            _buildSectionHeader('ALERTAS Y AVISOS'),
                            _buildSectionGroup([
                              _buildSwitchRow(
                                title: 'Notificaciones push',
                                icon: CupertinoIcons.bell_fill,
                                color: _accent,
                                value: notificacionesPush,
                                onChanged: (v) => _actualizarPreferencia(
                                  'notificaciones_push',
                                  v,
                                ),
                              ),
                              _buildDivider(),
                              _buildSwitchRow(
                                title: 'Email',
                                icon: CupertinoIcons.mail_solid,
                                color: CupertinoColors.systemIndigo,
                                value: notificacionesEmail,
                                onChanged: (v) => _actualizarPreferencia(
                                  'notificaciones_email',
                                  v,
                                ),
                              ),
                              _buildDivider(),
                              _buildSwitchRow(
                                title: 'Promociones',
                                icon: CupertinoIcons.tag_fill,
                                color: CupertinoColors.systemOrange,
                                value: notificacionesMarketing,
                                onChanged: (v) => _actualizarPreferencia(
                                  'notificaciones_marketing',
                                  v,
                                ),
                              ),
                            ]),

                            const SizedBox(height: 24),
                            _buildSectionHeader('APP'),
                            _buildSectionGroup([
                              _buildSwitchRow(
                                title: 'Modo oscuro',
                                icon: CupertinoIcons.moon_fill,
                                color: CupertinoColors.black,
                                value: modoOscuro,
                                onChanged: (v) =>
                                    setState(() => modoOscuro = v),
                              ),
                              _buildDivider(),
                              _buildSwitchRow(
                                title: 'Ubicación en vivo',
                                icon: CupertinoIcons.location_solid,
                                color: _success,
                                value: ubicacionEnTiempoReal,
                                onChanged: (v) =>
                                    setState(() => ubicacionEnTiempoReal = v),
                              ),
                            ]),

                            const SizedBox(height: 24),
                            _buildSectionHeader('LEGAL'),
                            _buildSectionGroup([
                              _buildNavigationRow(
                                title: 'Política de privacidad',
                                icon: CupertinoIcons.hand_raised_fill,
                                color: CupertinoColors.systemBlue,
                                onTap: () => _mostrarDialogoBasico(
                                  context,
                                  'Política de Privacidad',
                                  'Tu información siempre está cifrada y solo se usa para mejorar el servicio.',
                                ),
                              ),
                              _buildDivider(),
                              _buildNavigationRow(
                                title: 'Términos del servicio',
                                icon: CupertinoIcons.doc_text_fill,
                                color: CupertinoColors.systemGrey,
                                onTap: () => _mostrarDialogoBasico(
                                  context,
                                  'Términos del Servicio',
                                  'Usar la aplicación implica aceptar las reglas establecidas para repartidores.',
                                ),
                              ),
                            ]),

                            const SizedBox(height: 40),
                            _buildResetButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildSectionGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 54, // Alineado con el texto, dejando espacio para el icono
      color: CupertinoColors.separator,
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Más alto para iOS feel
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                color: CupertinoColors.label,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: _accent,
            onChanged: _busy ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.label,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: CupertinoColors.systemGrey3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        disabledColor: CupertinoColors.quaternarySystemFill,
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: BorderRadius.circular(12),
        onPressed: () {
          setState(() {
            notificacionesPush = true;
            notificacionesEmail = true;
            notificacionesMarketing = true;
            modoOscuro = false;
            ubicacionEnTiempoReal = true;
          });
          _mostrarToast(
            'Configuración restablecida',
            icono: CupertinoIcons.refresh_bold,
          );
        },
        child: const Text(
          'Restablecer configuración',
          style: TextStyle(
            color: _danger,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: _danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: _danger)),
          ),
          CupertinoButton(
            onPressed: _cargarPreferencias,
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.refresh, color: _danger),
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
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(
        title: Text(titulo),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(contenido),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text('Cerrar', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }
}
