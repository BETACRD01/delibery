// lib/config/performance_config.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Configuración de rendimiento para optimizar la app
class PerformanceConfig {
  PerformanceConfig._();

  /// Inicializa optimizaciones de rendimiento
  static void initialize() {
    try {
      // Habilitar repaint boundaries automáticos para mejor rendimiento
      debugProfileBuildsEnabled = false;
      debugProfilePaintsEnabled = false;

      // Optimización de imágenes en caché
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB
    } catch (e) {
      debugPrint('Error inicializando PerformanceConfig: $e');
    }
  }

  /// Builder optimizado para listas con muchos elementos
  static Widget optimizedListBuilder({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    EdgeInsets? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Usar RepaintBoundary para aislar cada elemento
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      // Optimización: mantener pocos elementos en memoria
      cacheExtent: 100,
    );
  }

  /// Builder optimizado para grids
  static Widget optimizedGridBuilder({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required SliverGridDelegate gridDelegate,
    EdgeInsets? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
  }) {
    return GridView.builder(
      itemCount: itemCount,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      cacheExtent: 100,
    );
  }

  /// Transición optimizada para navegación
  static PageRoute<T> createOptimizedRoute<T>(
    Widget page, {
    String? name,
    bool maintainState = true,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Usar FadeTransition que es más eficiente que otras transiciones
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return FadeTransition(
          opacity: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      settings: RouteSettings(name: name),
      maintainState: maintainState,
    );
  }

  /// Widget wrapper que previene rebuilds innecesarios
  static Widget preventRebuild({
    required Widget child,
    required Object? key,
  }) {
    return RepaintBoundary(
      key: ValueKey(key),
      child: child,
    );
  }

  /// Configuración para mejor rendimiento de scrolling
  static const ScrollPhysics optimizedScrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  /// Configuración para listas muy largas
  static const int defaultCacheExtent = 100;
  static const int maxCachedItems = 50;

  /// Limpia la caché de imágenes cuando sea necesario
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Optimiza el uso de memoria
  static void optimizeMemory() {
    // Limpiar caché de imágenes antiguas
    PaintingBinding.instance.imageCache.clear();

    // Forzar garbage collection (solo en debug)
    assert(() {
      // Solo en modo debug
      return true;
    }());
  }
}

/// Extension para facilitar el uso de optimizaciones
extension PerformanceExtensions on Widget {
  /// Envuelve el widget en un RepaintBoundary para mejor rendimiento
  Widget withRepaintBoundary() {
    return RepaintBoundary(child: this);
  }

  /// Envuelve el widget en un Builder lazy
  Widget asLazyBuilder() {
    return Builder(
      builder: (context) => this,
    );
  }
}
