// lib/widgets/common/jp_cupertino_button.dart

import 'package:flutter/cupertino.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🔘 CUPERTINO BUTTON - Botones unificados estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

enum JPButtonSize {
  small,
  compact,
  medium,
  large,
}

/// Botón base iOS con variantes: filled, outlined y text
class JPCupertinoButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final JPButtonSize size;
  final bool fullWidth;
  final bool loading;

  // Variantes privadas
  final _ButtonVariant _variant;

  // Constructor privado
  const JPCupertinoButton._({
    super.key,
    this.text,
    this.child,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.size = JPButtonSize.medium,
    this.fullWidth = false,
    this.loading = false,
    required _ButtonVariant variant,
  }) : _variant = variant;

  /// Botón filled (fondo sólido, texto blanco)
  const JPCupertinoButton.filled({
    Key? key,
    String? text,
    Widget? child,
    IconData? icon,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    JPButtonSize size = JPButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
  }) : this._(
          key: key,
          text: text,
          child: child,
          icon: icon,
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          size: size,
          fullWidth: fullWidth,
          loading: loading,
          variant: _ButtonVariant.filled,
        );

  /// Botón outlined (borde, texto coloreado)
  const JPCupertinoButton.outlined({
    Key? key,
    String? text,
    Widget? child,
    IconData? icon,
    VoidCallback? onPressed,
    Color? borderColor,
    Color? foregroundColor,
    JPButtonSize size = JPButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
  }) : this._(
          key: key,
          text: text,
          child: child,
          icon: icon,
          onPressed: onPressed,
          borderColor: borderColor,
          foregroundColor: foregroundColor,
          size: size,
          fullWidth: fullWidth,
          loading: loading,
          variant: _ButtonVariant.outlined,
        );

  /// Botón text (solo texto, sin fondo ni borde)
  const JPCupertinoButton.text({
    Key? key,
    String? text,
    Widget? child,
    IconData? icon,
    VoidCallback? onPressed,
    Color? foregroundColor,
    JPButtonSize size = JPButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
  }) : this._(
          key: key,
          text: text,
          child: child,
          icon: icon,
          onPressed: onPressed,
          foregroundColor: foregroundColor,
          size: size,
          fullWidth: fullWidth,
          loading: loading,
          variant: _ButtonVariant.text,
        );

  /// Botón destructive (estilo iOS para acciones destructivas)
  const JPCupertinoButton.destructive({
    Key? key,
    String? text,
    Widget? child,
    IconData? icon,
    VoidCallback? onPressed,
    JPButtonSize size = JPButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
  }) : this._(
          key: key,
          text: text,
          child: child,
          icon: icon,
          onPressed: onPressed,
          size: size,
          fullWidth: fullWidth,
          loading: loading,
          variant: _ButtonVariant.destructive,
        );

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isDisabled ? null : onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDisabled ? 0.3 : 1.0,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: _getPadding(),
          decoration: _getDecoration(context),
          child: loading
              ? _buildLoadingIndicator(context)
              : _buildContent(context),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case JPButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case JPButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case JPButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case JPButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (size) {
      case JPButtonSize.small:
        return 13;
      case JPButtonSize.compact:
        return 14;
      case JPButtonSize.medium:
        return 16;
      case JPButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (size) {
      case JPButtonSize.small:
        return 14;
      case JPButtonSize.compact:
        return 16;
      case JPButtonSize.medium:
        return 18;
      case JPButtonSize.large:
        return 20;
    }
  }

  BoxDecoration _getDecoration(BuildContext context) {
    switch (_variant) {
      case _ButtonVariant.filled:
        final bgColor = backgroundColor ?? JPCupertinoColors.systemBlue(context);
        return BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(JPConstants.radiusButton),
        );

      case _ButtonVariant.outlined:
        final lineColor = borderColor ??
                         foregroundColor ??
                         JPCupertinoColors.systemBlue(context);
        return BoxDecoration(
          border: Border.all(color: lineColor, width: 1.5),
          borderRadius: BorderRadius.circular(JPConstants.radiusButton),
        );

      case _ButtonVariant.text:
        return const BoxDecoration();

      case _ButtonVariant.destructive:
        return BoxDecoration(
          color: JPCupertinoColors.destructive(context),
          borderRadius: BorderRadius.circular(JPConstants.radiusButton),
        );
    }
  }

  Color _getForegroundColor(BuildContext context) {
    if (foregroundColor != null) return foregroundColor!;

    switch (_variant) {
      case _ButtonVariant.filled:
        return CupertinoColors.white;

      case _ButtonVariant.outlined:
        return JPCupertinoColors.systemBlue(context);

      case _ButtonVariant.text:
        return JPCupertinoColors.systemBlue(context);

      case _ButtonVariant.destructive:
        return CupertinoColors.white;
    }
  }

  Widget _buildContent(BuildContext context) {
    final textColor = _getForegroundColor(context);
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();

    // Si hay child personalizado, usarlo directamente
    if (child != null) {
      return DefaultTextStyle(
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        child: IconTheme(
          data: IconThemeData(color: textColor, size: iconSize),
          child: child!,
        ),
      );
    }

    // Si solo hay icon y texto
    if (icon != null && text != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 6),
          Text(
            text!,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // Solo icono
    if (icon != null) {
      return Icon(icon, size: iconSize, color: textColor);
    }

    // Solo texto
    return Text(
      text ?? '',
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final indicatorColor = _getForegroundColor(context);

    return SizedBox(
      height: _getFontSize() + 4,
      width: _getFontSize() + 4,
      child: CupertinoActivityIndicator(
        color: indicatorColor,
        radius: _getFontSize() * 0.5,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎯 BUTTON VARIANT - Enum interno para variantes
// ══════════════════════════════════════════════════════════════════════════════

enum _ButtonVariant {
  filled,
  outlined,
  text,
  destructive,
}
