// lib/widgets/common/jp_cupertino_app_bar.dart

import 'package:flutter/cupertino.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 📱 CUPERTINO APP BAR - AppBar estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

/// AppBar unificada estilo iOS con soporte dark mode
///
/// Características:
/// - Altura estándar iOS: 44px + statusBar padding
/// - Fondo adaptativo con .resolveFrom()
/// - Sombra sutil
/// - Leading, title y trailing personalizables
/// - Título centrado opcional
class JPCupertinoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool showShadow;
  final double elevation;

  const JPCupertinoAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.trailing,
    this.centerTitle = false,
    this.backgroundColor,
    this.showShadow = true,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? JPCupertinoColors.surface(context);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: showShadow ? JPConstants.subtleShadow(context) : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: NavigationToolbar(
            leading: leading ?? _buildDefaultLeading(context),
            middle: _buildTitle(context),
            trailing: trailing,
            centerMiddle: centerTitle,
            middleSpacing: 16,
          ),
        ),
      ),
    );
  }

  Widget? _buildDefaultLeading(BuildContext context) {
    // Solo mostrar botón back si hay una ruta anterior
    if (Navigator.canPop(context)) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.back,
              size: 28,
              color: JPCupertinoColors.systemBlue(context),
            ),
          ],
        ),
      );
    }
    return null;
  }

  Widget? _buildTitle(BuildContext context) {
    if (titleWidget != null) return titleWidget;
    if (title == null) return null;

    return Text(
      title!,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: JPCupertinoColors.label(context),
        letterSpacing: -0.4,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🔍 SEARCH APP BAR - AppBar con búsqueda integrada
// ══════════════════════════════════════════════════════════════════════════════

/// AppBar con barra de búsqueda integrada estilo iOS
class JPSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? leading;
  final Widget? trailing;

  const JPSearchAppBar({
    super.key,
    this.placeholder = 'Buscar',
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.leading,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        boxShadow: JPConstants.subtleShadow(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _buildSearchField(context),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: JPCupertinoColors.systemGrey5(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.search,
              size: 16,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: readOnly
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        placeholder,
                        style: TextStyle(
                          fontSize: 16,
                          color: JPCupertinoColors.placeholder(context),
                        ),
                      ),
                    )
                  : CupertinoTextField(
                      controller: controller,
                      onChanged: onChanged,
                      placeholder: placeholder,
                      style: TextStyle(
                        fontSize: 16,
                        color: JPCupertinoColors.label(context),
                      ),
                      placeholderStyle: TextStyle(
                        fontSize: 16,
                        color: JPCupertinoColors.placeholder(context),
                      ),
                      decoration: const BoxDecoration(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 LARGE TITLE APP BAR - AppBar con título grande estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

/// AppBar con título grande estilo iOS (para pantallas principales)
/// Usa CupertinoSliverNavigationBar internamente
class JPLargeTitleAppBar extends StatelessWidget {
  final String largeTitle;
  final Widget? leading;
  final Widget? trailing;

  const JPLargeTitleAppBar({
    super.key,
    required this.largeTitle,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverNavigationBar(
      backgroundColor: JPCupertinoColors.surface(context),
      border: null,
      largeTitle: Text(
        largeTitle,
        style: TextStyle(
          color: JPCupertinoColors.label(context),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      leading: leading,
      trailing: trailing,
    );
  }
}
