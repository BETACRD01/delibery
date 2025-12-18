// lib/screens/delivery/widgets/repartidor_drawer.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/rutas.dart';
import '../../../apis/helpers/api_exception.dart';
import '../../../models/repartidor.dart';
import '../../../services/roles_service.dart';
import '../perfil/pantalla_perfil_repartidor.dart';
import '../soporte/pantalla_ayuda_soporte_repartidor.dart';
import '../configuracion/pantalla_configuracion_repartidor.dart';
import '../ganancias/pantalla_ganancias_repartidor.dart';
import '../historial/pantalla_historial_repartidor.dart';
import '../pantalla_datos_bancarios.dart';

/// 🎨 Widget del menú lateral (Drawer) para el repartidor
/// ✅ CORREGIDO: Navegación forzada, diseño simplificado y soporte CLIENTE
class RepartidorDrawer extends StatelessWidget {
  final PerfilRepartidorModel? perfil;
  final bool estaDisponible;
  final VoidCallback onCambiarDisponibilidad;
  final VoidCallback onAbrirMapa;
  final VoidCallback onCerrarSesion;

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 PALETA REPARTIDOR (Tema Naranja)
  // ════════════════════════════════════════════════════════════════════════
  static const Color _primario = Color(0xFFFF9800); // Naranja
  static const Color _verde = Color(0xFF4CAF50);
  static const Color _rojo = Color(0xFFF44336);
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _fondoTarjeta = Color(0xFFF8FAFC);

  const RepartidorDrawer({
    super.key,
    required this.perfil,
    required this.estaDisponible,
    required this.onCambiarDisponibilidad,
    required this.onAbrirMapa,
    required this.onCerrarSesion,
  });

