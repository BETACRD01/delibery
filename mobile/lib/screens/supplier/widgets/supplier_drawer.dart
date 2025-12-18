// lib/screens/supplier/widgets/supplier_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/proveedor_roles.dart';
import '../../../config/rutas.dart';
import '../../../config/api_config.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../perfil/perfil_proveedor_panel.dart';
import '../screens/pantalla_productos_proveedor.dart';
import '../screens/pantalla_estadisticas_proveedor.dart';
import '../screens/pantalla_configuracion_proveedor.dart';
import '../screens/pantalla_ayuda_proveedor.dart';

class SupplierDrawer extends StatelessWidget {
  final VoidCallback onCerrarSesion;

  const SupplierDrawer({super.key, required this.onCerrarSesion});

  // ---------------------------------------------------------------------------
  // PALETA DE COLORES
  // ---------------------------------------------------------------------------
  static const Color _primario = Color(0xFF1E88E5);
  static const Color _exito = Color(0xFF43A047);
  static const Color _alerta = Color(0xFFFB8C00);
  static const Color _peligro = Color(0xFFE53935);
  static const Color _rojo = Color(0xFFEF4444);
  static const Color _fondoTarjeta = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildRoleCard(context),
                  const SizedBox(height: 8),
                  Consumer<SupplierController>(
                    builder: (context, controller, child) {
                      if (!controller.verificado) {
                        return _buildAlertaVerificacion();
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: 'Productos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaProductosProveedor(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    title: 'Estadísticas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaEstadisticasProveedor(),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
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
                          builder: (_) => const PerfilProveedorEditable(),
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
                          builder: (_) => const PantallaConfiguracionProveedor(),
                        ),
                      );
                    },
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
                          builder: (_) => const PantallaAyudaProveedor(),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    color: _peligro,
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

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            bottom: 22,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLogoAvatar(controller),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.nombreNegocio.isNotEmpty
                              ? controller.nombreNegocio
                              : 'Mi Negocio',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _buildBadgeVerificacion(controller.verificado),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.circle,
                    size: 10,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.email.isNotEmpty
                          ? controller.email
                          : 'Sin email',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoAvatar(SupplierController controller) {
    final logoUrl = controller.logo;
    
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            // ✅ CORRECCIÓN: .withValues()
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildLogoImage(logoUrl, controller),
      ),
    );
  }

  Widget _buildLogoImage(String? logoUrl, SupplierController controller) {
    if (logoUrl == null || logoUrl.isEmpty) {
      // ✅ CORRECCIÓN: Agregado 'const'
      return Container(
        color: _fondoTarjeta,
        child: const Icon(
          Icons.store,
          size: 28,
          color: _primario,
        ),
      );
    }

    String urlCompleta = logoUrl;
    if (!logoUrl.startsWith('http')) {
      urlCompleta = '${ApiConfig.baseUrl}$logoUrl';
    }

    if (controller.esLogoCaido(urlCompleta)) {
      return Container(
        color: _fondoTarjeta,
        child: const Icon(
          Icons.store,
          size: 28,
          color: _primario,
        ),
      );
    }

    return Image.network(
      urlCompleta,
      fit: BoxFit.cover,
      width: 56,
      height: 56,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: _fondoTarjeta,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primario,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Delay the mark to next frame to avoid notifyListeners during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.marcarLogoCaido(urlCompleta);
        });
        return Container(
          color: _fondoTarjeta,
          child: const Icon(
            Icons.store,
            size: 28,
            color: _primario,
          ),
        );
      },
    );
  }

  Widget _buildBadgeVerificacion(bool verificado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // ✅ CORRECCIÓN: .withValues()
        color: verificado
            ? _exito.withValues(alpha: 0.9)
            : _alerta.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verificado ? Icons.check_circle : Icons.schedule,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            verificado ? 'Verificado' : 'Pendiente',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
    required VoidCallback onTap,
    Color? color,
    Widget? badge,
  }) {
    final itemColor = color ?? Colors.black87;

    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: itemColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (badge != null) badge,
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      dense: true,
    );
  }

  Widget _buildAlertaVerificacion() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _alerta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _alerta.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: _alerta, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cuenta pendiente de verificación',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENÚ ITEMS
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // ALERTA VERIFICACIÓN
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // SELECTOR DE ROLES
  // ---------------------------------------------------------------------------

  Widget _buildRoleCard(BuildContext context) {
    return Consumer<ProveedorRoles>(
      builder: (context, proveedorRoles, _) {
        if (!proveedorRoles.tieneMultiplesRoles) {
          return const SizedBox.shrink();
        }
        final rolesDisponibles = proveedorRoles.rolesDisponibles
            .where((r) => r.toUpperCase() != 'PROVEEDOR')
            .toList();
        if (rolesDisponibles.isEmpty) return const SizedBox.shrink();

        final tituloActivo = proveedorRoles.rolActivo != null
            ? _getNombreRol(proveedorRoles.rolActivo!)
            : _getNombreRol(rolesDisponibles.first);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Material(
            color: Colors.transparent,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _mostrarCambiarRolSheet(context, proveedorRoles),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _primario.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cambiar rol',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Actualmente: $tituloActivo',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarCambiarRolSheet(
    BuildContext parentContext,
    ProveedorRoles proveedorRoles,
  ) {
    final rolesDisponibles = proveedorRoles.rolesDisponibles
        .where((r) => r.toUpperCase() != 'PROVEEDOR')
        .toList();

    if (rolesDisponibles.isEmpty) return;

    bool isChanging = false;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cambiar rol',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selecciona el rol que quieras activar.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rolesDisponibles.map((rol) {
                      final isDisabled = isChanging;
                      return ActionChip(
                        backgroundColor: Colors.grey.shade100,
                        label: Text(
                          _getNombreRol(rol),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: isDisabled
                            ? null
                            : () async {
                                final navigatorState = Navigator.of(parentContext);
                                final scaffoldMessenger =
                                    ScaffoldMessenger.of(parentContext);
                                final sheetMessenger =
                                    ScaffoldMessenger.of(sheetContext);
                                final rutaHome = _rutaHomePorRol(rol);
                                setSheetState(() => isChanging = true);
                                try {
                                  final success =
                                      await proveedorRoles.cambiarARol(rol);
                                  if (!success) {
                                    throw Exception('No puedes activar $rol');
                                  }
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                  await navigatorState.pushNamedAndRemoveUntil(
                                    rutaHome,
                                    (route) => false,
                                  );
                                  if (scaffoldMessenger.mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Rol cambiado a ${_getNombreRol(rol)}',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (sheetMessenger.mounted) {
                                    sheetMessenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: _rojo,
                                        content: Text(
                                          e.toString(),
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  setSheetState(() => isChanging = false);
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
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _rutaHomePorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMINISTRADOR':
        return Rutas.adminHome;
      case 'REPARTIDOR':
        return Rutas.repartidorHome;
      case 'PROVEEDOR':
        return Rutas.proveedorHome;
      case 'CLIENTE':
      case 'USUARIO':
      default:
        return Rutas.inicio;
    }
  }

  String _getNombreRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'CLIENTE':
      case 'USUARIO':
        return 'Modo Cliente';
      case 'REPARTIDOR':
        return 'Modo Repartidor';
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'PROVEEDOR':
        return 'Proveedor';
      default:
        return rol;
    }
  }

}
