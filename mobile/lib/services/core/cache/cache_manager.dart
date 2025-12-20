// lib/services/core/cache/cache_manager.dart

import 'dart:developer' as developer;
import 'cache_entry.dart';

/// Gestor centralizado de cache en memoria con soporte para TTL.
///
/// Características:
/// - Singleton para acceso global
/// - Expiracion automática basada en TTL
/// - Invalidación por clave o patrón
/// - Type-safe con genéricos
///
/// Ejemplo de uso:
/// ```dart
/// final cache = CacheManager.instance;
///
/// // Guardar con TTL de 5 minutos
/// cache.set('user_profile', profile, ttl: Duration(minutes: 5));
///
/// // Recuperar
/// final profile = cache.get<Profile>('user_profile');
///
/// // Invalidar por patrón
/// cache.removeByPattern('^user_.*'); // Elimina user_profile, user_addresses, etc.
/// ```
class CacheManager {
  // ========================================================================
  // SINGLETON
  // ========================================================================

  static final CacheManager _instance = CacheManager._();
  static CacheManager get instance => _instance;
  CacheManager._();

  // ========================================================================
  // ESTADO
  // ========================================================================

  final Map<String, CacheEntry> _cache = {};

  void _log(String message, {Object? error}) {
    developer.log(message, name: 'CacheManager', error: error);
  }

  // ========================================================================
  // OPERACIONES BÁSICAS
  // ========================================================================

  /// Obtiene un valor del cache.
  ///
  /// Retorna:
  /// - El valor tipado si existe y no ha expirado
  /// - `null` si no existe o ya expiró
  ///
  /// Si la entrada expiró, se elimina automáticamente del cache.
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      _log('Cache expirado para clave: $key');
      _cache.remove(key);
      return null;
    }

    _log('Cache hit para clave: $key (age: ${entry.age.inSeconds}s)');
    return entry.value as T;
  }

  /// Guarda un valor en el cache.
  ///
  /// Parámetros:
  /// - [key]: Clave única para el cache
  /// - [value]: Valor a cachear
  /// - [ttl]: Tiempo de vida (Time To Live). Si es null, no expira.
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );

    final expiryMsg = ttl != null ? ' (TTL: ${ttl.inMinutes}min)' : ' (sin expiración)';
    _log('Cache guardado para clave: $key$expiryMsg');
  }

  /// Verifica si una clave existe en el cache y no ha expirado.
  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  // ========================================================================
  // INVALIDACIÓN
  // ========================================================================

  /// Elimina una entrada específica del cache.
  void remove(String key) {
    final removed = _cache.remove(key);
    if (removed != null) {
      _log('Cache eliminado para clave: $key');
    }
  }

  /// Elimina todas las entradas que coincidan con un patrón regex.
  ///
  /// Ejemplo:
  /// ```dart
  /// cache.removeByPattern('^user_.*'); // Elimina user_profile, user_addresses, etc.
  /// cache.removeByPattern('.*_list\$'); // Elimina todas las claves que terminan en _list
  /// ```
  void removeByPattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      _log('Cache eliminado por patrón "$pattern": ${keysToRemove.length} entradas');
    }
  }

  /// Elimina todas las entradas del cache.
  void clear() {
    final count = _cache.length;
    _cache.clear();
    _log('Cache limpiado completamente: $count entradas eliminadas');
  }

  /// Elimina todas las entradas expiradas del cache.
  ///
  /// Esta operación se puede ejecutar periódicamente para liberar memoria.
  void cleanExpired() {
    final keysToRemove = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      _log('Cache expirado limpiado: ${keysToRemove.length} entradas');
    }
  }

  // ========================================================================
  // MÉTRICAS Y DEBUGGING
  // ========================================================================

  /// Número total de entradas en el cache (incluyendo expiradas).
  int get size => _cache.length;

  /// Número de entradas válidas (no expiradas).
  int get activeSize {
    return _cache.values.where((entry) => !entry.isExpired).length;
  }

  /// Número de entradas expiradas.
  int get expiredSize {
    return _cache.values.where((entry) => entry.isExpired).length;
  }

  /// Estadísticas del cache.
  Map<String, dynamic> get stats => {
        'total': size,
        'active': activeSize,
        'expired': expiredSize,
        'keys': _cache.keys.toList(),
      };

  /// Imprime las estadísticas del cache en los logs.
  void printStats() {
    _log('Cache stats: $stats');
  }
}
