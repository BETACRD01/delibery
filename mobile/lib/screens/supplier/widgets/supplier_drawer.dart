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
  static const Color _primarioOscuro = Color(0xFF1565C0);
  static const Color _exito = Color(0xFF43A047);         
  static const Color _alerta = Color(0xFFFB8C00);        
  static const Color _peligro = Color(0xFFE53935);       
  static const Color _textoSecundario = Color(0xFF6B7280);
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
                  // Alerta de verificación
                  Consumer<SupplierController>(
                    builder: (context, controller, child) {
                      if (!controller.verificado) {
                        return _buildAlertaVerificacion();
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Selector de roles
                  Consumer<ProveedorRoles>(
                    builder: (context, proveedorRoles, child) {
                      if (!proveedorRoles.tieneMultiplesRoles) {
                        return const SizedBox.shrink();
                      }
                      return _buildSelectorRoles(context, proveedorRoles);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Menú principal
                  _buildMenuItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: 'Productos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaProductosProveedor()),
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
                        MaterialPageRoute(builder: (_) => const PantallaEstadisticasProveedor()),
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
                        MaterialPageRoute(builder: (_) => const PantallaConfiguracionProveedor()),
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
                        MaterialPageRoute(builder: (_) => const PantallaAyudaProveedor()),
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
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primario, _primarioOscuro],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLogoAvatar(controller),
                  const SizedBox(width: 14),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _buildBadgeVerificacion(controller.verificado),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
        child: _buildLogoImage(logoUrl),
      ),
    );
  }

  Widget _buildLogoImage(String? logoUrl) {
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
        // ✅ CORRECCIÓN: Agregado 'const'
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

  // ---------------------------------------------------------------------------
  // MENÚ ITEMS
  // ---------------------------------------------------------------------------

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      dense: true,
    );
  }

  // ---------------------------------------------------------------------------
  // ALERTA VERIFICACIÓN
  // ---------------------------------------------------------------------------

  Widget _buildAlertaVerificacion() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // ✅ CORRECCIÓN: .withValues()
        color: _alerta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ✅ CORRECCIÓN: .withValues()
          color: _alerta.withValues(alpha: 0.3),
        ),
      ),
      child: const Row( // ✅ CORRECCIÓN: Agregado 'const'
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
  // SELECTOR DE ROLES
  // ---------------------------------------------------------------------------

  Widget _buildSelectorRoles(BuildContext context, ProveedorRoles proveedorRoles) {
    final rolesDisponibles = proveedorRoles.rolesDisponibles
        .where((r) => r.toUpperCase() != 'PROVEEDOR')
        .toList();

    if (rolesDisponibles.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fondoTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cambiar Rol',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: rolesDisponibles.map((rol) {
              return ActionChip(
                avatar: Icon(
                  _getIconoRol(rol),
                  size: 16,
                  color: _getColorRol(rol),
                ),
                label: Text(
                  _getNombreRol(rol),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getColorRol(rol),
                  ),
                ),
                // ✅ CORRECCIÓN: .withValues()
                backgroundColor: _getColorRol(rol).withValues(alpha: 0.1),
                side: BorderSide.none,
                onPressed: () => _confirmarCambioRol(context, proveedorRoles, rol),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _confirmarCambioRol(
    BuildContext context,
    ProveedorRoles proveedorRoles,
    String nuevoRol,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cambiar a ${_getNombreRol(nuevoRol)}'),
        content: const Text('¿Deseas cambiar de Rol?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              _ejecutarCambioRol(context, proveedorRoles, nuevoRol);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _getColorRol(nuevoRol),
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarCambioRol(
    BuildContext context,
    ProveedorRoles proveedorRoles,
    String nuevoRol,
  ) async {
    try {
      await proveedorRoles.cambiarARol(nuevoRol);
      
      if (!context.mounted) return;

      String rolDestino = nuevoRol;
      if (nuevoRol.toUpperCase() == 'USUARIO') rolDestino = 'CLIENTE';

      await Rutas.irAHomePorRol(context, rolDestino);
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  IconData _getIconoRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'CLIENTE':
      case 'USUARIO':
        return Icons.person_outline;
      case 'REPARTIDOR':
        return Icons.delivery_dining;
      case 'ADMINISTRADOR':
        return Icons.admin_panel_settings_outlined;
      case 'PROVEEDOR':
        return Icons.store;
      default:
        return Icons.help_outline;
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

  Color _getColorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'CLIENTE':
      case 'USUARIO':
        return _primario;
      case 'REPARTIDOR':
        return _alerta;
      case 'ADMINISTRADOR':
        return const Color(0xFF7B1FA2);
      default:
        return _textoSecundario;
    }
  }
}
