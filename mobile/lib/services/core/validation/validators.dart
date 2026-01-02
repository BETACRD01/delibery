// lib/services/core/validation/validators.dart
import '../../../config/network/api_config.dart';

/// Validadores de negocio para la aplicación
/// Incluye validaciones de email, passwords, datos Ecuador, etc.
class Validators {
  Validators._();

  // --------------------------------------------------------------------------
  // Expresiones Regulares
  // --------------------------------------------------------------------------

  static final _email = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );
  static final _letra = RegExp(r'[a-zA-Z]');
  static final _digito = RegExp(r'\d');
  static final _espacio = RegExp(r'\s');
  static final _soloNumeros = RegExp(r'^\d+$');
  static final _celularEc = RegExp(r'^09\d{8}$');
  static final _username = RegExp(r'^[a-zA-Z0-9_-]+$');
  static final _ruc = RegExp(r'^\d{13}$');
  static final _placa = RegExp(r'^[A-Z]{3}\d{4}$');
  static final _licencia = RegExp(r'^\d{10}$');
  static final _fecha = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  // --------------------------------------------------------------------------
  // Validaciones Generales
  // --------------------------------------------------------------------------

  static bool esEmailValido(String email) =>
      email.isNotEmpty && _email.hasMatch(email);

  static bool esUsernameValido(String username) =>
      username.length >= 3 && _username.hasMatch(username);

  static bool esCodigoValido(String codigo) =>
      codigo.length == ApiConfig.codigoLongitud &&
      _soloNumeros.hasMatch(codigo);

  static bool noEstaVacio(String? texto) =>
      texto != null && texto.trim().isNotEmpty;

  static Map<String, dynamic> validarPassword(String password) {
    final errores = <String>[];

    if (password.length < 8) {
      errores.add('Debe tener al menos 8 caracteres');
    }
    if (!_letra.hasMatch(password)) {
      errores.add('Debe contener al menos una letra');
    }
    if (!_digito.hasMatch(password)) {
      errores.add('Debe contener al menos un numero');
    }
    if (_espacio.hasMatch(password)) {
      errores.add('No puede contener espacios');
    }

    return {'valida': errores.isEmpty, 'errores': errores};
  }

  // --------------------------------------------------------------------------
  // Validaciones Ecuador
  // --------------------------------------------------------------------------

  static bool esCelularValido(String celular) =>
      celular.length == 10 && _celularEc.hasMatch(celular);

  static bool esRucValido(String ruc) => ruc.length == 13 && _ruc.hasMatch(ruc);

  static bool esPlacaValida(String placa) {
    final norm = normalizarPlaca(placa);
    return norm.length == 7 && _placa.hasMatch(norm);
  }

  static bool esLicenciaValida(String licencia) =>
      licencia.length == 10 && _licencia.hasMatch(licencia);

  // --------------------------------------------------------------------------
  // Validaciones Fecha
  // --------------------------------------------------------------------------

  static bool esFechaFormatoValido(String fecha) => _fecha.hasMatch(fecha);

  static Map<String, dynamic> validarFechaNacimiento(DateTime fecha) {
    final hoy = DateTime.now();
    var edad = hoy.year - fecha.year;

    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }

    return {
      'valida': edad >= 18,
      'edad': edad,
      'mensaje': edad < 18 ? 'Debes ser mayor de 18 anos' : null,
    };
  }

  // --------------------------------------------------------------------------
  // Normalizadores
  // --------------------------------------------------------------------------

  static String normalizarEmail(String email) => email.trim().toLowerCase();
  static String normalizarTexto(String texto) => texto.trim();
  static String normalizarPlaca(String placa) =>
      placa.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
}
