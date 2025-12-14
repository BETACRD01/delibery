// lib/apis/helpers/api_exception.dart

/// Excepcion personalizada para el manejo estandarizado de errores de API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic> errors;
  final Map<String, dynamic>? details;
  final StackTrace? stackTrace;
  
  // Contexto para diferenciar errores con mismo status code (ej: 401)
  final String? contexto;

  ApiException({
    required this.statusCode,
    required this.message,
    Map<String, dynamic>? errors,
    this.details,
    this.stackTrace,
    this.contexto,
  }) : errors = errors ?? {};

  // ---------------------------------------------------------------------------
  // FACTORIES (Constructores predefinidos)
  // ---------------------------------------------------------------------------

  // Factory para errores de login (401)
  factory ApiException.loginFallido({
    String? mensaje,
    Map<String, dynamic>? errors,
  }) {
    return ApiException(
      statusCode: 401,
      message: mensaje ?? 'Email o contraseña incorrectos',
      errors: errors ?? {},
      contexto: 'login',
    );
  }

  // Factory para sesion expirada (401)
  factory ApiException.sesionExpirada({String? mensaje}) {
    return ApiException(
      statusCode: 401,
      message: mensaje ?? 'Tu sesion ha expirado. Inicia sesion nuevamente',
      errors: {},
      contexto: 'sesion_expirada',
    );
  }

  // ---------------------------------------------------------------------------
  // MÉTODOS BASE
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ApiException: $message');
    buffer.writeln('Status Code: $statusCode');

    if (contexto != null) buffer.writeln('Context: $contexto');
    if (errors.isNotEmpty) buffer.writeln('Errors: $errors');
    if (details != null && details!.isNotEmpty) buffer.writeln('Details: $details');
    
    if (stackTrace != null) {
      buffer.writeln('\nStack Trace:');
      buffer.writeln(stackTrace.toString());
    }

    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'errors': errors,
      'details': details,
      'contexto': contexto,
      'stackTrace': stackTrace?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // GETTERS DE ESTADO
  // ---------------------------------------------------------------------------

  bool get isAuthError => statusCode == 401;
  bool get esLoginFallido => contexto == 'login' && statusCode == 401;
  bool get esSesionExpirada => contexto == 'sesion_expirada' && statusCode == 401;
  
  bool get isNetworkError => statusCode == 0;
  bool get isServerError => statusCode >= 500;
  bool get isRateLimitError => statusCode == 429;
  
  bool get isValidationError => statusCode == 400;
  bool get isForbiddenError => statusCode == 403;
  bool get isNotFoundError => statusCode == 404;

  bool get isCuentaBloqueada =>
      details?['bloqueado'] == true || errors['bloqueado'] == true;

  // Detalles especificos
  int? get intentosRestantes => details?['intentos_restantes'];
  int? get retryAfter => details?['retry_after'];
  String? get tipoRateLimit => details?['tipo'];
  String? get mensajeAdvertencia => details?['mensaje_advertencia'];
  String? get bloqueadoHasta => details?['bloqueado_hasta'];

  // ---------------------------------------------------------------------------
  // UTILIDADES DE ERRORES
  // ---------------------------------------------------------------------------

  String? getFieldError(String fieldName) {
    if (errors.containsKey(fieldName)) {
      final error = errors[fieldName];
      if (error is List && error.isNotEmpty) return error[0].toString();
      if (error is String) return error;
    }
    return null;
  }

  List<String> getAllFieldErrors() {
    final fieldErrors = <String>[];
    errors.forEach((key, value) {
      if (key == 'non_field_errors') return;
      if (value is List && value.isNotEmpty) {
        fieldErrors.add('$key: ${value[0]}');
      } else if (value is String) {
        fieldErrors.add('$key: $value');
      }
    });
    return fieldErrors;
  }

  /// ✅ MÉTODO OPTIMIZADO: Convierte errores técnicos en mensajes amigables
  /// Lee la estructura de errores de Django Rest Framework
  String getUserFriendlyMessage() {
    // 1. Errores de infraestructura
    if (isNetworkError) return 'Sin conexion a internet. Verifique su red.';
    if (isServerError) return 'Error del servidor. Intente mas tarde.';

    if (isRateLimitError) {
      if (retryAfter != null) {
        return 'Demasiados intentos. Espera ${_formatSeconds(retryAfter!)}.';
      }
      return 'Demasiados intentos. Intente mas tarde.';
    }

    // 2. Errores de cuenta
    if (isCuentaBloqueada) {
      if (bloqueadoHasta != null) {
        return 'Tu cuenta esta bloqueada hasta $bloqueadoHasta';
      }
      return 'Tu cuenta ha sido bloqueada temporalmente.';
    }

    if (esLoginFallido) return 'Credenciales incorrectas. Verifica tus datos';
    if (esSesionExpirada) return 'Tu sesion ha expirado. Inicia sesion nuevamente';

    // 3. Lectura inteligente de errores de Django (Map errors)
    if (errors.isNotEmpty) {
      // Prioridad a mensaje general ('detail')
      if (errors.containsKey('detail')) {
        return errors['detail'].toString();
      }
      
      // Prioridad a errores generales ('non_field_errors')
      if (errors.containsKey('non_field_errors')) {
        final list = errors['non_field_errors'];
        if (list is List && list.isNotEmpty) return list.first.toString();
        return list.toString();
      }

      // Si no, tomamos el primer error de campo disponible
      // Ej: { "email": ["El email no es válido"] }
      final firstKey = errors.keys.first;
      final firstVal = errors[firstKey];
      
      String errorMsg = '';
      if (firstVal is List && firstVal.isNotEmpty) {
        errorMsg = firstVal.first.toString();
      } else {
        errorMsg = firstVal.toString();
      }

      // Formateamos la clave para que se vea bien (ej: fecha_nacimiento -> Fecha nacimiento)
      final fieldName = firstKey[0].toUpperCase() + firstKey.substring(1).replaceAll('_', ' ');
      return '$fieldName: $errorMsg';
    }

    // 4. Fallback final
    return message.isNotEmpty ? message : 'Ocurrió un error inesperado.';
  }

  String _formatSeconds(int segundos) {
    if (segundos < 60) return '$segundos segundos';
    
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    
    if (segs == 0) return '$minutos minutos';
    return '$minutos minutos y $segs segundos';
  }

  bool get isRecoverable {
    return isNetworkError ||
        isRateLimitError ||
        statusCode == 503 ||
        statusCode == 504;
  }

  ApiException copyWith({
    int? statusCode,
    String? message,
    Map<String, dynamic>? errors,
    Map<String, dynamic>? details,
    StackTrace? stackTrace,
    String? contexto,
  }) {
    return ApiException(
      statusCode: statusCode ?? this.statusCode,
      message: message ?? this.message,
      errors: errors ?? this.errors,
      details: details ?? this.details,
      stackTrace: stackTrace ?? this.stackTrace,
      contexto: contexto ?? this.contexto,
    );
  }
}