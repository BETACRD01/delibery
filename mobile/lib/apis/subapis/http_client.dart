// lib/apis/subapis/http_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../helpers/api_exception.dart';

// ============================================================================
// API CLIENT
// ============================================================================

class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  // --------------------------------------------------------------------------
  // Storage
  // --------------------------------------------------------------------------

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  static const _keyAccess = 'jp_access_token';
  static const _keyRefresh = 'jp_refresh_token';
  static const _keyExpiry = 'jp_token_expiry';
  static const _keyRole = 'jp_user_role';
  static const _keyUserId = 'jp_user_id';

  // --------------------------------------------------------------------------
  // State
  // --------------------------------------------------------------------------

  String? _accessToken;
  String? _refreshToken;
  String? _userRole;
  int? _userId;
  DateTime? _tokenExpiry;
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;
  bool _tokensLoaded = false;
  DateTime? _nextRefreshRetry;
  bool _refreshCooldownLogged = false;

  // --------------------------------------------------------------------------
  // Getters
  // --------------------------------------------------------------------------

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userRole => _userRole;
  int? get userId => _userId;
  DateTime? get tokenExpiry => _tokenExpiry;
  bool get tokensLoaded => _tokensLoaded;

  void _log(String msg, {Object? error}) =>
      developer.log(msg, name: 'ApiClient', error: error);

  // --------------------------------------------------------------------------
  // Token Management
  // --------------------------------------------------------------------------

  /// Actualiza solo el rol cacheado cuando la API no devuelve nuevos tokens.
  Future<void> cacheUserRole(String role) async {
    final normalized = role.toUpperCase();
    _userRole = normalized;

    try {
      await _storage.write(key: _keyRole, value: normalized);
      _log('Rol cacheado localmente: $normalized');
    } catch (e) {
      _log('Error cacheando rol', error: e);
    }
  }

  Future<void> saveTokens(
    String access,
    String refresh, {
    String? role,
    int? userId,
    Duration? lifetime,
  }) async {
    try {
      _accessToken = access;
      _refreshToken = refresh;
      _userRole = role;
      _userId = userId;
      _tokensLoaded = true;
      _tokenExpiry = DateTime.now().add(lifetime ?? const Duration(hours: 12));

      await Future.wait([
        _storage.write(key: _keyAccess, value: access),
        _storage.write(key: _keyRefresh, value: refresh),
        _storage.write(key: _keyExpiry, value: _tokenExpiry!.toIso8601String()),
        if (role != null) _storage.write(key: _keyRole, value: role),
        if (userId != null)
          _storage.write(key: _keyUserId, value: userId.toString()),
      ]);

      _log('Tokens guardados');
    } catch (e) {
      _log('Error guardando tokens', error: e);
      rethrow;
    }
  }

  Future<void> loadTokens() async {
    if (_tokensLoaded && _accessToken != null) {
      return;
    }

    try {
      _accessToken = await _storage.read(key: _keyAccess);
      _refreshToken = await _storage.read(key: _keyRefresh);
      _userRole = await _storage.read(key: _keyRole);

      final userIdStr = await _storage.read(key: _keyUserId);
      if (userIdStr != null) {
        _userId = int.tryParse(userIdStr);
      }

      final expiryStr = await _storage.read(key: _keyExpiry);
      if (expiryStr != null) {
        _tokenExpiry = DateTime.tryParse(expiryStr);
      }

      if (_accessToken != null) {
        _tokensLoaded = true;
        _log('Tokens cargados');
      }
    } catch (e) {
      _log('Error cargando tokens', error: e);
      _tokensLoaded = false;
      await clearTokens();
    }
  }

  Future<void> clearTokens() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _userRole = null;
      _userId = null;
      _tokenExpiry = null;
      _isRefreshing = false;
      _refreshCompleter = null;
      _tokensLoaded = false;

      await _storage.deleteAll();
      _log('Sesion limpiada');
    } catch (e) {
      _log('Error limpiando tokens', error: e);
    }
  }

  Future<bool> hasStoredTokens() async {
    try {
      return await _storage.containsKey(key: _keyAccess);
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Token Validation & Refresh
  // --------------------------------------------------------------------------

  bool _isTokenExpiring() {
    if (_tokenExpiry == null) {
      return true;
    }
    return DateTime.now().isAfter(
      _tokenExpiry!.subtract(const Duration(minutes: 5)),
    );
  }

  Future<bool> _ensureValidToken() async {
    if (_accessToken == null) {
      return false;
    }
    if (!_isTokenExpiring()) {
      return true;
    }

    if (_nextRefreshRetry != null &&
        DateTime.now().isBefore(_nextRefreshRetry!)) {
      if (!_refreshCooldownLogged) {
        _log('Refresh en cooldown');
        _refreshCooldownLogged = true;
      }
      return false;
    }
    _refreshCooldownLogged = false;

    _log('Token proximo a expirar, refrescando...');
    return await refreshAccessToken();
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      _log('No hay refresh token');
      return false;
    }

    if (_isRefreshing) {
      return await _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      _log('Solicitando nuevo token...');

      final response = await http
          .post(
            Uri.parse(ApiConfig.tokenRefresh),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': ApiConfig.apiKeyMobile,
            },
            body: json.encode({'refresh': _refreshToken}),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await saveTokens(
          data['access'],
          _refreshToken!,
          role: _userRole,
          userId: _userId,
        );
        _log('Token refrescado');
        _nextRefreshRetry = null;
        _refreshCooldownLogged = false;
        _refreshCompleter!.complete(true);
        return true;
      }

      if (response.statusCode == 401) {
        _log('Refresh token invalido');
        await clearTokens();
      }

      _refreshCompleter!.complete(false);
      return false;
    } on SocketException catch (e) {
      _log('Error de red refrescando', error: e);
      _nextRefreshRetry = DateTime.now().add(const Duration(seconds: 30));
      _refreshCompleter!.complete(false);
      return false;
    } on TimeoutException catch (e) {
      _log('Timeout refrescando', error: e);
      _nextRefreshRetry = DateTime.now().add(const Duration(seconds: 30));
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      _log('Error refrescando', error: e);
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // --------------------------------------------------------------------------
  // HTTP Methods
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> get(String endpoint) async {
    await _ensureValidToken();
    return _execute(
      () => http.get(Uri.parse(endpoint), headers: _headers),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    await _ensureValidToken();
    return _execute(
      () => http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: json.encode(data),
      ),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> postPublic(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': ApiConfig.apiKeyMobile,
    };
    return _execute(
      () => http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(data),
      ),
      endpoint,
      esPublico: true,
    );
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    await _ensureValidToken();
    return _execute(
      () => http.put(
        Uri.parse(endpoint),
        headers: _headers,
        body: json.encode(data),
      ),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    await _ensureValidToken();
    return _execute(
      () => http.patch(
        Uri.parse(endpoint),
        headers: _headers,
        body: json.encode(data),
      ),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    await _ensureValidToken();
    return _execute(
      () => http.delete(Uri.parse(endpoint), headers: _headers),
      endpoint,
    );
  }

  // --------------------------------------------------------------------------
  // Multipart
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> multipart(
    String method,
    String endpoint,
    Map<String, String> fields,
    Map<String, File> files,
  ) async {
    await _ensureValidToken();
    await _validateFiles(files);

    int attempt = 0;
    while (attempt < ApiConfig.maxRetries) {
      try {
        final request = http.MultipartRequest(method, Uri.parse(endpoint))
          ..headers.addAll(_multipartHeaders)
          ..fields.addAll(fields);

        for (final entry in files.entries) {
          final file = entry.value;
          final ext = file.path.split('.').last.toLowerCase();
          request.files.add(
            http.MultipartFile(
              entry.key,
              file.openRead(),
              await file.length(),
              filename: file.path.split('/').last,
              contentType: _contentType(ext),
            ),
          );
        }

        final streamedResponse = await request.send().timeout(
          ApiConfig.receiveTimeout * 3,
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 401 && _accessToken != null) {
          _log('Token expirado en multipart, refrescando...');
          if (await refreshAccessToken()) {
            attempt++;
            continue;
          }
          throw ApiException.sesionExpirada();
        }

        return _handleResponse(response);
      } on ApiException catch (e) {
        // No reintentar errores de validacion/permisos para preservar el mensaje del backend.
        if (!e.isRecoverable) {
          rethrow;
        }
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          rethrow;
        }
        final delaySeconds = e.retryAfter ?? 2;
        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (e) {
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: 'Error en subida tras $attempt intentos',
            errors: {'error': '$e'},
          );
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw ApiException(
      statusCode: 0,
      message: 'Error desconocido en multipart',
    );
  }

  // --------------------------------------------------------------------------
  // Core Execution
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> _execute(
    Future<http.Response> Function() requestFn,
    String endpoint, {
    bool esPublico = false,
  }) async {
    int attempt = 0;

    while (attempt < ApiConfig.maxRetries) {
      try {
        final response = await requestFn().timeout(
          esPublico ? ApiConfig.connectTimeout : ApiConfig.receiveTimeout,
        );

        if (response.statusCode == 401 && !esPublico && _accessToken != null) {
          _log('Token expirado (401), refrescando...');
          if (await refreshAccessToken()) {
            attempt++;
            continue;
          }
          throw ApiException.sesionExpirada();
        }

        return _handleResponse(response, esPublico: esPublico);
      } on SocketException {
        if (_tryEmulatorFallback(attempt)) {
          attempt++;
          continue;
        }
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: ApiConfig.errorNetwork,
            errors: {'conexion': 'Sin conexion'},
          );
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } on TimeoutException {
        if (_tryEmulatorFallback(attempt)) {
          attempt++;
          continue;
        }
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: ApiConfig.errorTimeout,
            errors: {'timeout': 'Operacion expiro'},
          );
        }
      }
    }
    throw ApiException(statusCode: 0, message: 'Error tras reintentos');
  }

  // --------------------------------------------------------------------------
  // Headers & Utilities
  // --------------------------------------------------------------------------

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': ApiConfig.apiKeyMobile,
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Map<String, String> get _multipartHeaders => {
    'X-API-Key': ApiConfig.apiKeyMobile,
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  bool _tryEmulatorFallback(int attempt) {
    if (!ApiConfig.enableEmulatorFallback) {
      return false;
    }
    if (attempt != 0 || !Platform.isAndroid || !ApiConfig.isEmulatorDevice) {
      return false;
    }
    if (ApiConfig.currentServerIp != ApiConfig.localBackendIp) {
      return false;
    }

    _log('Fallback a emulador host 10.0.2.2');
    ApiConfig.setManualIp(ApiConfig.emulatorHost);
    return true;
  }

  Future<void> _validateFiles(Map<String, File> files) async {
    for (final entry in files.entries) {
      final file = entry.value;
      if (!await file.exists()) {
        throw ApiException(
          statusCode: 400,
          message: 'Archivo no encontrado: ${file.path}',
          errors: {entry.key: 'No existe'},
        );
      }
      if ((await file.length()) > 10 * 1024 * 1024) {
        throw ApiException(
          statusCode: 400,
          message: 'Archivo excede 10MB',
          errors: {entry.key: 'Muy grande'},
        );
      }
    }
  }

  MediaType _contentType(String ext) => switch (ext) {
    'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
    'png' => MediaType('image', 'png'),
    'pdf' => MediaType('application', 'pdf'),
    _ => MediaType('application', 'octet-stream'),
  };

  // --------------------------------------------------------------------------
  // Response Handling
  // --------------------------------------------------------------------------

  Map<String, dynamic> _handleResponse(
    http.Response response, {
    bool esPublico = false,
  }) {
    final code = response.statusCode;

    if (code >= 200 && code < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is List) {
          return {'data': decoded, 'success': true};
        }
        return {'success': true, 'raw_data': decoded};
      } catch (_) {
        return {'success': true, 'raw_data': response.body};
      }
    }

    _log('Error HTTP $code: ${response.body}');

    Map<String, dynamic> errorBody = {};
    try {
      if (response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          errorBody = decoded;
        } else {
          errorBody = {'error': '$decoded'};
        }
      }
    } catch (_) {
      errorBody = {'error': response.body};
    }

    throw ApiException(
      statusCode: code,
      message: _extractError(errorBody, code, esPublico),
      errors: errorBody,
      contexto: esPublico ? 'publico' : 'autenticado',
    );
  }

  String _extractError(Map<String, dynamic> error, int code, bool esPublico) {
    if (code == 401) {
      return esPublico ? 'Credenciales invalidas' : 'Sesion expirada';
    }
    if (code == 403) {
      return 'Sin permisos';
    }
    if (code == 404) {
      return 'No encontrado';
    }
    if (code == 429) {
      return 'Demasiadas peticiones';
    }
    if (code >= 500) {
      return ApiConfig.errorServer;
    }

    for (final key in ['detail', 'message', 'error']) {
      if (error.containsKey(key)) {
        return error[key].toString();
      }
    }

    return 'Error ($code)';
  }
}
