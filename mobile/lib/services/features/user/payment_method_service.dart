// lib/services/features/user/payment_method_service.dart

import '../../../apis/resources/users/payment_methods_api.dart';
import '../../../apis/mappers/user_mapper.dart';
import '../../../models/users/payment_method.dart';
import '../../core/cache/cache_manager.dart';
import 'dart:developer' as developer;

/// Servicio para gestionar métodos de pago de usuario.
///
/// Responsabilidades:
/// - Lógica de negocio (validaciones, reglas)
/// - Cache con TTL
/// - Orquestación de operaciones
/// - Transformación DTO → Model
/// - NO comunicación HTTP directa
class PaymentMethodService {
  final PaymentMethodsApi _api;
  final CacheManager _cache;

  // ========================================================================
  // SINGLETON MEJORADO CON DI OPCIONAL
  // ========================================================================

  static PaymentMethodService? _instance;

  factory PaymentMethodService({
    PaymentMethodsApi? api,
    CacheManager? cache,
  }) {
    return _instance ??= PaymentMethodService._(
      api: api ?? PaymentMethodsApi(),
      cache: cache ?? CacheManager.instance,
    );
  }

  PaymentMethodService._({
    required PaymentMethodsApi api,
    required CacheManager cache,
  })  : _api = api,
        _cache = cache;

  static void resetInstance() => _instance = null;

  // ========================================================================
  // CONFIGURACIÓN DE CACHE
  // ========================================================================

  static const _paymentMethodsListKey = 'user_payment_methods_list';
  static const _defaultPaymentMethodKey = 'user_default_payment_method';
  static const _paymentMethodCacheTTL = Duration(minutes: 5);

  void _log(String msg, {Object? error, StackTrace? stackTrace}) {
    developer.log(msg, name: 'PaymentMethodService', error: error, stackTrace: stackTrace);
  }

  // ========================================================================
  // MÉTODOS PÚBLICOS - CRUD
  // ========================================================================

