// lib/apis/subapis/http_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/api_config.dart';
import '../helpers/api_exception.dart';

// ============================================================================
// API CLIENT (OPTIMIZADO PARA NGROK/PRODUCCIÓN)
// ============================================================================

class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  // --------------------------------------------------------------------------
  // Storage (Almacenamiento Seguro)
  // --------------------------------------------------------------------------

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyAccess = 'jp_access_token';
  static const _keyRefresh = 'jp_refresh_token';
  static const _keyExpiry = 'jp_token_expiry';
  static const _keyRole = 'jp_user_role';
  static const _keyUserId = 'jp_user_id';

  // --------------------------------------------------------------------------
  // State (Estado en Memoria)
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

  // --------------------------------------------------------------------------
  // Getters Públicos
  // --------------------------------------------------------------------------

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userRole => _userRole;
  int? get userId => _userId;
  bool get tokensLoaded => _tokensLoaded;

  void _log(String msg, {Object? error}) =>
      developer.log(msg, name: 'ApiClient', error: error);

  // --------------------------------------------------------------------------
  // Gestión de Tokens (Guardar / Cargar / Borrar)
  // --------------------------------------------------------------------------

  Future<void> cacheUserRole(String role) async {
    final normalized = role.toUpperCase();
    _userRole = normalized;
    try {
      await _storage.write(key: _keyRole, value: normalized);
    } catch (e) {
      _log('Error cacheando rol', error: e);
    }
  }

  Future<void> saveTokens(
    String access,
    String refresh, {
    String? role,
    int? userId,
  }) async {
    try {
      _accessToken = access;
      _refreshToken = refresh;
      _userRole = role;
      _userId = userId;
      _tokensLoaded = true;
      // Asumimos validez de 12 horas si no se especifica
      _tokenExpiry = DateTime.now().add(const Duration(hours: 12));

      await Future.wait([
        _storage.write(key: _keyAccess, value: access),
        _storage.write(key: _keyRefresh, value: refresh),
        _storage.write(key: _keyExpiry, value: _tokenExpiry!.toIso8601String()),
        if (role != null) _storage.write(key: _keyRole, value: role),
        if (userId != null)
          _storage.write(key: _keyUserId, value: userId.toString()),
      ]);

      _log('Tokens guardados correctamente');
    } catch (e) {
      _log('Error guardando tokens', error: e);
      rethrow;
    }
  }

  Future<void> loadTokens() async {
    if (_tokensLoaded && _accessToken != null) return;

    try {
      _accessToken = await _storage.read(key: _keyAccess);
      _refreshToken = await _storage.read(key: _keyRefresh);
      _userRole = await _storage.read(key: _keyRole);

      final uid = await _storage.read(key: _keyUserId);
      if (uid != null) _userId = int.tryParse(uid);

      final expiry = await _storage.read(key: _keyExpiry);
      if (expiry != null) _tokenExpiry = DateTime.tryParse(expiry);

      if (_accessToken != null) {
        _tokensLoaded = true;
        _log('Sesión restaurada');
      }
    } catch (e) {
      _log('Error cargando tokens', error: e);
      await clearTokens();
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _userRole = null;
    _userId = null;
    _tokenExpiry = null;
    _tokensLoaded = false;
    try {
      await _storage.deleteAll();
      _log('Sesión cerrada y limpiada');
    } catch (e) {
      _log('Error limpiando storage', error: e);
    }
  }

  // --------------------------------------------------------------------------
  // Validación y Refresh Automático
  // --------------------------------------------------------------------------

  bool _isTokenExpiring() {
    if (_tokenExpiry == null) return true;
    // Consideramos expirado 5 minutos antes para prevenir fallos en vuelo
    return DateTime.now().isAfter(
      _tokenExpiry!.subtract(const Duration(minutes: 5)),
    );
  }

  Future<bool> _ensureValidToken() async {
    if (_accessToken == null) return false;

    if (!_isTokenExpiring()) return true;

    // Evitar loops infinitos de refresh si falla mucho
    if (_nextRefreshRetry != null &&
        DateTime.now().isBefore(_nextRefreshRetry!)) {
      return false;
    }

    _log('Token por expirar, intentando refresh...');
    return await refreshAccessToken();
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    // Si ya hay un refresh en proceso, esperar a que termine
    if (_isRefreshing) return await _refreshCompleter!.future;

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
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
          _refreshToken!, // Mantenemos el refresh actual si no viene uno nuevo
          role: _userRole,
          userId: _userId,
        );
        _refreshCompleter!.complete(true);
        _nextRefreshRetry = null;
        return true;
      } else {
        _log('Refresh fallido: ${response.statusCode}');
        await clearTokens(); // Si falla el refresh, forzamos logout
        _refreshCompleter!.complete(false);
        return false;
      }
    } catch (e) {
      _log('Error en refresh', error: e);
      _nextRefreshRetry = DateTime.now().add(const Duration(seconds: 30));
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // --------------------------------------------------------------------------
  // Métodos HTTP Públicos (GET, POST, PUT, PATCH, DELETE)
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> get(String endpoint) async {
    await _ensureValidToken();
    return _execute(() => http.get(Uri.parse(endpoint), headers: _headers));
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
    );
  }

  Future<Map<String, dynamic>> postPublic(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    // No validamos token aquí porque es público (Login, Registro)
    return _execute(
      () => http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': ApiConfig.apiKeyMobile,
        },
        body: json.encode(data),
      ),
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
    );
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    await _ensureValidToken();
    return _execute(() => http.delete(Uri.parse(endpoint), headers: _headers));
  }

  // --------------------------------------------------------------------------
  // Subida de Archivos (Multipart)
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
        final request = http.MultipartRequest(method, Uri.parse(endpoint));
        request.headers.addAll(_multipartHeaders);
        request.fields.addAll(fields);

        for (final entry in files.entries) {
          final file = entry.value;
          final ext = file.path.split('.').last.toLowerCase();
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              file.path,
              contentType: _contentType(ext),
            ),
          );
        }

        final streamedResponse = await request.send().timeout(
          ApiConfig.sendTimeout,
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 401 && _accessToken != null) {
          if (await refreshAccessToken()) {
            attempt++;
            continue; // Reintentar con nuevo token
          }
          throw ApiException.sesionExpirada();
        }

        return _handleResponse(response);
      } catch (e) {
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: 'Error subiendo archivos tras $attempt intentos',
            errors: {'error': e.toString()},
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
  // Ejecución Central (_execute)
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> _execute(
    Future<http.Response> Function() requestFn, {
    bool esPublico = false,
  }) async {
    int attempt = 0;

    // Bucle de reintentos
    while (attempt < ApiConfig.maxRetries) {
      try {
        final response = await requestFn().timeout(ApiConfig.connectTimeout);

        // Manejo automático de Token Expirado (401)
        if (response.statusCode == 401 && !esPublico && _accessToken != null) {
          _log('Token 401 detectado, intentando refresh...');
          if (await refreshAccessToken()) {
            attempt++;
            continue; // Reintentamos la petición original con el nuevo token
          }
          throw ApiException.sesionExpirada();
        }

        return _handleResponse(response, esPublico: esPublico);
      } on SocketException catch (_) {
        // Error de conexión puro (sin internet / ngrok caído)
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: ApiConfig.errorNetwork,
            errors: {'conexion': 'No se pudo conectar al servidor'},
          );
        }
        await Future.delayed(const Duration(seconds: 1));
      } on TimeoutException catch (_) {
        // Timeout
        attempt++;
        if (attempt >= ApiConfig.maxRetries) {
          throw ApiException(
            statusCode: 0,
            message: ApiConfig.errorTimeout,
            errors: {'timeout': 'La petición tardó demasiado'},
          );
        }
      } catch (e) {
        if (e is ApiException) {
          rethrow; // Si ya es una excepción procesada, la pasamos
        }
        throw ApiException(
          statusCode: 0,
          message: ApiConfig.errorUnknown,
          errors: {'error': e.toString()},
        );
      }
    }
    throw ApiException(statusCode: 0, message: 'Error tras reintentos');
  }

  // --------------------------------------------------------------------------
  // Headers y Utilidades Privadas
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

  Future<void> _validateFiles(Map<String, File> files) async {
    for (final entry in files.entries) {
      final file = entry.value;
      if (!await file.exists()) {
        throw ApiException(
          statusCode: 400,
          message: 'Archivo no encontrado: ${entry.key}',
        );
      }
      // Límite de 10MB
      if ((await file.length()) > 10 * 1024 * 1024) {
        throw ApiException(
          statusCode: 400,
          message: 'El archivo ${entry.key} es muy grande (Max 10MB)',
        );
      }
    }
  }

  MediaType _contentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // --------------------------------------------------------------------------
  // Procesamiento de Respuesta (JSON Parsing)
  // --------------------------------------------------------------------------

  Map<String, dynamic> _handleResponse(
    http.Response response, {
    bool esPublico = false,
  }) {
    final code = response.statusCode;

    // ÉXITO (200-299)
    if (code >= 200 && code < 300) {
      if (response.body.isEmpty) return {'success': true};
      try {
        final decoded = json.decode(
          utf8.decode(response.bodyBytes),
        ); // utf8 decode para tildes
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'data': decoded, 'success': true};
        return {'success': true, 'raw_data': decoded};
      } catch (_) {
        return {'success': true, 'raw_data': response.body};
      }
    }

    // ERROR
    _log('Error HTTP $code: ${response.body}');

    Map<String, dynamic> errorBody = {};
    String mensajeError = 'Error desconocido';

    try {
      if (response.body.isNotEmpty) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          errorBody = decoded;
          // Intentamos extraer el mensaje más legible posible
          if (decoded.containsKey('detail')) {
            mensajeError = decoded['detail'];
          } else if (decoded.containsKey('message')) {
            mensajeError = decoded['message'];
          } else if (decoded.containsKey('error')) {
            mensajeError = decoded['error'];
          }
        }
      }
    } catch (_) {
      mensajeError = response.body; // Si no es JSON, devolvemos el texto plano
    }

    // Mensajes amigables para errores comunes
    if (code == 401) {
      mensajeError = esPublico ? 'Credenciales incorrectas' : 'Sesión expirada';
    }
    if (code == 403) {
      mensajeError = 'No tienes permiso para realizar esta acción';
    }
    if (code == 404) {
      mensajeError = 'Recurso no encontrado';
    }
    if (code == 500) {
      mensajeError = ApiConfig.errorServer;
    }

    throw ApiException(
      statusCode: code,
      message: mensajeError,
      errors: errorBody,
    );
  }
}
