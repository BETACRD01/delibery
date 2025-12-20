// lib/apis/client/base_api.dart

import 'dart:developer' as developer;
import '../subapis/http_client.dart';

/// Clase base para todas las APIs.
///
/// Proporciona:
/// - Acceso al [ApiClient] compartido
/// - Logging estructurado con el nombre de la clase
/// - Patrón base para implementar APIs específicas
///
/// Ejemplo de uso:
/// ```dart
/// class ProfileApi extends BaseApi {
///   ProfileApi(super.client);
///
///   Future<ProfileResponse> getProfile() async {
///     log('GET: Obtener perfil');
///     final response = await client.get(endpoint);
///     return ProfileResponse.fromJson(response);
///   }
/// }
/// ```
abstract class BaseApi {
  final ApiClient client;

  BaseApi(this.client);

  /// Registra un mensaje de log con el nombre de la clase concreta.
  ///
  /// El nombre de la clase se obtiene automáticamente via [runtimeType],
  /// por lo que los logs mostrarán "ProfileApi", "AddressesApi", etc.
  void log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
