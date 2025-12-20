// lib/widgets/common/jp_list_tile.dart

import 'package:flutter/cupertino.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 📋 LIST TILE - ListTile estilo iOS Settings
// ══════════════════════════════════════════════════════════════════════════════

/// ListTile estilo iOS (como en Settings)
///
/// Características:
/// - Leading icon en contenedor cuadrado con color de fondo
/// - Título y subtítulo opcionales
/// - Chevron trailing por defecto
/// - Divider con indent desde el icono
/// - Tap con CupertinoButton (sin ripple)
class JPListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;
  final EdgeInsets? padding;

  const JPListTile({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: JPConstants.spacingHorizontal,
                  vertical: JPConstants.spacingItem,
                ),
            child: Row(
              children: [
                // Leading icon
                Container(
                  width: JPConstants.iconContainerSize,
                  height: JPConstants.iconContainerSize,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(JPConstants.radiusIcon),
                  ),
                  child: Icon(
                    icon,
                    color: CupertinoColors.white,
                    size: JPConstants.iconSizeSmall + 2,
                  ),
                ),
                const SizedBox(width: 14),
                // Title y subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          color: JPCupertinoColors.label(context),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: JPCupertinoColors.secondaryLabel(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing
                if (trailing != null)
                  trailing!
                else if (showChevron)
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: JPCupertinoColors.systemGrey3(context),
                  ),
              ],
            ),
          ),
        ),
        // Divider con indent
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Container(
              height: 0.5,
              color: JPCupertinoColors.separator(context),
            ),
          ),
      ],
    );
  }
}
