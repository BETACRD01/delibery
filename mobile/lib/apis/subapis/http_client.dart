// lib/apis/subapis/http_client.dart

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../helpers/api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  // ---------------------------------------------------------------------------
  // VARIABLES Y ESTADO
  // ---------------------------------------------------------------------------

  String? _accessToken;
  String? _refreshToken;
  String? _userRole;
  int? _userId;
  DateTime? _tokenExpiry;
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;
  bool _tokensLoaded = false;
  DateTime? _nextRefreshRetryAllowed;
  bool _refreshCooldownLogged = false;

  static const String _keyAccessToken = 'jp_access_token';
  static const String _keyRefreshToken = 'jp_refresh_token';
  static const String _keyTokenTimestamp = 'jp_token_timestamp';
  static const String _keyTokenExpiry = 'jp_token_expiry';
  static const String _keyUserRole = 'jp_user_role';
  static const String _keyUserId = 'jp_user_id';

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userRole => _userRole;
  int? get userId => _userId;
  DateTime? get tokenExpiry => _tokenExpiry;
  bool get tokensLoaded => _tokensLoaded;

  void _log(String message, {Object? error}) {
    developer.log(message, name: 'ApiClient', error: error);
  }

  // ---------------------------------------------------------------------------
  // GESTION DE TOKENS
  // ---------------------------------------------------------------------------

  Future<void> saveTokens(
    String access,
    String refresh, {
    String? role,
    int? userId,
    Duration? tokenLifetime,
  }) async {
    try {
      _accessToken = access;
      _refreshToken = refresh;
      _userRole = role;
      _userId = userId;
      _tokensLoaded = true;

      final lifetime = tokenLifetime ?? const Duration(hours: 12);
      _tokenExpiry = DateTime.now().add(lifetime);

      await _secureStorage.write(key: _keyAccessToken, value: access);
      await _secureStorage.write(key: _keyRefreshToken, value: refresh);
      await _secureStorage.write(
        key: _keyTokenTimestamp,
        value: DateTime.now().toIso8601String(),
      );
      await _secureStorage.write(
        key: _keyTokenExpiry,
        value: _tokenExpiry!.toIso8601String(),
      );

      if (role != null) {
        await _secureStorage.write(key: _keyUserRole, value: role);
      }

      if (userId != null) {
        await _secureStorage.write(key: _keyUserId, value: userId.toString());
      }

      _log('Tokens guardados correctamente');
    } catch (e) {
      _log('Error guardando tokens', error: e);
      rethrow;
    }
  }

  Future<void> loadTokens() async {
    if (_tokensLoaded && _accessToken != null) return;

    try {
      _accessToken = await _secureStorage.read(key: _keyAccessToken);
      _refreshToken = await _secureStorage.read(key: _keyRefreshToken);
      _userRole = await _secureStorage.read(key: _keyUserRole);

      final userIdStr = await _secureStorage.read(key: _keyUserId);
      if (userIdStr != null) _userId = int.tryParse(userIdStr);

      final expiryStr = await _secureStorage.read(key: _keyTokenExpiry);
      if (expiryStr != null) _tokenExpiry = DateTime.tryParse(expiryStr);

      if (_accessToken != null) {
        _tokensLoaded = true;
        _log('Tokens cargados desde almacenamiento');
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

      await _secureStorage.deleteAll();
      _log('Sesion limpiada y tokens eliminados');
    } catch (e) {
      _log('Error limpiando tokens', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // VALIDACION Y REFRESCO
  // ---------------------------------------------------------------------------

  bool _isTokenExpiredOrExpiring() {
  if (_tokenExpiry == null) return true;
  const margin = Duration(minutes: 5);
  return DateTime.now().isAfter(_tokenExpiry!.subtract(margin));
}

  Future<bool> _ensureValidToken() async {
    if (_accessToken == null) return false;
    if (!_isTokenExpiredOrExpiring()) return true;

    // Si hubo un fallo reciente de red refrescando, evitamos spamear el endpoint
    if (_nextRefreshRetryAllowed != null &&
        DateTime.now().isBefore(_nextRefreshRetryAllowed!)) {
      if (!_refreshCooldownLogged) {
        _log('Refresh token en cooldown por fallo de red; reintento posterior');
        _refreshCooldownLogged = true;
      }
      return false;
    }
    _refreshCooldownLogged = false;

    _log('Token proximo a expirar, iniciando refresco automatico');
    return await refreshAccessToken();
  }

  Future<bool> hasStoredTokens() async {
    try {
      return await _secureStorage.containsKey(key: _keyAccessToken);
    } catch (e) {
      return false;
    }
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      _log('No hay refresh token disponible');
      return false;
    }

    if (_isRefreshing) {
      return await _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      _log('Solicitando nuevo access token...');

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
          tokenLifetime: const Duration(hours: 12),
        );

        _log('Token refrescado exitosamente');
        _nextRefreshRetryAllowed = null;
        _refreshCooldownLogged = false;
        _refreshCompleter!.complete(true);
        return true;
      }

      if (response.statusCode == 401) {
        _log('Refresh token invalido o expirado');
        await clearTokens();
      }

      _refreshCompleter!.complete(false);
      return false;
    } on SocketException catch (e) {
      _log('Error de red al refrescar token', error: e);
      _nextRefreshRetryAllowed = DateTime.now().add(const Duration(seconds: 30));
      _refreshCooldownLogged = false;
      _refreshCompleter!.complete(false);
      return false;
    } on TimeoutException catch (e) {
      _log('Timeout refrescando token', error: e);
      _nextRefreshRetryAllowed = DateTime.now().add(const Duration(seconds: 30));
      _refreshCooldownLogged = false;
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      _log('Error de red al refrescar token', error: e);
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // ---------------------------------------------------------------------------
  // METODOS HTTP PUBLICOS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> get(String endpoint) async {
    await _ensureValidToken();
    _log('GET: $endpoint');

    return _executeRequest(
      () => http.get(Uri.parse(endpoint), headers: _getHeaders()),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    await _ensureValidToken();
    _log('POST: $endpoint');

    return _executeRequest(
      () => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(),
        body: json.encode(data),
      ),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> postPublic(String endpoint, Map<String, dynamic> data) async {
    _log('POST (Publico): $endpoint');

    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': ApiConfig.apiKeyMobile,
    };

    return _executeRequest(
      () => http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(data),
      ),
      endpoint,
      esPublico: true,
    );
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    await _ensureValidToken();
    _log('PUT: $endpoint');

    return _executeRequest(
      () => http.put(
        Uri.parse(endpoint),
        headers: _getHeaders(),
        body: json.encode(data),
      ),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    await _ensureValidToken();
    _log('PATCH: $endpoint');

    return _executeRequest(
      () => http.patch(
        Uri.parse(endpoint),
        headers: _getHeaders(),
        body: json.encode(data),
      ),
      endpoint,
    );
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    await _ensureValidToken();
    _log('DELETE: $endpoint');

    return _executeRequest(
      () => http.delete(Uri.parse(endpoint), headers: _getHeaders()),
      endpoint,
    );
  }

  // ---------------------------------------------------------------------------
  // MULTIPART REQUESTS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> multipart(
    String method,
    String endpoint,
    Map<String, String> fields,
    Map<String, File> files,
  ) async {
    await _ensureValidToken();
    _log('$method (Multipart): $endpoint');

    await _validarArchivosMultipart(files);

    // Lógica de reintento específica para multipart
    int attempt = 0;
    while (attempt < ApiConfig.maxRetries) {
      try {
        final uri = Uri.parse(endpoint);
        final request = http.MultipartRequest(method, uri);

        request.headers.addAll(_getMultipartHeaders());
        request.fields.addAll(fields);

        for (final entry in files.entries) {
          final file = entry.value;
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final extension = file.path.split('.').last.toLowerCase();

          request.files.add(
            http.MultipartFile(
              entry.key,
              stream,
              length,
              filename: file.path.split('/').last,
              contentType: _getContentType(extension),
            ),
          );
        }

        final streamedResponse = await request.send().timeout(
          ApiConfig.receiveTimeout * 3, // Mayor timeout para archivos
        );

        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 401 && _accessToken != null) {
          _log('Token expirado en subida de archivo, refrescando...');
          if (await refreshAccessToken()) {
            attempt++;
            continue; // Reintentar con nuevo token
          }
          throw ApiException.sesionExpirada();
        }

        return _handleResponse(response);

      } on Exception catch (e) {
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: 'Error en subida de archivos tras varios intentos',
            errors: {'error': e.toString()},
            stackTrace: StackTrace.current,
          );
        }
        await Future.delayed( const Duration(seconds: 2));
      }
    }
    throw ApiException(statusCode: 0, message: 'Error desconocido en multipart');
  }

  // ---------------------------------------------------------------------------
  // LOGICA INTERNA DE REQUEST
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _executeRequest(
    Future<http.Response> Function() requestFn,
    String endpoint, {
    bool esPublico = false,
  }) async {
    int attempt = 0;
    const maxRetries = 3;

    while (attempt < maxRetries) {
      try {
        final response = await requestFn().timeout(
          esPublico ? ApiConfig.connectTimeout : ApiConfig.receiveTimeout,
        );

        // Manejo de 401 Autenticado (Token Expirado)
        if (response.statusCode == 401 && !esPublico && _accessToken != null) {
          _log('Token expirado (401), intentando refrescar...');
          final refreshed = await refreshAccessToken();
          
          if (refreshed) {
            attempt++;
            continue; // Reintentar el ciclo con el nuevo token
          } else {
            throw ApiException.sesionExpirada();
          }
        }

        return _handleResponse(response, esPublico: esPublico);

      } on SocketException {
        if (_tryEmulatorFallback(attempt)) {
          attempt++;
          continue;
        }

        attempt++;
        if (attempt >= maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: ApiConfig.errorNetwork,
            errors: {'conexion': 'Sin conexion a internet'},
            stackTrace: StackTrace.current,
          );
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        
      } on TimeoutException {
        if (_tryEmulatorFallback(attempt)) {
          attempt++;
          continue;
        }

        attempt++;
        if (attempt >= maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: ApiConfig.errorTimeout,
            errors: {'timeout': 'La operacion expiro'},
            stackTrace: StackTrace.current,
          );
        }
      }
    }
    throw ApiException(statusCode: 0, message: 'Error desconocido tras reintentos');
  }

  // ---------------------------------------------------------------------------
  // HEADERS Y UTILIDADES
  // ---------------------------------------------------------------------------

  bool _tryEmulatorFallback(int attempt) {
    // Fallback al host del emulador solo si se habilita explícitamente con --dart-define=ENABLE_EMULATOR_FALLBACK=true
    if (!ApiConfig.enableEmulatorFallback) return false;

    final currentIp = ApiConfig.currentServerIp;
    final isLocalIp = currentIp == ApiConfig.localBackendIp;
    if (attempt == 0 && Platform.isAndroid && ApiConfig.isEmulatorDevice && isLocalIp) {
      _log('Fallo de red en Android con IP local; cambiando a host 10.0.2.2 y reintentando');
      ApiConfig.setManualIp(ApiConfig.emulatorHost);
      return true;
    }
    return false;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': ApiConfig.apiKeyMobile,
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Map<String, String> _getMultipartHeaders() {
    final headers = {
      'X-API-Key': ApiConfig.apiKeyMobile,
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<void> _validarArchivosMultipart(Map<String, File> files) async {
    for (final entry in files.entries) {
      final file = entry.value;
      if (!await file.exists()) {
        throw ApiException(
          statusCode: 400,
          message: 'Archivo no encontrado: ${file.path}',
          errors: {entry.key: 'El archivo no existe en el dispositivo'},
          stackTrace: StackTrace.current,
        );
      }
      
      // Limite de 10MB
      if ((await file.length()) > 10 * 1024 * 1024) {
        throw ApiException(
          statusCode: 400,
          message: 'El archivo excede el limite de 10MB',
          errors: {entry.key: 'Archivo demasiado grande'},
          stackTrace: StackTrace.current,
        );
      }
    }
  }

  MediaType _getContentType(String extension) {
    switch (extension) {
      case 'jpg': case 'jpeg': return MediaType('image', 'jpeg');
      case 'png': return MediaType('image', 'png');
      case 'pdf': return MediaType('application', 'pdf');
      default: return MediaType('application', 'octet-stream');
    }
  }

  // ---------------------------------------------------------------------------
  // MANEJO DE RESPUESTA
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _handleResponse(http.Response response, {bool esPublico = false}) {
    final code = response.statusCode;

    // Exito (200-299)
    if (code >= 200 && code < 300) {
      if (response.body.isEmpty) return {'success': true};
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'data': decoded, 'success': true};
        return {'success': true, 'raw_data': decoded};
      } catch (e) {
        return {'success': true, 'raw_data': response.body};
      }
    }

    // Error
    _log('Error HTTP $code: ${response.body}');
    
    Map<String, dynamic> errorBody = {};
    try {
      if (response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          errorBody = decoded;
        } else if (decoded is List) {
          errorBody = {
            'errors': decoded,
            'error': decoded.toString(),
          };
        } else {
          errorBody = {'error': decoded.toString()};
        }
      }
    } catch (_) {
      errorBody = {'error': response.body};
    }

    throw ApiException(
      statusCode: code,
      message: _extractErrorMessage(errorBody, code, esPublico),
      errors: errorBody,
      stackTrace: StackTrace.current,
      contexto: esPublico ? 'publico' : 'autenticado',
    );
  }

  String _extractErrorMessage(Map<String, dynamic> error, int code, bool esPublico) {
    if (code == 401) {
      return esPublico 
          ? 'Credenciales invalidas' 
          : 'Tu sesion ha expirado';
    }
    if (code == 403) return 'No tienes permisos para esta accion';
    if (code == 404) return 'Recurso no encontrado';
    if (code == 429) return 'Demasiadas peticiones, intenta mas tarde';
    if (code >= 500) return ApiConfig.errorServer;

    // Mensajes especificos del backend
    if (error.containsKey('detail')) return error['detail'].toString();
    if (error.containsKey('message')) return error['message'].toString();
    if (error.containsKey('error')) return error['error'].toString();

    return 'Error desconocido ($code)';
  }
}
