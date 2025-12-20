// lib/screens/user/perfil/configuracion/pantalla_configuracion.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, showDialog;
import 'package:provider/provider.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/solicitudes_service.dart';
import '../../../../../services/toast_service.dart';
import '../../../../../services/role_manager.dart';
import '../../../../../models/solicitud_cambio_rol.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../switch/role_router.dart';
import '../../../../switch/roles.dart';
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
  final _authService = AuthService();
  final _solicitudesService = SolicitudesService();

  List<String> _rolesActivos = [];
  final Map<String, SolicitudCambioRol> _ultimasSolicitudes = {};

  bool _isLoading = true;
  String? _rolSeleccionado;
  String? _rolActual;

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

      final solicitudesResponse = await _solicitudesService
          .obtenerMisSolicitudes();
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
        final rolCacheado = _authService.getRolCacheado()?.toUpperCase();
        final rolActivoNormalizado =
            rolCacheado != null && rolesActivos.contains(rolCacheado)
            ? rolCacheado
            : _obtenerPrimerRolActivo();
        setState(() {
          _rolesActivos = rolesActivos;
          _ultimasSolicitudes.addAll(mapaSolicitudes);
          _rolSeleccionado = rolActivoNormalizado;
          _rolActual = rolActivoNormalizado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ToastService().showError(context, 'Error cargando configuración');
      }
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
  // UI PRINCIPAL iOS-STYLE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: JPCupertinoColors.surface(context),
        middle: Text(l10n.settings),
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: _isLoading
          ? Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: JPCupertinoColors.systemGrey(context),
              ),
            )
          : SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Refresh control iOS
                  CupertinoSliverRefreshControl(
                    onRefresh: _cargarDatosCompletos,
                  ),

                  // Contenido principal
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Modo de trabajo
                        if (_esProveedorActivo || _esRepartidorActivo) ...[
                          _buildSectionTitle('Modo de trabajo'),
                          const SizedBox(height: 8),
                          _buildRoleList(),
                          const SizedBox(height: 18),
                        ],

                        // Estado de solicitudes
                        if (_tieneEstadoVisible('PROVEEDOR') ||
                            _tieneEstadoVisible('REPARTIDOR')) ...[
                          _buildSectionTitle('Estado de solicitudes'),
                          const SizedBox(height: 8),
                          _buildStatusList(),
                          const SizedBox(height: 18),
                        ],

                        // Oportunidades
                        if (_mostrarOportunidad('PROVEEDOR') ||
                            _mostrarOportunidad('REPARTIDOR')) ...[
                          _buildSectionTitle('Oportunidades'),
                          const SizedBox(height: 8),
                          _buildOportunidades(),
                          const SizedBox(height: 18),
                        ],

                        // Solicitar rol
                        _buildSectionTitle('Solicitar rol'),
                        const SizedBox(height: 8),
                        _buildSettingsContainer([_buildSolicitudRolTile()]),
                        const SizedBox(height: 18),

                        // Cuenta
                        _buildSectionTitle(l10n.account),
                        const SizedBox(height: 8),
                        _buildSettingsContainer([
                          _buildSettingsTile(
                            icon: CupertinoIcons.location,
                            title: l10n.myAddresses,
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const PantallaListaDirecciones(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: CupertinoIcons.lock,
                            title: 'Cambiar Contraseña',
                            onTap: _mostrarDialogoCambiarPassword,
                          ),
                        ]),
                        const SizedBox(height: 18),

                        // General
                        _buildSectionTitle('General'),
                        const SizedBox(height: 8),
                        _buildSettingsContainer([
                          _buildSettingsTile(
                            icon: CupertinoIcons.bell,
                            title: l10n.notifications,
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const PantallaNotificaciones(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: CupertinoIcons.globe,
                            title: l10n.language,
                            trailingText: _getLanguageName(context),
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const PantallaIdioma(),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 18),

                        // Soporte
                        _buildSectionTitle('Soporte'),
                        const SizedBox(height: 8),
                        _buildSettingsContainer([
                          _buildSettingsTile(
                            icon: CupertinoIcons.question_circle,
                            title: l10n.helpSupport,
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const PantallaAyudaSoporte(),
                              ),
                            ),
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: CupertinoIcons.doc_text,
                            title: l10n.termsConditions,
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const PantallaTerminos(),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ==========================================================
  // WIDGETS PERSONALIZADOS - iOS STYLE
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: JPCupertinoColors.secondaryLabel(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRoleList() {
    final items = <Widget>[];
    if (_esProveedorActivo) {
      items.add(
        _buildRoleTile(
          label: 'Proveedor',
          icon: CupertinoIcons.bag,
          rol: 'PROVEEDOR',
        ),
      );
    }
    if (_esRepartidorActivo) {
      items.add(
        _buildRoleTile(
          label: 'Repartidor',
          icon: CupertinoIcons.car_detailed,
          rol: 'REPARTIDOR',
        ),
      );
    }

    return _buildSettingsContainer(_withDividers(items));
  }

  Widget _buildRoleTile({
    required String label,
    required IconData icon,
    required String rol,
  }) {
    final isSelected = (_rolActual ?? _rolSeleccionado) == rol;
    return GestureDetector(
      onTap: () => setState(() => _rolSeleccionado = rol),
      child: Container(
        color: CupertinoColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: JPCupertinoColors.systemGrey(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSelected ? 'Rol actual' : 'Cambiar a este rol',
                    style: TextStyle(
                      color: JPCupertinoColors.secondaryLabel(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Change button
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              color: isSelected
                  ? JPCupertinoColors.systemGrey4(context)
                  : JPCupertinoColors.systemBlue(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: isSelected ? null : () => _cambiarRol(rol),
              child: Text(
                isSelected ? 'Actual' : 'Cambiar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSelected
                      ? JPCupertinoColors.secondaryLabel(context)
                      : CupertinoColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusList() {
    final tiles = <Widget>[];
    if (_tieneEstadoVisible('PROVEEDOR')) {
      tiles.add(_buildStatusTile('PROVEEDOR'));
    }
    if (_tieneEstadoVisible('REPARTIDOR')) {
      tiles.add(_buildStatusTile('REPARTIDOR'));
    }
    return _buildSettingsContainer(_withDividers(tiles));
  }

  Widget _buildStatusTile(String rol) {
    final solicitud = _ultimasSolicitudes[rol];
    if (solicitud == null) return const SizedBox.shrink();

    final esPendiente = solicitud.estaPendiente;
    final title = rol == 'PROVEEDOR'
        ? 'Solicitud Proveedor'
        : 'Solicitud Repartidor';
    final estado = esPendiente ? 'En revisión' : 'Rechazada';
    final icon = rol == 'PROVEEDOR'
        ? CupertinoIcons.bag
        : CupertinoIcons.car_detailed;
    final statusColor = esPendiente
        ? JPCupertinoColors.systemOrange(context)
        : JPCupertinoColors.systemRed(context);

    return Container(
      color: CupertinoColors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemGrey6(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: JPCupertinoColors.systemGrey(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: JPCupertinoColors.label(context),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Retry button
          if (!esPendiente)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              color: JPCupertinoColors.systemBlue(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: _irASolicitarRol,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOportunidades() {
    final items = <Widget>[];
    if (_mostrarOportunidad('PROVEEDOR')) {
      items.add(
        _buildOpportunityTile(
          title: 'Quiero ser Proveedor',
          subtitle: 'Publica tus productos y vende más',
          icon: CupertinoIcons.bag,
        ),
      );
    }
    if (_mostrarOportunidad('REPARTIDOR')) {
      if (items.isNotEmpty) {
        items.add(_buildDivider());
      }
      items.add(
        _buildOpportunityTile(
          title: 'Quiero ser Repartidor',
          subtitle: 'Gana dinero extra entregando pedidos',
          icon: CupertinoIcons.car_detailed,
        ),
      );
    }
    return _buildSettingsContainer(items);
  }

  List<Widget> _withDividers(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i != children.length - 1) {
        result.add(_buildDivider());
      }
    }
    return result;
  }

  Widget _buildOpportunityTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: _irASolicitarRol,
      child: Container(
        color: CupertinoColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: JPCupertinoColors.systemBlue(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: JPCupertinoColors.secondaryLabel(context),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: JPCupertinoColors.systemGrey3(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolicitudRolTile() {
    return GestureDetector(
      onTap: _irASolicitarRol,
      child: Container(
        color: CupertinoColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.person_badge_plus,
                color: JPCupertinoColors.systemGrey(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solicitar cambio de rol',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Envía una solicitud al administrador',
                    style: TextStyle(
                      fontSize: 13,
                      color: JPCupertinoColors.secondaryLabel(context),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: JPCupertinoColors.systemGrey3(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: JPConstants.cardShadow(context),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: CupertinoColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: JPCupertinoColors.systemGrey(context),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: JPCupertinoColors.label(context),
                ),
              ),
            ),

            // Trailing text and chevron
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 13,
                  color: JPCupertinoColors.secondaryLabel(context),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: JPCupertinoColors.systemGrey3(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(
        height: 1,
        indent: 56,
        color: JPCupertinoColors.separator(context),
      );

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
  // LÓGICA
  // ==========================================================

  void _irASolicitarRol() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PantallaSolicitarRol()),
    );
  }

  void _mostrarDialogoCambiarPassword() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => const DialogoCambiarPassword(),
    );

    if (resultado == true && mounted) {
      ToastService().showSuccess(context, 'Contraseña actualizada exitosamente');
    }
  }

  Future<void> _cambiarRol(String nuevoRol) async {
    final roleManager = Provider.of<RoleManager>(context, listen: false);
    final target = parseRole(nuevoRol);

    ToastService().showInfo(
      context,
      'Cambiando a ${roleToDisplay(target)}...',
    );

    final exito = await roleManager.switchRole(target);
    if (!mounted) return;

    if (exito) {
      await RoleRouter.navigateByRole(context, target);
    } else {
      ToastService().showError(
        context,
        'No se pudo cambiar al rol ${roleToDisplay(target)}',
      );
    }
  }
}
