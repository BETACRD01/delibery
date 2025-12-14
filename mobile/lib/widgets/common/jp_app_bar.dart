// lib/widgets/common/jp_app_bar.dart

import 'package:flutter/material.dart';
import '../../theme/jp_theme.dart';

/// AppBar reutilizable con diseño consistente
class JPAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const JPAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.3,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? JPColors.textPrimary,
      elevation: elevation,
      shadowColor: Colors.black12,
      centerTitle: centerTitle,
      leading: leading ??
          (Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

/// AppBar con buscador integrado
class JPSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  final TextEditingController? controller;
  final List<Widget>? actions;
  final bool autoFocus;

  const JPSearchAppBar({
    super.key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSearchTap,
    this.controller,
    this.actions,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.3,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: JPColors.textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: TextField(
        controller: controller,
        autofocus: autoFocus,
        onChanged: onChanged,
        onTap: onSearchTap,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          hintStyle: const TextStyle(
            color: JPColors.textHint,
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: JPColors.textHint,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: JPColors.textPrimary,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
