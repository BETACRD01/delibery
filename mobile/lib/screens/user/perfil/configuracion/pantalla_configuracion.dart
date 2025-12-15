// lib/screens/user/perfil/configuracion/pantalla_configuracion.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart' hide JPSnackbar;
import '../../../../../services/auth_service.dart';
import '../../../../../services/solicitudes_service.dart';
import '../../../../../models/solicitud_cambio_rol.dart';
import '../../../../../config/rutas.dart';
import '../../../../../widgets/jp_snackbar.dart';
import '../../../../../l10n/app_localizations.dart';
import 'ayuda/pantalla_ayuda_soporte.dart';
import '../../../solicitudes_rol/pantalla_solicitar_rol.dart';
import 'ayuda/pantalla_terminos.dart';
import 'idioma/pantalla_idioma.dart';
import 'notificaciones/pantalla_notificaciones.dart';
import 'direcciones/pantalla_lista_direcciones.dart';
import 'seguridad/dialogo_cambiar_password.dart';

class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({super.key});

  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  static const _celeste = Color(0xFF2DAAE1);
  static const _celesteSuave = Color(0xFFE5F5FD);
  static const _naranja = Color(0xFFFF8A3D);

  final _authService = AuthService();
  final _solicitudesService = SolicitudesService();

  List<String> _rolesActivos = [];
  final Map<String, SolicitudCambioRol> _ultimasSolicitudes = {};

  bool _isLoading = true;
  String? _rolSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarDatosCompletos();
  }

  Future<void> _cargarDatosCompletos() async {
    try {
      final authResponse = await _authService.obtenerRolesDisponibles();
      List<String> rolesActivos = [];

      if (authResponse.containsKey('roles')) {
        final listaRoles = authResponse['roles'] as List;
        for (var item in listaRoles) {
          if (item is String) {
            rolesActivos.add(item);
          } else if (item is Map) {
            rolesActivos.add(item['nombre']);
          }
        }
      }

      final solicitudesResponse = await _solicitudesService.obtenerMisSolicitudes();
      Map<String, SolicitudCambioRol> mapaSolicitudes = {};

      List<dynamic>? listaSol;
      if (solicitudesResponse.containsKey('results')) {
        listaSol = solicitudesResponse['results'];
      } else if (solicitudesResponse['solicitudes'] != null) {
        listaSol = solicitudesResponse['solicitudes'];
      }

      if (listaSol != null) {
        for (var json in listaSol) {
          final sol = SolicitudCambioRol.fromJson(json);
          if (!mapaSolicitudes.containsKey(sol.rolSolicitado)) {
            mapaSolicitudes[sol.rolSolicitado] = sol;
          }
        }
      }

      if (mounted) {
        setState(() {
          _rolesActivos = rolesActivos;
          _ultimasSolicitudes.addAll(mapaSolicitudes);
          _rolSeleccionado = _obtenerPrimerRolActivo();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) JPSnackbar.error(context, 'Error cargando configuración');
    }
  }

  String? _obtenerPrimerRolActivo() {
    if (_rolesActivos.contains('PROVEEDOR')) return 'PROVEEDOR';
    if (_rolesActivos.contains('REPARTIDOR')) return 'REPARTIDOR';
    return null;
  }

  bool get _esProveedorActivo => _rolesActivos.contains('PROVEEDOR');
  bool get _esRepartidorActivo => _rolesActivos.contains('REPARTIDOR');

  bool _tieneEstadoVisible(String rol) {
    if (_rolesActivos.contains(rol)) return false;
    final sol = _ultimasSolicitudes[rol];
    if (sol == null) return false;
    return sol.estaPendiente || sol.fueRechazada;
  }

  bool _mostrarOportunidad(String rol) {
    if (_rolesActivos.contains(rol)) return false;
    final sol = _ultimasSolicitudes[rol];
    if (sol != null && sol.estaPendiente) return false;
    return true;
  }

  // ==========================================================
  // UI PRINCIPAL MEJORADA (DISEÑO)
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.2,
        shadowColor: Colors.black12,
        foregroundColor: JPColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: JPColors.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_esProveedorActivo || _esRepartidorActivo) ...[
                    _buildSectionTitle('Modo de trabajo'),
                    const SizedBox(height: 8),
                    _buildRoleSelector(),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildDiagnosticPanel(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_tieneEstadoVisible('PROVEEDOR') || _tieneEstadoVisible('REPARTIDOR')) ...[
                    _buildSectionTitle('Estado de solicitudes'),
                    const SizedBox(height: 10),
                    if (_tieneEstadoVisible('PROVEEDOR')) _buildStatusCard('PROVEEDOR'),
                    if (_tieneEstadoVisible('REPARTIDOR')) _buildStatusCard('REPARTIDOR'),
                    const SizedBox(height: 22),
                  ],

                  if (_mostrarOportunidad('PROVEEDOR') || _mostrarOportunidad('REPARTIDOR')) ...[
                    _buildSectionTitle('Oportunidades'),
                    const SizedBox(height: 10),
                    if (_mostrarOportunidad('PROVEEDOR'))
                      _buildOpportunityCard(
                        title: 'Quiero ser Proveedor',
                        subtitle: 'Publica tus productos',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFFFF8C00),
                      ),
                    if (_mostrarOportunidad('PROVEEDOR') && _mostrarOportunidad('REPARTIDOR'))
                      const SizedBox(height: 12),
                    if (_mostrarOportunidad('REPARTIDOR'))
                      _buildOpportunityCard(
                        title: 'Quiero ser Repartidor',
                        subtitle: 'Gana dinero extra',
                        icon: Icons.two_wheeler_rounded,
                        color: _celeste,
                      ),
                    const SizedBox(height: 22),
                  ],

                  _buildSectionTitle(l10n.account),
                  const SizedBox(height: 10),
                  _buildSettingsContainer([
                    _buildSettingsTile(
                      icon: Icons.location_on_outlined,
                      title: l10n.myAddresses,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaListaDirecciones()),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Cambiar Contraseña',
                      onTap: _mostrarDialogoCambiarPassword,
                    ),
                  ]),
                  const SizedBox(height: 22),

                  _buildSectionTitle('General'),
                  const SizedBox(height: 10),
                  _buildSettingsContainer([
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.notifications,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaNotificaciones()),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: l10n.language,
                      trailingText: _getLanguageName(context),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaIdioma()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),

                  _buildSectionTitle('Soporte'),
                  const SizedBox(height: 10),
                  _buildSettingsContainer([
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: l10n.helpSupport,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaAyudaSoporte()),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      title: l10n.termsConditions,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaTerminos()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ==========================================================
  // WIDGETS PERSONALIZADOS - DISEÑO COMPACTO
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7A90),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _celesteSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _celeste.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          if (_esProveedorActivo)
            Expanded(
              child: _buildRoleTab(
                label: 'Proveedor',
                icon: Icons.storefront,
                color: const Color(0xFFFF8C00),
                isSelected: _rolSeleccionado == 'PROVEEDOR',
                onTap: () => setState(() => _rolSeleccionado = 'PROVEEDOR'),
              ),
            ),
          if (_esProveedorActivo && _esRepartidorActivo) const SizedBox(width: 4),
          if (_esRepartidorActivo)
            Expanded(
              child: _buildRoleTab(
                label: 'Repartidor',
                icon: Icons.delivery_dining,
                color: _celeste,
                isSelected: _rolSeleccionado == 'REPARTIDOR',
                onTap: () => setState(() => _rolSeleccionado = 'REPARTIDOR'),
              ),
            ),
      ],
      ),
    );
  }

  Widget _buildRoleTab({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.35) : Colors.transparent),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : JPColors.textHint, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? JPColors.textPrimary : JPColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticPanel() {
    if (_rolSeleccionado == 'PROVEEDOR') {
      return _buildActionPanel(
        title: 'Panel de Proveedor',
        description: 'Gestiona tu tienda.',
        icon: Icons.storefront_rounded,
        color: const Color(0xFFFF8C00),
        btnText: 'IR A MI TIENDA',
        onTap: () => _cambiarRol('PROVEEDOR'),
      );
    } else if (_rolSeleccionado == 'REPARTIDOR') {
      return _buildActionPanel(
        title: 'Panel de Repartidor',
        description: 'Ver pedidos disponibles.',
        icon: Icons.delivery_dining_rounded,
        color: _celeste,
        btnText: 'IR A REPARTIR',
        onTap: () => _cambiarRol('REPARTIDOR'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionPanel({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _celeste.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: JPColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: JPColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGradientActionButton(
            text: btnText,
            color: color,
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientActionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
        color: color.withValues(alpha: 0.06),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: JPColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String rol) {
    final solicitud = _ultimasSolicitudes[rol];
    if (solicitud == null) return const SizedBox.shrink();

    final esPendiente = solicitud.estaPendiente;
    final color = rol == 'PROVEEDOR'
        ? _naranja
        : _celeste;

    final title = rol == 'PROVEEDOR'
        ? 'Solicitud Proveedor'
        : 'Solicitud Repartidor';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            rol == 'PROVEEDOR' ? Icons.store : Icons.two_wheeler,
            color: color,
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (esPendiente ? JPColors.warning : JPColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              esPendiente ? 'En Revisión' : 'Rechazada',
              style: TextStyle(
                color: esPendiente ? JPColors.warning : JPColors.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        trailing: !esPendiente
            ? TextButton(
                onPressed: _irASolicitarRol,
                style: TextButton.styleFrom(foregroundColor: color),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontSize: 12),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildOpportunityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _irASolicitarRol,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 3),
                      Text(
                      subtitle,
                      style: const TextStyle(
                      fontSize: 13,
                      color: JPColors.textSecondary,
                      ),
                     )
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 15, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: JPColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: JPColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, indent: 54, color: Colors.grey.shade100);

  String _getLanguageName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    switch (locale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      default:
        return 'Español';
    }
  }

  // ==========================================================
  // LÓGICA (SIN CAMBIOS)
  // ==========================================================

  void _irASolicitarRol() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaSolicitarRol()),
    );
  }

  void _mostrarDialogoCambiarPassword() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => const DialogoCambiarPassword(),
    );

    if (resultado == true && mounted) {
      // La contraseña fue cambiada exitosamente
      // Opcional: podrías cerrar sesión automáticamente
      // await _authService.cerrarSesion();
      // Navigator.of(context).pushNamedAndRemoveUntil(Rutas.login, (route) => false);
    }
  }

  Future<void> _cambiarRol(String nuevoRol) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: JPColors.primary)),
    );

    try {
      await _authService.cambiarRolActivo(nuevoRol);
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Rutas.router, (route) => false);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) JPSnackbar.error(context, 'Error al cambiar modo: $e');
    }
  }
}
