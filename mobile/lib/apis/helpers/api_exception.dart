// lib/apis/helpers/api_exception.dart

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic> errors;
  final Map<String, dynamic>? details;
  final StackTrace? stackTrace;
  final String? contexto;

  ApiException({
    required this.statusCode,
    required this.message,
    Map<String, dynamic>? errors,
    this.details,
    this.stackTrace,
    this.contexto,
  }) : errors = errors ?? {};

  // --------------------------------------------------------------------------
  // Factories
  // --------------------------------------------------------------------------

  factory ApiException.loginFallido({
    String? mensaje,
    Map<String, dynamic>? errors,
  }) => ApiException(
    statusCode: 401,
    message: mensaje ?? 'Email o contrasena incorrectos',
    errors: errors ?? {},
    contexto: 'login',
  );

  factory ApiException.sesionExpirada({String? mensaje}) => ApiException(
    statusCode: 401,
    message: mensaje ?? 'Tu sesion ha expirado. Inicia sesion nuevamente',
    errors: {},
    contexto: 'sesion_expirada',
  );

  factory ApiException.red({String? mensaje}) => ApiException(
    statusCode: 0,
    message: mensaje ?? 'Sin conexion a internet',
    contexto: 'red',
  );

  factory ApiException.timeout({String? mensaje}) => ApiException(
    statusCode: 0,
    message: mensaje ?? 'La operacion tardo demasiado',
    contexto: 'timeout',
  );

  // --------------------------------------------------------------------------
  // Getters de Estado
  // --------------------------------------------------------------------------

  bool get isAuthError => statusCode == 401;
  bool get esLoginFallido => contexto == 'login' && statusCode == 401;
  bool get esSesionExpirada =>
      contexto == 'sesion_expirada' && statusCode == 401;
  bool get isNetworkError => statusCode == 0;
  bool get isServerError => statusCode >= 500;
  bool get isRateLimitError => statusCode == 429;
  bool get isValidationError => statusCode == 400;
  bool get isForbiddenError => statusCode == 403;
  bool get isNotFoundError => statusCode == 404;

  bool get isCuentaBloqueada =>
      details?['bloqueado'] == true || errors['bloqueado'] == true;
  bool get isRecoverable =>
      isNetworkError ||
      isRateLimitError ||
      statusCode == 503 ||
      statusCode == 504;

  int? get intentosRestantes => details?['intentos_restantes'];
  int? get retryAfter => details?['retry_after'];
  String? get tipoRateLimit => details?['tipo'];
  String? get bloqueadoHasta => details?['bloqueado_hasta'];

  // --------------------------------------------------------------------------
  // Mensajes Amigables
  // --------------------------------------------------------------------------

  String getUserFriendlyMessage() {
    if (isNetworkError) {
      return 'Sin conexion a internet. Verifique su red.';
    }
    if (isServerError) {
      return 'Error del servidor. Intente mas tarde.';
    }
    if (isRateLimitError) {
      return retryAfter != null
          ? 'Demasiados intentos. Espera ${_formatSeconds(retryAfter!)}.'
          : 'Demasiados intentos. Intente mas tarde.';
    }
    if (isCuentaBloqueada) {
      return bloqueadoHasta != null
          ? 'Tu cuenta esta bloqueada hasta $bloqueadoHasta'
          : 'Tu cuenta ha sido bloqueada temporalmente.';
    }
    if (esLoginFallido) {
      return 'Credenciales incorrectas. Verifica tus datos';
    }
    if (esSesionExpirada) {
      return 'Tu sesion ha expirado. Inicia sesion nuevamente';
    }

    if (errors.isNotEmpty) {
      return _extractErrorMessage();
    }

    return message.isNotEmpty ? message : 'Ocurrio un error inesperado.';
  }

  String _extractErrorMessage() {
    if (errors.containsKey('detail')) {
      return errors['detail'].toString();
    }

    if (errors.containsKey('non_field_errors')) {
      final list = errors['non_field_errors'];
      if (list is List && list.isNotEmpty) {
        return list.first.toString();
      }
      return list.toString();
    }

    final firstKey = errors.keys.first;
    final firstVal = errors[firstKey];

    final errorMsg = (firstVal is List && firstVal.isNotEmpty)
        ? firstVal.first.toString()
        : firstVal.toString();

    final fieldName =
        firstKey[0].toUpperCase() + firstKey.substring(1).replaceAll('_', ' ');
    return '$fieldName: $errorMsg';
  }

  String _formatSeconds(int segundos) {
    if (segundos < 60) {
      return '$segundos segundos';
    }
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    return sec == 0 ? '$min minutos' : '$min minutos y $sec segundos';
  }

  // --------------------------------------------------------------------------
  // Utilidades de Errores
  // --------------------------------------------------------------------------

  String? getFieldError(String fieldName) {
    if (!errors.containsKey(fieldName)) {
      return null;
    }
    final error = errors[fieldName];
    if (error is List && error.isNotEmpty) {
      return error[0].toString();
    }
    if (error is String) {
      return error;
    }
    return null;
  }

  List<String> getAllFieldErrors() {
    final result = <String>[];
    for (final entry in errors.entries) {
      if (entry.key == 'non_field_errors') {
        continue;
      }
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        result.add('${entry.key}: ${value[0]}');
      } else if (value is String) {
        result.add('${entry.key}: $value');
      }
    }
    return result;
  }

  // --------------------------------------------------------------------------
  // Serializacion
  // --------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'message': message,
    'errors': errors,
    'details': details,
    'contexto': contexto,
    'timestamp': DateTime.now().toIso8601String(),
  };

  @override
  String toString() {
    final parts = ['ApiException: $message', 'Status: $statusCode'];
    if (contexto != null) {
      parts.add('Contexto: $contexto');
    }
    if (errors.isNotEmpty) {
      parts.add('Errors: $errors');
    }
    return parts.join(' | ');
  }

  // --------------------------------------------------------------------------
  // Copy
  // --------------------------------------------------------------------------

  ApiException copyWith({
    int? statusCode,
    String? message,
    Map<String, dynamic>? errors,
    Map<String, dynamic>? details,
    StackTrace? stackTrace,
    String? contexto,
  }) => ApiException(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    errors: errors ?? this.errors,
    details: details ?? this.details,
    stackTrace: stackTrace ?? this.stackTrace,
    contexto: contexto ?? this.contexto,
  );
}
