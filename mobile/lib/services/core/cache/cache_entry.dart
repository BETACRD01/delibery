// lib/services/core/cache/cache_entry.dart

/// Entrada de cache con soporte para expiración automática (TTL).
///
/// Cada entrada almacena:
/// - [value]: El valor cacheado (puede ser de cualquier tipo T)
/// - [expiresAt]: Fecha/hora de expiración (null = sin expiración)
/// - [createdAt]: Fecha/hora de creación
class CacheEntry<T> {
  final T value;
  final DateTime? expiresAt;
  final DateTime createdAt;

  CacheEntry({
    required this.value,
    this.expiresAt,
  }) : createdAt = DateTime.now();

  /// Verifica si la entrada ha expirado.
  ///
  /// Retorna:
  /// - `true` si tiene fecha de expiración y ya pasó
  /// - `false` si no tiene fecha de expiración o aún es válida
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Tiempo transcurrido desde que se creó la entrada.
  Duration get age => DateTime.now().difference(createdAt);

  /// Tiempo restante hasta la expiración.
  ///
  /// Retorna:
  /// - Duration negativa si ya expiró
  /// - null si no tiene fecha de expiración
  Duration? get timeToExpire {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now());
  }

  @override
  String toString() {
    final expiry = expiresAt != null
        ? 'expires at ${expiresAt!.toIso8601String()}'
        : 'no expiration';
    return 'CacheEntry<$T>($expiry, age: ${age.inSeconds}s)';
  }
}
