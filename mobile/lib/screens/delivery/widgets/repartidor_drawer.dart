// lib/screens/delivery/widgets/repartidor_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/repartidor.dart';
import '../../../providers/proveedor_roles.dart';
import '../../../config/rutas.dart';
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
  static const Color _primario = Color(0xFFFF9800);      // Naranja
  static const Color _primarioOscuro = Color(0xFFF57C00);
  static const Color _verde = Color(0xFF4CAF50);
  static const Color _azul = Color(0xFF2196F3);
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
                  // Switch de Disponibilidad (Exclusivo de Repartidor)
                  _buildDisponibilidadTile(),

                  // Selector de roles (Simplificado estilo Proveedor)
                  Consumer<ProveedorRoles>(
                    builder: (context, proveedorRoles, child) {
                      if (!proveedorRoles.tieneMultiplesRoles) {
                        return const SizedBox.shrink();
                      }
                      return _buildSelectorRoles(context, proveedorRoles);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),

                  // Menú Principal
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
                        MaterialPageRoute(builder: (_) => const PantallaHistorialRepartidor()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.attach_money,
                    title: 'Ganancias',
                    subtitle: '\$${((perfil?.entregasCompletadas ?? 0) * 5.0).toStringAsFixed(2)}',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaGananciasRepartidor()),
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
                        MaterialPageRoute(builder: (_) => const PantallaEditarPerfilRepartidor()),
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
                        MaterialPageRoute(builder: (_) => const PantallaDatosBancarios()),
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
                        MaterialPageRoute(builder: (_) => const PantallaConfiguracionRepartidor()),
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
                        MaterialPageRoute(builder: (_) => const PantallaAyudaSoporteRepartidor()),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: fotoPerfil != null
                      ? DecorationImage(
                          image: NetworkImage(fotoPerfil),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: fotoPerfil == null
                    ? const Icon(Icons.person, color: _primario, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perfil?.estado.nombre ?? 'Offline',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 14, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  email,
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
          color: estaDisponible ? _verde.withValues(alpha: 0.5) : Colors.grey.shade300,
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

  Widget _buildSelectorRoles(BuildContext context, ProveedorRoles proveedorRoles) {
    // Filtramos roles distintos al actual (REPARTIDOR)
    final rolesDisponibles = proveedorRoles.rolesDisponibles
        .where((r) => r.toUpperCase() != 'REPARTIDOR')
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
              Navigator.pop(context); // Cerrar drawer
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

  /// ✅ Lógica corregida: Forzar navegación sin verificar estado anterior
  Future<void> _ejecutarCambioRol(
    BuildContext context,
    ProveedorRoles proveedorRoles,
    String nuevoRol,
  ) async {
    try {
      // Intentar cambiar estado (sin bloquear por resultado)
      await proveedorRoles.cambiarARol(nuevoRol);
      
      if (!context.mounted) return;

      // Normalizar string para evitar errores en router
      String rolDestino = nuevoRol;
      if (nuevoRol.toUpperCase() == 'USUARIO') rolDestino = 'CLIENTE';

      // Forzar navegación
      await Rutas.irAHomePorRol(context, rolDestino);
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      dense: true,
    );
  }

  Widget _buildBadgeActivo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _verde,
        borderRadius: BorderRadius.circular(10),
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
        return 'Repartidor';
      case 'ADMINISTRADOR':
        return 'Admin';
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
        return _azul;
      case 'REPARTIDOR':
        return _primario;
      case 'ADMINISTRADOR':
        return const Color(0xFF7B1FA2);
      case 'PROVEEDOR':
        return _verde;
      default:
        return _textoSecundario;
    }
  }
}
