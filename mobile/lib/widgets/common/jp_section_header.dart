// lib/widgets/common/jp_section_header.dart

import 'package:flutter/cupertino.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 📝 SECTION HEADER - Header de sección estilo iOS Settings
// ══════════════════════════════════════════════════════════════════════════════

/// Header de sección estilo iOS (como en Settings)
///
/// Características:
/// - Texto en mayúsculas
/// - Color gris secundario
/// - Tamaño 13px, peso 500
/// - Letter spacing ajustado
/// - Padding personalizable
class JPSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;
  final bool uppercase;

  const JPSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
    this.uppercase = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            left: JPConstants.spacingHorizontal,
            bottom: JPConstants.spacingSmall,
            top: JPConstants.spacingSection,
          ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              uppercase ? title.toUpperCase() : title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: JPCupertinoColors.systemGrey(context),
                letterSpacing: -0.08,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
