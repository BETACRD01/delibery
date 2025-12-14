// lib/screens/user/inicio/widgets/inicio/home_app_bar.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../config/rutas.dart';
import 'package:badges/badges.dart' as badges;

/// AppBar personalizado para la pantalla Home
class HomeAppBar extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final int notificacionesCount;
  final String nombreUsuario;
  final String? fotoPerfilUrl;
  final String? logoAssetPath;

  const HomeAppBar({
    super.key,
    this.onNotificationTap,
    this.onSearchTap,
    this.notificacionesCount = 0,
    this.nombreUsuario = 'Usuario',
    this.fotoPerfilUrl,
    this.logoAssetPath,
  });

  // Tamaño deseado para el logo (compacto: 32.0)
  static const double _logoSize = 48.0;
  
  // Ruta de logo predeterminada (desde el pubspec.yaml)
  static const String _defaultLogoPath = 'assets/images/Beta.png'; 

  @override
  Widget build(BuildContext context) {
    const double searchBarHeight = 46.0; 
    
    return SliverAppBar(
      expandedHeight: 90,
      toolbarHeight: 55,
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      // Espaciado estable; sin desplazamientos dinámicos
      titleSpacing: 0,

      // La Barra de búsqueda está en el 'bottom' para garantizar la separación.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(searchBarHeight),
        child: Column(
          children: [
            _buildSearchBar(context),
            // Línea divisora
            Container(color: Colors.grey[200], height: 0.5),
          ],
        ),
      ),

      // LOGO Y NOMBRE (Title)
      title: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoWidget(),
            const SizedBox(width: 8),
            const Text(
              'JP Express',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: JPColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),

      // ACCIONES A LA DERECHA
      actions: [
        _buildNotificationIcon(),
        const SizedBox(width: 4),

        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            color: JPColors.error,
            size: 26,
          ),
          tooltip: 'Cerrar Sesión',
          onPressed: () => _confirmarCerrarSesion(context),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // 🔍 BARRA DE BÚSQUEDA OPTIMIZADA
  Widget _buildSearchBar(BuildContext context) {
    // Altura compacta (34)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), // Padding externo
      child: SizedBox(
        height: 34, 
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.grey[500], size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Buscar productos...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🖼️ LÓGICA PARA MOSTRAR EL LOGO O EL PLACEHOLDER
  Widget _buildLogoWidget() {
    final path = logoAssetPath?.isNotEmpty == true ? logoAssetPath : _defaultLogoPath;

    if (path != null && path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8), 
        child: Image.asset(
          path,
          width: _logoSize,
          height: _logoSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderLogo();
          },
        ),
      );
    } else {
      return _buildPlaceholderLogo();
    }
  }

  // 🚀 WIDGET DEL LOGO DE REEMPLAZO (FALLBACK)
  Widget _buildPlaceholderLogo() {
    return Container(
      width: _logoSize,
      height: _logoSize,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: JPColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.rocket_launch_rounded,
        color: JPColors.primary,
        size: 20, 
      ),
    );
  }

  // 🔔 ICONO DE NOTIFICACIONES CON BADGE
  Widget _buildNotificationIcon() {
    final tieneNotificaciones = notificacionesCount > 0;

    return badges.Badge(
      showBadge: tieneNotificaciones,
      ignorePointer: true,
      badgeStyle:const badges.BadgeStyle(
        badgeColor: JPColors.error,
        padding:  EdgeInsets.all(4),
        borderSide: BorderSide(color: Colors.white, width: 1.5),
      ),
      position: badges.BadgePosition.topEnd(top: 8, end: 8),
      badgeContent: const SizedBox.shrink(), 
      child: IconButton(
        icon: const Icon(
          Icons.notifications_none_rounded, 
          color: JPColors.textPrimary,
          size: 28,
        ),
        onPressed: onNotificationTap,
        splashRadius: 24,
      ),
    );
  }

  // 🚪 LÓGICA DE CERRAR SESIÓN
  void _confirmarCerrarSesion(BuildContext context) {
    final authService = AuthService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cerrar Sesión', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('¿Estás seguro que quieres salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar', 
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                Rutas.login,
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: JPColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
