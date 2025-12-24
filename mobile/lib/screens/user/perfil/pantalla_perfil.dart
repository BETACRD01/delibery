// lib/screens/user/perfil/pantalla_perfil.dart

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/rutas.dart';
import '../../../controllers/user/perfil_controller.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/roles/role_manager.dart';
import '../../../services/core/toast_service.dart';
import '../../../switch/role_router.dart';
import '../../../switch/roles.dart';
import '../../../theme/app_colors_primary.dart';
import '../../../theme/jp_theme.dart';
import '../../../widgets/ratings/rating_summary_card.dart';
import '../../../widgets/role_switcher_ios.dart';
import '../../raffles/pantalla_rifa_activa.dart';
import '../../solicitudes_rol/pantalla_solicitar_rol.dart';
import 'configuracion/ayuda/pantalla_ayuda_soporte.dart';
import 'configuracion/ayuda/pantalla_terminos.dart';
import 'configuracion/direcciones/pantalla_lista_direcciones.dart';
import 'configuracion/idioma/pantalla_idioma.dart';
import 'configuracion/notificaciones/pantalla_notificaciones.dart';
import 'configuracion/seguridad/dialogo_cambiar_password.dart';
import 'editar/pantalla_editar_foto.dart';
import 'editar/pantalla_editar_informacion.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil>
    with WidgetsBindingObserver {
  late final PerfilController _controller;
  final _authService = AuthService();
  List<String> _rolesActivos = [];
  String? _rolActual;
  bool _rolesCargando = false;
  bool _cambiandoRol = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PerfilController();
    _cargarDatos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargarRoles();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await _controller.cargarDatosCompletos();
  }

  Future<void> _recargarDatos() async {
    await _controller.cargarDatosCompletos(forzarRecarga: true);
    await _cargarRoles();
  }

  Future<void> _cargarRoles() async {
    setState(() => _rolesCargando = true);
    try {
      final roleManager = context.read<RoleManager>();
      await roleManager.refresh();
      final rolesAprobados = roleManager.approvedRoles
          .map((info) => roleToApi(info.role).toUpperCase())
          .where((r) => r == 'PROVEEDOR' || r == 'REPARTIDOR')
          .toList();
      final rolActivo = roleToApi(roleManager.activeRole).toUpperCase();

      if ((rolActivo == 'PROVEEDOR' || rolActivo == 'REPARTIDOR') &&
          !rolesAprobados.contains(rolActivo)) {
        rolesAprobados.add(rolActivo);
      }

      if (mounted) {
        setState(() {
          _rolesActivos = rolesAprobados;
          _rolActual = rolActivo;
          _rolesCargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final rolCacheado = _authService.getRolCacheado()?.toUpperCase();
        final fallbackRoles = List<String>.from(_rolesActivos);
        if (fallbackRoles.isEmpty &&
            (rolCacheado == 'PROVEEDOR' || rolCacheado == 'REPARTIDOR')) {
          fallbackRoles.add(rolCacheado!);
        }
        setState(() {
          _rolesActivos = fallbackRoles;
          _rolActual = rolCacheado ?? _rolActual;
          _rolesCargando = false;
        });
      }
    }
  }

  Future<void> _abrirCambiarPassword() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => const DialogoCambiarPassword(),
    );

    if (resultado == true && mounted) {
      ToastService().showSuccess(
        context,
        'Contraseña actualizada exitosamente',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _cargarRoles();
    }
  }

  void _editarPerfil() async {
    if (_controller.perfil == null) return;
    final resultado = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (context) =>
            PantallaEditarInformacion(perfil: _controller.perfil!),
      ),
    );
    if (resultado == true) await _recargarDatos();
  }

  void _editarFoto() async {
    final resultado = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (context) =>
            PantallaEditarFoto(fotoActual: _controller.perfil?.fotoPerfilUrl),
      ),
    );
    if (resultado == true) await _recargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && !_controller.tieneDatos) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          if (_controller.tieneError && !_controller.tieneDatos) {
            return _buildErrorState();
          }

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_controller.errorPerfil != null ||
                        _controller.errorEstadisticas != null)
                      _buildWarningBanner(),

                    // Sección de calificaciones
                    _buildRatingsSection(),

                    _buildSettingsSection(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final perfil = _controller.perfil;
    if (perfil == null) return const SizedBox(height: 100);

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Mi Perfil',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Card del perfil compacta
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Foto de perfil
                  GestureDetector(
                    onTap: _editarFoto,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColorsPrimary.main,
                                AppColorsPrimary.main.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: JPAvatar(
                              imageUrl: perfil.fotoPerfilUrl,
                              radius: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              CupertinoIcons.camera_fill,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Nombre y correo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.usuarioNombre,
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perfil.usuarioEmail,
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (perfil.esClienteFrecuente) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.star_fill,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Cliente Frecuente',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsSection() {
    final estadisticas = _controller.estadisticas;

    // Si no hay estadísticas o no hay calificaciones, no mostrar nada
    if (estadisticas == null || estadisticas.totalResenas == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CompactRatingSummaryCard(
        averageRating: estadisticas.calificacion,
        totalReviews: estadisticas.totalResenas,
        subtitle: 'Calificación promedio recibida',
        // onTap: () {
        //   // TODO: Navegar a pantalla de todas las reseñas
        //   // Rutas.irAMisCalificaciones(context);
        // },
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // CUENTA
        _buildSectionHeader('CUENTA'),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: CupertinoIcons.person_fill,
            iconBgColor: const Color(0xFF5AC8FA),
            title: 'Información del perfil',
            onTap: _editarPerfil,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: CupertinoIcons.location_solid,
            iconBgColor: const Color(0xFF34C759),
            title: 'Mis direcciones',
            onTap: () => _navegarA(const PantallaListaDirecciones()),
          ),
        ]),

        const SizedBox(height: 24),

        // PREFERENCIAS
        _buildSectionHeader('PREFERENCIAS'),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: CupertinoIcons.bell_fill,
            iconBgColor: const Color(0xFFFF3B30),
            title: 'Notificaciones',
            onTap: () => _navegarA(const PantallaNotificaciones()),
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: CupertinoIcons.globe,
            iconBgColor: const Color(0xFF007AFF),
            title: 'Idioma',
            onTap: () => _navegarA(const PantallaIdioma()),
          ),
        ]),

        const SizedBox(height: 24),

        // RIFAS Y PROMOCIONES
        _buildSectionHeader('RIFAS Y PROMOCIONES'),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: CupertinoIcons.ticket_fill,
            iconBgColor: const Color(0xFFFF9500),
            title: 'Rifas activas',
            onTap: () => _navegarA(const PantallaRifaActiva()),
          ),
        ]),

        // CAMBIAR ROL (solo si hay roles disponibles)
        if (_tieneRolesDisponibles()) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('CAMBIAR ROL'),
          _buildRoleCard(),
        ],

        const SizedBox(height: 24),

        // SOLICITUDES
        _buildSectionHeader('SOLICITUDES'),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: CupertinoIcons.arrow_right_arrow_left,
            iconBgColor: const Color(0xFFAF52DE),
            title: 'Solicitar cambio de rol',
            subtitle: 'Solicita ser proveedor o repartidor',
            onTap: () => _navegarA(const PantallaSolicitarRol()),
          ),
        ]),

        const SizedBox(height: 24),

        // SEGURIDAD
        _buildSectionHeader('SEGURIDAD'),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: CupertinoIcons.lock_fill,
            iconBgColor: const Color(0xFF5AC8FA),
            title: 'Cambiar contraseña',
            subtitle: 'Actualiza tu clave de acceso',
            onTap: _abrirCambiarPassword,
          ),
        ]),

        const SizedBox(height: 24),

        // SOPORTE (AL FINAL)
        _buildSectionHeader('SOPORTE'),
        _buildSettingsCard([
          _buildSettingsTile(
            icon: CupertinoIcons.question_circle_fill,
            iconBgColor: const Color(0xFF5856D6),
            title: 'Ayuda y soporte',
            onTap: () => _navegarA(const PantallaAyudaSoporte()),
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: CupertinoIcons.doc_text_fill,
            iconBgColor: const Color(0xFF8E8E93),
            title: 'Términos y condiciones',
            onTap: () => _navegarA(const PantallaTerminos()),
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.systemGrey.resolveFrom(context),
            letterSpacing: -0.08,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRoleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildRoleSwitcher(),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  bool _tieneRolesDisponibles() {
    return _rolesActivos.contains('PROVEEDOR') ||
        _rolesActivos.contains('REPARTIDOR');
  }

  Widget _buildRoleSwitcher() {
    if (_rolesCargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final disponibleProveedor = _rolesActivos.contains('PROVEEDOR');
    final disponibleRepartidor = _rolesActivos.contains('REPARTIDOR');

    final options = <String, String>{};
    if (disponibleProveedor) options['PROVEEDOR'] = 'Proveedor';
    if (disponibleRepartidor) options['REPARTIDOR'] = 'Repartidor';

    final selected = options.keys.contains(_rolActual)
        ? _rolActual
        : (options.keys.isNotEmpty ? options.keys.first : null);

    return RoleSwitcherIOS(
      opciones: options,
      rolSeleccionado: selected,
      onChanged: (valor) => _goToRole(valor),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFECB5)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Color(0xFF856404),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Alguna información no se pudo cargar.',
              style: TextStyle(color: Color(0xFF856404), fontSize: 13),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: _recargarDatos,
            child: const Icon(
              CupertinoIcons.refresh,
              color: Color(0xFF856404),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 48,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar perfil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error ?? 'Ocurrió un problema inesperado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _recargarDatos,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Reintentar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navegarA(Widget pantalla) {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => pantalla));
  }

  String _rutaHomePorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'PROVEEDOR':
        return Rutas.proveedorHome;
      case 'REPARTIDOR':
        return Rutas.repartidorHome;
      case 'USUARIO':
      case 'CLIENTE':
        return Rutas.inicio;
      default:
        return Rutas.inicio;
    }
  }

  Future<void> _goToRole(String nuevoRol) async {
    if (nuevoRol.isEmpty) return;
    if (_cambiandoRol) {
      debugPrint('[Perfil][Rol] Cambio en progreso, acción ignorada');
      return;
    }

    final rolDestino = nuevoRol.toUpperCase();
    final rolAnterior = _rolActual?.toUpperCase();

    debugPrint(
      '[Perfil][Rol] Solicitud de cambio: ${rolAnterior ?? "N/A"} -> $rolDestino',
    );

    final roleManager = context.read<RoleManager>();
    _cambiandoRol = true;
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      ),
    );

    try {
      await roleManager.refresh();
      final destino = parseRole(rolDestino);
      final roleInfo = roleManager.getRoleInfo(destino);

      if (roleInfo == null || !roleInfo.canActivate) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (mounted) {
          final mensaje = roleManager.getStatusMessage(destino);
          await showCupertinoDialog(
            context: context,
            builder: (dialogContext) => CupertinoAlertDialog(
              title: const Text('Rol no disponible'),
              content: Text(mensaje),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          );
        }
        return;
      }
      final exito = await roleManager.switchRole(destino);

      if (!exito) {
        final errorRol =
            roleManager.error ?? 'No se pudo cambiar al rol $rolDestino';
        throw Exception(errorRol);
      }

      final rolCacheado =
          _authService.getRolCacheado()?.toUpperCase() ?? 'DESCONOCIDO';
      final ruta = _rutaHomePorRol(roleToApi(destino));

      debugPrint(
        '[Perfil][Rol] Cambio aplicado: ${rolAnterior ?? "N/A"} -> '
        '${roleToApi(destino)} | cache=$rolCacheado | ruta=$ruta',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await RoleRouter.navigateByRole(context, destino);
    } catch (e) {
      debugPrint('[Perfil][Rol] Error al cambiar a $rolDestino: $e');
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        await showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('No se pudo cambiar de rol: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      }
    } finally {
      _cambiandoRol = false;
      if (mounted) {
        await _cargarRoles();
      }
    }
  }
}