  /// Lista todos los métodos de pago del usuario.
  ///
  /// Usa cache con TTL de 5 minutos.
  ///
  /// Parámetros:
  /// - [forceRefresh]: Si true, ignora cache y consulta API.
  Future<List<PaymentMethod>> listPaymentMethods({bool forceRefresh = false}) async {
    try {
      // 1. Check cache
      if (!forceRefresh) {
        final cached = _cache.get<List<PaymentMethod>>(_paymentMethodsListKey);
        if (cached != null) {
          _log('Retornando ${cached.length} métodos de pago desde cache');
          return cached;
        }
      }

      // 2. Fetch from API
      _log('Obteniendo métodos de pago desde API');
      final responses = await _api.listPaymentMethods();

      // 3. Transform DTOs → Models
      final paymentMethods = responses
          .map((dto) => UserMapper.paymentMethodToModel(dto))
          .toList();

      // 4. Update cache
      _cache.set(_paymentMethodsListKey, paymentMethods, ttl: _paymentMethodCacheTTL);

      _log('Obtenidos ${paymentMethods.length} métodos de pago');
      return paymentMethods;
    } catch (e, stackTrace) {
      _log('Error listando métodos de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene un método de pago específico por ID.
  ///
  /// Parámetros:
  /// - [id]: ID del método de pago.
  Future<PaymentMethod> getPaymentMethod(String id) async {
    try {
      // Check individual cache first
      final cacheKey = 'user_payment_method_$id';
      final cached = _cache.get<PaymentMethod>(cacheKey);
      if (cached != null) {
        _log('Retornando método de pago $id desde cache');
        return cached;
      }

      // Fetch from API
      _log('Obteniendo método de pago $id desde API');
      final response = await _api.getPaymentMethod(id);

      // Transform DTO → Model
      final paymentMethod = UserMapper.paymentMethodToModel(response);

      // Update cache
      _cache.set(cacheKey, paymentMethod, ttl: _paymentMethodCacheTTL);

      return paymentMethod;
    } catch (e, stackTrace) {
      _log('Error obteniendo método de pago $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Crea un nuevo método de pago.
  ///
  /// Validaciones:
  /// - Alias no puede estar vacío
  /// - Si requiere verificación, debe tener comprobante
  ///
  /// Parámetros:
  /// - [paymentMethod]: Método de pago a crear.
  Future<PaymentMethod> createPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      // 1. Validar reglas de negocio
      _validatePaymentMethod(paymentMethod);

      // 2. Verificar duplicados (alias único)
      await _checkDuplicateAlias(paymentMethod.alias);

      // 3. Transform Model → DTO
      final request = UserMapper.paymentMethodToCreateRequest(paymentMethod);

      // 4. Call API
      _log('Creando método de pago: ${paymentMethod.alias}');
      final response = await _api.createPaymentMethod(request);

      // 5. Transform DTO → Model
      final created = UserMapper.paymentMethodToModel(response);

      // 6. Invalidate cache
      _cache.removeByPattern('^user_.*payment.*');

      _log('Método de pago creado exitosamente: ${created.id}');
      return created;
    } catch (e, stackTrace) {
      _log('Error creando método de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualiza un método de pago existente.
  ///
  /// Parámetros:
  /// - [paymentMethod]: Método de pago con datos actualizados.
  Future<PaymentMethod> updatePaymentMethod(PaymentMethod paymentMethod) async {
    try {
      // 1. Validar reglas de negocio
      _validatePaymentMethod(paymentMethod);

      // 2. Verificar duplicados (solo si cambió el alias)
      final original = await getPaymentMethod(paymentMethod.id);
      if (original.alias != paymentMethod.alias) {
        await _checkDuplicateAlias(paymentMethod.alias, excludeId: paymentMethod.id);
      }

      // 3. Transform Model → DTO
      final request = UserMapper.paymentMethodToUpdateRequest(paymentMethod);

      // 4. Call API
      _log('Actualizando método de pago: ${paymentMethod.id}');
      final response = await _api.updatePaymentMethod(paymentMethod.id, request);

      // 5. Transform DTO → Model
      final updated = UserMapper.paymentMethodToModel(response);

      // 6. Invalidate cache
      _cache.removeByPattern('^user_.*payment.*');

      _log('Método de pago actualizado exitosamente');
      return updated;
    } catch (e, stackTrace) {
      _log('Error actualizando método de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Elimina un método de pago.
  ///
  /// No se puede eliminar el método predeterminado a menos que sea el único.
  ///
  /// Parámetros:
  /// - [id]: ID del método de pago a eliminar.
  Future<void> deletePaymentMethod(String id) async {
    try {
      // 1. Validar que no sea el método predeterminado
      final paymentMethod = await getPaymentMethod(id);
      if (paymentMethod.isDefault) {
        final allMethods = await listPaymentMethods();
        if (allMethods.length > 1) {
          throw PaymentMethodValidationException(
            'No se puede eliminar el método de pago predeterminado. '
            'Por favor, seleccione otro método como predeterminado primero.',
          );
        }
      }

      // 2. Call API
      _log('Eliminando método de pago: $id');
      await _api.deletePaymentMethod(id);

      // 3. Invalidate cache
      _cache.removeByPattern('^user_.*payment.*');

      _log('Método de pago eliminado exitosamente');
    } catch (e, stackTrace) {
      _log('Error eliminando método de pago', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ========================================================================
  // MÉTODOS PÚBLICOS - OPERACIONES ESPECIALES
  // ========================================================================

  /// Obtiene el método de pago predeterminado del usuario.
  ///
  /// Retorna null si no hay método predeterminado configurado.
  Future<PaymentMethod?> getDefaultPaymentMethod({bool forceRefresh = false}) async {
    try {
      // 1. Check cache
      if (!forceRefresh) {
        final cached = _cache.get<PaymentMethod?>(_defaultPaymentMethodKey);
        if (cached != null) {
          _log('Retornando método de pago predeterminado desde cache');
          return cached;
        }
      }

      // 2. Fetch from API
      _log('Obteniendo método de pago predeterminado desde API');
      final response = await _api.getDefaultPaymentMethod();

      if (response == null) {
        _log('No hay método de pago predeterminado configurado');
        return null;
      }

      // 3. Transform DTO → Model
      final defaultMethod = UserMapper.paymentMethodToModel(response);

      // 4. Update cache
      _cache.set(_defaultPaymentMethodKey, defaultMethod, ttl: _paymentMethodCacheTTL);

      return defaultMethod;
    } catch (e, stackTrace) {
      _log('Error obteniendo método de pago predeterminado', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Establece un método de pago como predeterminado.
  ///
  /// Parámetros:
  /// - [id]: ID del método de pago a marcar como predeterminado.
  Future<PaymentMethod> setAsDefault(String id) async {
    try {
      final paymentMethod = await getPaymentMethod(id);

      if (paymentMethod.isDefault) {
        _log('El método de pago $id ya es el predeterminado');
        return paymentMethod;
      }

      // Actualizar con isDefault = true
      final updated = paymentMethod.copyWith(isDefault: true);
      return await updatePaymentMethod(updated);
    } catch (e, stackTrace) {
      _log('Error estableciendo método de pago predeterminado', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Filtra métodos de pago por tipo.
  ///
  /// Parámetros:
  /// - [type]: Tipo de método de pago (efectivo, transferencia, tarjeta).
  Future<List<PaymentMethod>> getPaymentMethodsByType(String type) async {
    try {
      final allMethods = await listPaymentMethods();
      return allMethods
          .where((method) => method.type.toLowerCase() == type.toLowerCase())
          .toList();
    } catch (e, stackTrace) {
      _log('Error filtrando métodos de pago por tipo', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene métodos de pago pendientes de verificación.
  ///
  /// Retorna solo los métodos que requieren verificación pero no tienen comprobante.
  Future<List<PaymentMethod>> getPendingVerificationMethods() async {
    try {
      final allMethods = await listPaymentMethods();
      return allMethods
          .where((method) => method.isPendingVerification)
          .toList();
    } catch (e, stackTrace) {
      _log('Error obteniendo métodos pendientes de verificación', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ========================================================================
  // VALIDACIONES DE NEGOCIO
  // ========================================================================

  void _validatePaymentMethod(PaymentMethod paymentMethod) {
    // Validar que el alias no esté vacío
    if (paymentMethod.alias.trim().isEmpty) {
      throw PaymentMethodValidationException(
        'El alias del método de pago no puede estar vacío',
      );
    }

    // Validar longitud del alias
    if (paymentMethod.alias.length < 3) {
      throw PaymentMethodValidationException(
        'El alias debe tener al menos 3 caracteres',
      );
    }

    if (paymentMethod.alias.length > 50) {
      throw PaymentMethodValidationException(
        'El alias no puede exceder 50 caracteres',
      );
    }

    // Validar que si requiere verificación, debe tener comprobante
    if (paymentMethod.requiresVerification && !paymentMethod.hasProof) {
      _log('Advertencia: Método de pago requiere verificación pero no tiene comprobante');
      // No lanzamos excepción porque el backend puede manejar esto
    }
  }

  /// Verifica si ya existe un método de pago con el mismo alias.
  ///
  /// Lanza [DuplicatePaymentMethodException] si encuentra un duplicado.
  Future<void> _checkDuplicateAlias(String alias, {String? excludeId}) async {
    try {
      final paymentMethods = await listPaymentMethods();

      final duplicate = paymentMethods.any((method) =>
          method.alias.toLowerCase() == alias.toLowerCase() &&
          method.id != excludeId);

      if (duplicate) {
        throw DuplicatePaymentMethodException(
          'Ya existe un método de pago con el alias "$alias"',
        );
      }
    } catch (e) {
      if (e is DuplicatePaymentMethodException) rethrow;
      // Si falla la verificación de duplicados, permitimos continuar
      // El backend hará la validación final
      _log('No se pudo verificar duplicados de alias', error: e);
    }
  }

  // ========================================================================
  // CACHE MANAGEMENT
  // ========================================================================

  /// Limpia el cache de métodos de pago.
  void clearCache() {
    _log('Limpiando cache de métodos de pago');
    _cache.removeByPattern('^user_.*payment.*');
  }

  /// Limpia todo el cache relacionado con métodos de pago.
  void clearAllCache() {
    _log('Limpiando todo el cache de métodos de pago');
    _cache.remove(_paymentMethodsListKey);
    _cache.remove(_defaultPaymentMethodKey);
    _cache.removeByPattern('^user_payment_method_');
  }
}

// ========================================================================
// EXCEPCIONES PERSONALIZADAS
// ========================================================================

/// Excepción cuando se intenta crear un método de pago duplicado.
class DuplicatePaymentMethodException implements Exception {
  final String message;
  DuplicatePaymentMethodException(this.message);

  @override
  String toString() => 'DuplicatePaymentMethodException: $message';
}

/// Excepción para validaciones de métodos de pago.
class PaymentMethodValidationException implements Exception {
  final String message;
  PaymentMethodValidationException(this.message);

  @override
  String toString() => 'PaymentMethodValidationException: $message';
}
