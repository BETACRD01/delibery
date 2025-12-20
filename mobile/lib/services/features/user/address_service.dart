// lib/services/features/user/address_service.dart

import 'dart:developer' as developer;
import '../../../apis/resources/users/addresses_api.dart';
import '../../../apis/mappers/user_mapper.dart';
import '../../../apis/helpers/api_exception.dart';
import '../../../models/user/address.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/validation/validators.dart';

/// Servicio de lógica de negocio para direcciones de usuario.
///
/// Responsabilidades:
/// - Gestionar CRUD de direcciones
/// - Validar duplicados
/// - Cache de lista de direcciones
/// - Manejo de dirección predeterminada
/// - Validaciones de negocio
class AddressService {
  final AddressesApi _api;
  final CacheManager _cache;

  // ========================================================================
  // SINGLETON MEJORADO CON DI OPCIONAL
  // ========================================================================

  static AddressService? _instance;

  factory AddressService({
    AddressesApi? api,
    CacheManager? cache,
  }) {
    return _instance ??= AddressService._(
      api: api ?? AddressesApi(),
      cache: cache ?? CacheManager.instance,
    );
  }

  AddressService._({
    required AddressesApi api,
    required CacheManager cache,
  })  : _api = api,
        _cache = cache;

  static void resetInstance() => _instance = null;

  // ========================================================================
  // CACHE CONFIGURATION
  // ========================================================================

  static const _addressesListKey = 'user_addresses_list';
  static const _defaultAddressKey = 'user_default_address';
  static const _addressCacheTTL = Duration(minutes: 5);

