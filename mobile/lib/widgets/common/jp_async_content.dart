// lib/widgets/common/jp_async_content.dart
// Widget reutilizable para manejar 3 estados: loading/success/error
// con transiciones suaves estilo iOS

import 'package:flutter/cupertino.dart';

import '../../theme/primary_colors.dart';
import '../../theme/secondary_colors.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 📦 ASYNC STATE - Estados posibles del contenido asíncrono
// ══════════════════════════════════════════════════════════════════════════════

enum AsyncStatus { loading, success, error }

/// Estado genérico para contenido asíncrono
class AsyncState<T> {
  final AsyncStatus status;
  final T? data;
  final String? errorMessage;

  const AsyncState._({required this.status, this.data, this.errorMessage});

  /// Estado de carga
  factory AsyncState.loading() =>
      const AsyncState._(status: AsyncStatus.loading);

  /// Estado de éxito con datos
  factory AsyncState.success(T data) =>
      AsyncState._(status: AsyncStatus.success, data: data);

  /// Estado de error
  factory AsyncState.error(String message) =>
      AsyncState._(status: AsyncStatus.error, errorMessage: message);

  bool get isLoading => status == AsyncStatus.loading;
  bool get isSuccess => status == AsyncStatus.success;
  bool get isError => status == AsyncStatus.error;
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎭 JP ASYNC CONTENT - Widget con transiciones suaves
// ══════════════════════════════════════════════════════════════════════════════

/// Widget que maneja 3 estados con transiciones suaves estilo iOS
class JPAsyncContent<T> extends StatelessWidget {
  /// Estado actual del contenido
  final AsyncState<T> state;

  /// Builder para el contenido cuando hay datos
  final Widget Function(T data) builder;

  /// Widget de loading (skeleton/shimmer)
  final Widget? loadingWidget;

  /// Callback para reintentar en caso de error
  final VoidCallback? onRetry;

  /// Mensaje personalizado de error
  final String? errorTitle;
  final String? errorMessage;

  /// Duración de la transición
  final Duration transitionDuration;

  const JPAsyncContent({
    super.key,
    required this.state,
    required this.builder,
    this.loadingWidget,
    this.onRetry,
    this.errorTitle,
    this.errorMessage,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state.status) {
      case AsyncStatus.loading:
        return KeyedSubtree(
          key: const ValueKey('loading'),
          child: loadingWidget ?? _buildDefaultLoading(context),
        );

      case AsyncStatus.success:
        return KeyedSubtree(
          key: const ValueKey('success'),
          child: builder(state.data as T),
        );

      case AsyncStatus.error:
        return KeyedSubtree(
          key: const ValueKey('error'),
          child: _buildError(context),
        );
    }
  }

  Widget _buildDefaultLoading(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(
        radius: 14,
        color: JPCupertinoColors.systemGrey(context),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 56,
              color: AppColorsSupport.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorTitle ?? 'Algo salió mal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColorsSupport.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ??
                  errorMessage ??
                  'Ocurrió un error inesperado',
              style: TextStyle(
                fontSize: 14,
                color: AppColorsSupport.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                borderRadius: BorderRadius.circular(12),
                onPressed: onRetry,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🔄 JP ASYNC SLIVER - Versión Sliver para CustomScrollView
// ══════════════════════════════════════════════════════════════════════════════

/// Versión Sliver del JPAsyncContent para usar en CustomScrollView
class JPAsyncSliver<T> extends StatelessWidget {
  final AsyncState<T> state;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final VoidCallback? onRetry;
  final String? errorTitle;
  final Duration transitionDuration;

  const JPAsyncSliver({
    super.key,
    required this.state,
    required this.builder,
    this.loadingWidget,
    this.onRetry,
    this.errorTitle,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case AsyncStatus.loading:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: AnimatedSwitcher(
            duration: transitionDuration,
            child: loadingWidget ?? _buildDefaultLoading(context),
          ),
        );

      case AsyncStatus.success:
        return builder(state.data as T);

      case AsyncStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildError(context),
        );
    }
  }

  Widget _buildDefaultLoading(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(
        radius: 14,
        color: JPCupertinoColors.systemGrey(context),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 56,
              color: AppColorsSupport.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorTitle ?? 'Algo salió mal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColorsSupport.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ⏳ JP LOADING OVERLAY - Overlay de carga fullscreen
// ══════════════════════════════════════════════════════════════════════════════

/// Overlay de carga estilo iOS
class JPLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? barrierColor;

  const JPLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color:
                  barrierColor ?? CupertinoColors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: JPCupertinoColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(
                        radius: 16,
                        color: AppColorsPrimary.main,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColorsSupport.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