  // Servicio de roles (singleton)
  static final RolesService _rolesService = RolesService();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[100],
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionTitle('Servicios'),
                  _buildMenuItem(
                    context,
                    icon: Icons.map_outlined,
                    title: 'Mapa de Pedidos',
                    badge: _buildBadgeActivo(),
                    onTap: () {
                      Navigator.pop(context);
                      onAbrirMapa();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'Historial',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaHistorialRepartidor(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.attach_money,
                    title: 'Ganancias',
                    subtitle:
                        '\$${((perfil?.entregasCompletadas ?? 0) * 5.0).toStringAsFixed(2)}',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaGananciasRepartidor(),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _buildSectionTitle('Sesión'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Mi Perfil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PantallaEditarPerfilRepartidor(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance,
                    title: 'Cuenta bancaria',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaDatosBancarios(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PantallaConfiguracionRepartidor(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.swap_horiz,
                    title: 'Cambiar rol',
                    subtitle: 'Cliente / Proveedor',
                    onTap: () {
                      final navigatorContext = context;
                      Navigator.pop(navigatorContext);
                      _mostrarCambiarRolSheet(navigatorContext);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _buildSectionTitle('Soporte'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Ayuda',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PantallaAyudaSoporteRepartidor(),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _buildSectionTitle('Cuenta'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    color: _rojo,
                    onTap: onCerrarSesion,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📸 HEADER PERSONALIZADO
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    final fotoPerfil = perfil?.fotoPerfil;
    final nombre = perfil?.nombreCompleto ?? 'Cargando...';
    final email = perfil?.email ?? '';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_primario, _verde],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    CachedNetworkImage(
                      imageUrl: fotoPerfil ?? '',
                      imageBuilder: (context, imageProvider) => Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(
                                alpha: estaDisponible ? 0.15 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              perfil?.estado.nombre ?? 'Offline',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildDisponibilidadTile(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🛵 DISPONIBILIDAD TILE
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildDisponibilidadTile() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: estaDisponible ? _verde.withValues(alpha: 0.1) : _fondoTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estaDisponible
              ? _verde.withValues(alpha: 0.5)
              : Colors.grey.shade300,
        ),
      ),
      child: SwitchListTile(
        value: estaDisponible,
        onChanged: (value) => onCambiarDisponibilidad(),
        activeTrackColor: _verde,
        title: Text(
          estaDisponible ? 'Disponible' : 'Fuera de Servicio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: estaDisponible ? Colors.green[800] : Colors.grey[700],
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          estaDisponible ? 'Recibiendo pedidos' : 'No recibirás alertas',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        dense: true,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔄 SELECTOR DE ROLES (Estilo Simple)
  // ════════════════════════════════════════════════════════════════════════

  void _mostrarCambiarRolSheet(BuildContext parentContext) {
    final rolesFuture = _rolesService.obtenerRolesDisponibles();
    bool isChangingRole = false;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<Map<String, dynamic>>(
          future: rolesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: _primario),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudieron cargar los roles',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString()),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _mostrarCambiarRolSheet(parentContext);
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final rolesDisponibles =
                (snapshot.data?['roles_disponibles'] as List<dynamic>?)
                    ?.map((value) => value.toString().toUpperCase())
                    .toList() ??
                [];
            final rolActivo =
                (snapshot.data?['rol_activo'] as String?)?.toUpperCase() ?? '';
            final fallbackRoles = ['CLIENTE', 'USUARIO', 'PROVEEDOR'];
            final rolesSet = <String>{};
            rolesSet.addAll(fallbackRoles);
            rolesSet.addAll(rolesDisponibles);
            rolesSet.remove(rolActivo);
            rolesSet.remove('REPARTIDOR');
            final rolesParaMostrar = rolesSet.toList();


            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: 18,
                    left: 20,
                    right: 20,
                    bottom: 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Elegir rol',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cambia al rol que necesites. Si el backend requiere verificación, recibirás una notificación.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (rolesParaMostrar.isEmpty)
                        const Text(
                          'No hay otros roles disponibles.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: rolesParaMostrar.map((rol) {
                            final activo = rol == rolActivo;
                            final isDisabled = isChangingRole;
                            return ActionChip(
                              backgroundColor: activo
                                  ? _primario.withValues(alpha: 0.14)
                                  : Colors.grey.shade100,
                              label: Text(
                                _rolesService.obtenerNombreRol(rol),
                                style: TextStyle(
                                  color: activo ? _primario : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: isDisabled
                                  ? null
                                  : () async {
                                      setSheetState(() => isChangingRole = true);
                                      final messenger =
                                          ScaffoldMessenger.of(sheetContext);
                                      final rootNavigator = Navigator.of(
                                        sheetContext,
                                        rootNavigator: true,
                                      );
                                      final homeRoute = _rutaHomePorRol(rol);

                                    try {
                                      await _rolesService.cambiarRolActivo(rol);
                                      if (sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop();
                                      }
                                      rootNavigator.pushNamedAndRemoveUntil(
                                        homeRoute,
                                        (_) => false,
                                      );
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Rol cambiado a ${_rolesService.obtenerNombreRol(rol)}',
                                          ),
                                        ),
                                      );
                                    } on ApiException catch (e) {
                                      if (sheetContext.mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            backgroundColor: _rojo,
                                            content: Text(
                                              e.getUserFriendlyMessage(),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (_) {
                                      if (sheetContext.mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            backgroundColor: _rojo,
                                            content: Text(
                                              'No se pudo cambiar de rol',
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      setSheetState(() => isChangingRole = false);
                                    }
                                    },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📋 HELPERS & MENU ITEMS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? color,
    Widget? badge,
  }) {
    final itemColor = color ?? _textoSecundario;

    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (badge != null) badge,
        ],
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      dense: true,
    );
  }

  Widget _buildBadgeActivo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _verde.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'ACTIVO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Colors.black54,
      ),
    );
  }

  String _rutaHomePorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMINISTRADOR':
      case 'STAFF':
        return Rutas.adminHome;
      case 'REPARTIDOR':
        return Rutas.repartidorHome;
      case 'PROVEEDOR':
        return Rutas.proveedorHome;
      case 'USUARIO':
      case 'CLIENTE':
      default:
        return Rutas.inicio;
    }
  }
}