  void _log(String msg, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      msg,
      name: 'AddressService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ========================================================================
  // CASOS DE USO
  // ========================================================================

  /// Lista todas las direcciones del usuario.
  Future<List<Address>> listAddresses({bool forceRefresh = false}) async {
    try {
      // 1. Check cache
      if (!forceRefresh) {
        final cached = _cache.get<List<Address>>(_addressesListKey);
        if (cached != null) {
          _log('Retornando ${cached.length} direcciones desde cache');
          return cached;
        }
      }

      // 2. Fetch from API
      _log('Obteniendo direcciones desde API');
      final responses = await _api.listAddresses();

      // 3. Transform DTOs → Models
      final addresses = responses
          .map((dto) => UserMapper.addressToModel(dto))
          .toList();

      // 4. Update cache
      _cache.set(_addressesListKey, addresses, ttl: _addressCacheTTL);

      _log('${addresses.length} direcciones obtenidas y cacheadas');
      return addresses;
    } catch (e, stackTrace) {
      _log('Error listando direcciones', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene una dirección específica.
  Future<Address> getAddress(String id) async {
    try {
      _log('Obteniendo dirección $id');
      final response = await _api.getAddress(id);
      return UserMapper.addressToModel(response);
    } catch (e, stackTrace) {
      _log('Error obteniendo dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Crea una nueva dirección.
  ///
  /// Validaciones:
  /// - Verifica duplicados por etiqueta
  /// - Valida coordenadas
  /// - Valida campos requeridos
  Future<Address> createAddress(Address address) async {
    try {
      // 1. Validar reglas de negocio
      _validateAddress(address);

      // 2. Verificar duplicados
      await _checkDuplicateLabel(address.label);

      // 3. Transform Model → DTO
      final request = UserMapper.addressToCreateRequest(address);

      // 4. Call API
      _log('Creando dirección: ${address.label}');
      final response = await _api.createAddress(request);

      // 5. Transform DTO → Model
      final created = UserMapper.addressToModel(response);

      // 6. Invalidate cache
      _cache.removeByPattern('^user_.*address.*');

      _log('Dirección creada correctamente');
      return created;
    } on ApiException catch (e) {
      // Manejar error específico de duplicado del backend
      if (e.statusCode == 400 &&
          e.message.toLowerCase().contains('ya tienes una dirección')) {
        _log('Direccion duplicada detectada en backend');
        throw DuplicateAddressException('Ya existe una dirección con esa etiqueta');
      }
      rethrow;
    } catch (e, stackTrace) {
      _log('Error creando dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualiza una dirección existente.
  Future<Address> updateAddress(String id, Address address) async {
    try {
      // 1. Validar
      _validateAddress(address);

      // 2. Transform Model → DTO
      final request = UserMapper.addressToUpdateRequest(address);

      // 3. Call API
      _log('Actualizando dirección $id');
      final response = await _api.updateAddress(id, request);

      // 4. Transform DTO → Model
      final updated = UserMapper.addressToModel(response);

      // 5. Invalidate cache
      _cache.removeByPattern('^user_.*address.*');

      _log('Dirección actualizada correctamente');
      return updated;
    } catch (e, stackTrace) {
      _log('Error actualizando dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Elimina una dirección.
  Future<void> deleteAddress(String id) async {
    try {
      _log('Eliminando dirección $id');
      await _api.deleteAddress(id);

      // Invalidate cache
      _cache.removeByPattern('^user_.*address.*');

      _log('Dirección eliminada correctamente');
    } catch (e, stackTrace) {
      _log('Error eliminando dirección', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtiene la dirección predeterminada del usuario.
  Future<Address?> getDefaultAddress({bool forceRefresh = false}) async {
    try {
      // 1. Check cache
      if (!forceRefresh) {
        final cached = _cache.get<Address>(_defaultAddressKey);
        if (cached != null) {
          _log('Retornando dirección predeterminada desde cache');
          return cached;
        }
      }

      // 2. Fetch from API
      _log('Obteniendo dirección predeterminada');
      final response = await _api.getDefaultAddress();

      if (response == null) {
        _log('No hay dirección predeterminada');
        return null;
      }

      // 3. Transform DTO → Model
      final address = UserMapper.addressToModel(response);

      // 4. Update cache
      _cache.set(_defaultAddressKey, address, ttl: _addressCacheTTL);

      return address;
    } catch (e, stackTrace) {
      _log('Error obteniendo dirección predeterminada', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ========================================================================
  // VALIDACIONES DE NEGOCIO
  // ========================================================================

  void _validateAddress(Address address) {
    // Validar etiqueta
    if (!Validators.noEstaVacio(address.label)) {
      throw AddressValidationException('La etiqueta es requerida');
    }

    // Validar dirección/calle
    if (!Validators.noEstaVacio(address.street)) {
      throw AddressValidationException('La dirección es requerida');
    }

    // Validar coordenadas
    if (!address.hasValidCoordinates) {
      throw AddressValidationException(
        'Las coordenadas son inválidas (no pueden ser 0,0)',
      );
    }

    // Validar teléfono si está presente
    if (address.hasContactPhone &&
        !Validators.esCelularValido(address.contactPhone!)) {
      throw AddressValidationException(
        'El teléfono de contacto es inválido',
      );
    }
  }

  /// Verifica si ya existe una dirección con la misma etiqueta.
  Future<void> _checkDuplicateLabel(String label) async {
    final addresses = await listAddresses();

    final duplicate = addresses.any((a) =>
        a.label.toLowerCase() == label.toLowerCase());

    if (duplicate) {
      throw DuplicateAddressException(
        'Ya existe una dirección con la etiqueta "$label"',
      );
    }
  }

  // ========================================================================
  // CACHE MANAGEMENT
  // ========================================================================

  /// Limpia todo el cache relacionado con direcciones.
  void clearCache() {
    _cache.removeByPattern('^user_.*address.*');
    _log('Cache de direcciones limpiado');
  }
}

// ============================================================================
// EXCEPCIONES
// ============================================================================

class AddressValidationException implements Exception {
  final String message;

  AddressValidationException(this.message);

  @override
  String toString() => 'AddressValidationException: $message';
}

class DuplicateAddressException implements Exception {
  final String message;

  DuplicateAddressException(this.message);

  @override
  String toString() => 'DuplicateAddressException: $message';
}
