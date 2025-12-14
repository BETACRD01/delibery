// lib/services/api_validators.dart

import '../../config/api_config.dart';

/// Validadores estaticos para datos de entrada de la API
class ApiValidators {
  ApiValidators._();

  // ---------------------------------------------------------------------------
  // EXPRESIONES REGULARES (Precompiladas para rendimiento)
  // ---------------------------------------------------------------------------
  
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );
  static final RegExp _letterRegex = RegExp(r'[a-zA-Z]');
  static final RegExp _digitRegex = RegExp(r'\d');
  static final RegExp _spaceRegex = RegExp(r'\s');
  static final RegExp _numericOnlyRegex = RegExp(r'^\d+$');
  static final RegExp _ecuadorCelularRegex = RegExp(r'^09\d{8}$');
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
  static final RegExp _rucRegex = RegExp(r'^\d{13}$');
  static final RegExp _placaRegex = RegExp(r'^[A-Z]{3}\d{4}$');
  static final RegExp _licenciaRegex = RegExp(r'^\d{10}$');
  static final RegExp _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  // ---------------------------------------------------------------------------
  // VALIDACIONES GENERALES
  // ---------------------------------------------------------------------------

  static bool esEmailValido(String email) {
    return email.isNotEmpty && _emailRegex.hasMatch(email);
  }

  static Map<String, dynamic> validarPassword(String password) {
    final errores = <String>[];

    if (password.length < 8) {
      errores.add('Debe tener al menos 8 caracteres');
    }
    if (!password.contains(_letterRegex)) {
      errores.add('Debe contener al menos una letra');
    }
    if (!password.contains(_digitRegex)) {
      errores.add('Debe contener al menos un numero');
    }
    if (password.contains(_spaceRegex)) {
      errores.add('No puede contener espacios');
    }

    return {'valida': errores.isEmpty, 'errores': errores};
  }

  static bool esCodigoValido(String codigo) {
    // Valida longitud exacta segun configuracion y que sea numerico
    if (codigo.length != ApiConfig.codigoLongitud) return false;
    return _numericOnlyRegex.hasMatch(codigo);
  }

  static bool esUsernameValido(String username) {
    if (username.isEmpty || username.length < 3) return false;
    return _usernameRegex.hasMatch(username);
  }

  static bool noEstaVacio(String? texto) {
    return texto != null && texto.trim().isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES LOCALES (ECUADOR)
  // ---------------------------------------------------------------------------

  static bool esCelularValido(String celular) {
    if (celular.length != 10) return false;
    return _ecuadorCelularRegex.hasMatch(celular);
  }

  static bool esRucValido(String ruc) {
    if (ruc.length != 13) return false;
    return _rucRegex.hasMatch(ruc);
  }

  static bool esPlacaValida(String placa) {
    final placaNorm = normalizarPlaca(placa);
    if (placaNorm.length != 7) return false;
    return _placaRegex.hasMatch(placaNorm);
  }

  static bool esLicenciaValida(String licencia) {
    if (licencia.length != 10) return false;
    return _licenciaRegex.hasMatch(licencia);
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES DE FECHA
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> validarFechaNacimiento(DateTime fecha) {
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;

    // Ajuste si aun no cumple años en el mes/dia actual
    if (hoy.month < fecha.month || 
       (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }

    return {
      'valida': edad >= 18,
      'edad': edad,
      'mensaje': edad < 18 ? 'Debes ser mayor de 18 años' : null,
    };
  }

  static bool esFechaFormatoValido(String fecha) {
    return _dateRegex.hasMatch(fecha);
  }

  // ---------------------------------------------------------------------------
  // NORMALIZADORES
  // ---------------------------------------------------------------------------

  static String normalizarEmail(String email) => email.trim().toLowerCase();

  static String normalizarTexto(String texto) => texto.trim();

  static String normalizarPlaca(String placa) {
    return placa.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
  }
}