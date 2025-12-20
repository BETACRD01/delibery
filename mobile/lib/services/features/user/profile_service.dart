// lib/services/features/user/profile_service.dart

import 'dart:developer' as developer;
import '../../../apis/resources/users/profile_api.dart';
import '../../../apis/mappers/user_mapper.dart';
import '../../../models/user/profile.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/validation/validators.dart';

/// Servicio de lógica de negocio para el perfil de usuario.
///
/// Responsabilidades:
/// - Casos de uso de negocio
/// - Validaciones de reglas de negocio
/// - Cache con TTL
/// - Transformación DTO → Model
/// - Orquestación entre APIs
/// - Manejo de errores contextual
///
/// NO responsabilidades:
/// - Llamadas HTTP directas (usa ProfileApi)
/// - Navegación (responsabilidad de UI)
/// - Serialización JSON (responsabilidad de DTOs)
class ProfileService {
  final ProfileApi _api;
  final CacheManager _cache;

  // ========================================================================
  // SINGLETON MEJORADO CON DI OPCIONAL
  // ========================================================================

  static ProfileService? _instance;

  factory ProfileService({
    ProfileApi? api,
    CacheManager? cache,
  }) {
    return _instance ??= ProfileService._(
      api: api ?? ProfileApi(),
      cache: cache ?? CacheManager.instance,
    );
  }

  ProfileService._({
    required ProfileApi api,
    required CacheManager cache,
  })  : _api = api,
        _cache = cache;

  /// Reset para testing
  static void resetInstance() => _instance = null;

  // ========================================================================
  // CACHE CONFIGURATION
  // ========================================================================

  static const _cacheKey = 'user_profile';
  static const _cacheTTL = Duration(minutes: 10);

  void _log(String msg, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      msg,
      name: 'ProfileService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ========================================================================
  // CASOS DE USO
  // ========================================================================

  /// Obtiene el perfil del usuario autenticado.
  ///
  /// Flujo:
  /// 1. Verifica cache (si no es forzado)
  /// 2. Si no hay cache, llama a la API
  /// 3. Transforma DTO → Model
  /// 4. Actualiza cache con TTL
  /// 5. Retorna Model
  ///
  /// Parámetros:
  /// - [forceRefresh]: Si es true, ignora el cache y hace petición HTTP
  ///
  /// Returns: [Profile] con los datos del usuario
  ///
  /// Throws:
  /// - [ApiException] si hay error HTTP
  Future<Profile> getProfile({bool forceRefresh = false}) async {
    try {
      // 1. Check cache
      if (!forceRefresh) {
        final cached = _cache.get<Profile>(_cacheKey);
        if (cached != null) {
          _log('Retornando perfil desde cache');
          return cached;
        }
      }

      // 2. Fetch from API
      _log('Obteniendo perfil desde API');
      final response = await _api.getProfile();

      // 3. Transform DTO → Model
      final profile = UserMapper.profileToModel(response);

      // 4. Update cache
      _cache.set(_cacheKey, profile, ttl: _cacheTTL);

      _log('Perfil obtenido y cacheado correctamente');
      return profile;
    } catch (e, stackTrace) {
      _log('Error obteniendo perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualiza el perfil del usuario.
  ///
  /// Flujo:
  /// 1. Valida reglas de negocio
  /// 2. Transforma Model → DTO
  /// 3. Llama a la API
  /// 4. Transforma DTO → Model
  /// 5. Actualiza cache
  /// 6. Retorna Model actualizado
  ///
  /// Parámetros:
  /// - [profile]: Model con los nuevos datos del perfil
  ///
  /// Returns: [Profile] actualizado desde el servidor
  ///
  /// Throws:
  /// - [ValidationException] si los datos no cumplen reglas de negocio
  /// - [ApiException] si hay error HTTP
  Future<Profile> updateProfile(Profile profile) async {
    try {
      // 1. Validar reglas de negocio
      _validateProfile(profile);

      // 2. Transform Model → DTO
      final request = UserMapper.profileToUpdateRequest(profile);

      // 3. Call API
      _log('Actualizando perfil');
      final response = await _api.updateProfile(request);

      // 4. Transform DTO → Model
      final updated = UserMapper.profileToModel(response);

      // 5. Update cache
      _cache.set(_cacheKey, updated, ttl: _cacheTTL);

      _log('Perfil actualizado correctamente');
      return updated;
    } catch (e, stackTrace) {
      _log('Error actualizando perfil', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualiza parcialmente el perfil del usuario.
  ///
  /// Similar a [updateProfile] pero solo envía los campos que cambiaron.
  /// Útil para optimizar el payload del request.
  ///
  /// Parámetros:
  /// - [newProfile]: Model con los nuevos datos
  /// - [originalProfile]: Model con los datos originales para comparar
  ///
  /// Returns: [Profile] actualizado desde el servidor
  ///
  /// Throws:
  /// - [ValidationException] si los datos no cumplen reglas de negocio
  /// - [ApiException] si hay error HTTP
  Future<Profile> updateProfilePartial({
    required Profile newProfile,
    required Profile originalProfile,
  }) async {
    try {
      // 1. Validar reglas de negocio
      _validateProfile(newProfile);

      // 2. Transform Model → DTO (solo campos modificados)
      final request = UserMapper.profileToPartialUpdateRequest(
        newProfile,
        original: originalProfile,
      );

      // 3. Call API
      _log('Actualizando perfil parcialmente');
      final response = await _api.updateProfile(request);

      // 4. Transform DTO → Model
      final updated = UserMapper.profileToModel(response);

      // 5. Update cache
      _cache.set(_cacheKey, updated, ttl: _cacheTTL);

      _log('Perfil actualizado parcialmente');
      return updated;
    } catch (e, stackTrace) {
      _log('Error actualizando perfil parcialmente', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ========================================================================
  // VALIDACIONES DE NEGOCIO
  // ========================================================================

  /// Valida el perfil según reglas de negocio.
  ///
  /// Reglas:
  /// - Si hay teléfono, debe ser válido (10 dígitos, empieza con 09)
  /// - Nombres y apellidos no pueden tener caracteres especiales (opcional)
  ///
  /// Throws: [ValidationException] si hay errores
  void _validateProfile(Profile profile) {
    // Validar teléfono si está presente
    if (profile.phone != null &&
        profile.phone!.isNotEmpty &&
        !Validators.esCelularValido(profile.phone!)) {
      throw ValidationException(
        'Teléfono inválido. Debe tener 10 dígitos y empezar con 09',
      );
    }

    // Validar que nombre y apellido no estén vacíos si se proporcionan
    if (profile.firstName != null &&
        !Validators.noEstaVacio(profile.firstName)) {
      throw ValidationException('El nombre no puede estar vacío');
    }

    if (profile.lastName != null &&
        !Validators.noEstaVacio(profile.lastName)) {
      throw ValidationException('El apellido no puede estar vacío');
    }
  }

  // ========================================================================
  // CACHE MANAGEMENT
  // ========================================================================

  /// Limpia el cache del perfil.
  ///
  /// Útil cuando:
  /// - El usuario cierra sesión
  /// - Se quiere forzar una recarga
  void clearCache() {
    _cache.remove(_cacheKey);
    _log('Cache de perfil limpiado');
  }

  /// Verifica si hay un perfil en cache.
  bool get hasCachedProfile => _cache.contains(_cacheKey);
}

// ============================================================================
// EXCEPCIONES
// ============================================================================

/// Excepción lanzada cuando una validación de negocio falla.
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? fieldErrors;

  ValidationException(this.message, {this.fieldErrors});

  @override
  String toString() => 'ValidationException: $message';
}
