// lib/services/core/cache/cache_service.dart
// Servicio de caché en memoria para optimizar carga de datos

import 'dart:async';

// ══════════════════════════════════════════════════════════════════════════════
// 📦 CACHE ENTRY - Entrada de caché con TTL
// ══════════════════════════════════════════════════════════════════════════════

class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({required this.data, required this.ttl})
    : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  Duration get remainingTime {
    final elapsed = DateTime.now().difference(createdAt);
    final remaining = ttl - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🗄️ CACHE SERVICE - Servicio de caché en memoria
// ══════════════════════════════════════════════════════════════════════════════

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};

  /// TTL por defecto: 5 minutos
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Obtener valor del caché
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  /// Guardar valor en caché
  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = CacheEntry<T>(data: value, ttl: ttl ?? defaultTTL);
  }

  /// Verificar si existe en caché y no ha expirado
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Obtener o ejecutar fetch si no existe
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetch, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) return cached;

    final data = await fetch();
    set<T>(key, data, ttl: ttl);
    return data;
  }

  /// Invalidar entrada específica
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidar todas las entradas que empiecen con un prefijo
  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Limpiar todo el caché
  void clear() {
    _cache.clear();
  }

  /// Limpiar entradas expiradas
  void cleanExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🔑 CACHE KEYS - Claves predefinidas para el caché
// ══════════════════════════════════════════════════════════════════════════════

class CacheKeys {
  // Categorías
  static const String categorias = 'categorias';
  static String categoriaProductos(int id) => 'categoria_productos_$id';

  // Productos
  static const String productosDestacados = 'productos_destacados';
  static const String productosOfertas = 'productos_ofertas';
  static const String productosPopulares = 'productos_populares';
  static String productoDetalle(int id) => 'producto_$id';

  // Usuario
  static const String perfilUsuario = 'perfil_usuario';
  static const String pedidosActivos = 'pedidos_activos';
  static const String direcciones = 'direcciones';

  // Proveedor
  static const String proveedores = 'proveedores';
  static String proveedorDetalle(int id) => 'proveedor_$id';
}
