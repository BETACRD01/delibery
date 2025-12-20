// lib/utils/add_to_cart_debounce.dart

/// Utilidad para prevenir spam al agregar productos al carrito
///
/// Implementa un cooldown de 800ms entre cada intento de agregar
/// el mismo producto al carrito, previniendo clicks accidentales múltiples.
///
/// Uso:
/// ```dart
/// if (!AddToCartDebounce.canAdd(productoId)) {
///   ToastService().showInfo(context, 'Por favor espera un momento');
///   return;
/// }
/// // Proceder con agregar al carrito...
/// ```
class AddToCartDebounce {
  static final Map<String, DateTime> _lastAttempts = {};
  static const Duration _cooldown = Duration(milliseconds: 800);

  /// Verifica si se puede agregar un producto al carrito
  ///
  /// Retorna true si pasó el cooldown desde el último intento,
  /// false si debe esperar.
  ///
  /// [productId] - ID único del producto a verificar
  static bool canAdd(String productId) {
    final now = DateTime.now();
    final lastAttempt = _lastAttempts[productId];

    if (lastAttempt == null ||
        now.difference(lastAttempt) > _cooldown) {
      _lastAttempts[productId] = now;
      return true;
    }

    return false;
  }

  /// Limpia el cooldown para un producto específico
  ///
  /// Útil cuando se quiere permitir inmediatamente otro intento
  /// (ej: después de quitar y volver a agregar un producto)
  static void reset(String productId) {
    _lastAttempts.remove(productId);
  }

  /// Limpia todos los cooldowns
  ///
  /// Útil al navegar a otra pantalla o cerrar sesión
  static void resetAll() {
    _lastAttempts.clear();
  }

  /// Obtiene el tiempo restante de cooldown para un producto
  ///
  /// Retorna null si no hay cooldown activo
  static Duration? getRemainingCooldown(String productId) {
    final lastAttempt = _lastAttempts[productId];
    if (lastAttempt == null) return null;

    final now = DateTime.now();
    final elapsed = now.difference(lastAttempt);

    if (elapsed >= _cooldown) return null;

    return _cooldown - elapsed;
  }
}
