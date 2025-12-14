// lib/config/constantes.dart

import '../config/api_config.dart';
import 'dart:developer' as developer;

class JPConstantes {
  JPConstantes._();

  // -- Info App --
  static const String appName = 'JP Express';
  static const String appVersion = '1.0.0';
  static const String appSlogan = 'Tu delivery favorito!';

  // -- Assets --
  static String get defaultAvatarUrl => 'https://via.placeholder.com/150';
  static const String logoPath = 'assets/images/logo.png';
  static const String productPlaceholder = 'assets/images/product_placeholder.png';

  // -- Limites --
  static const int maxImageSizeMB = 5;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;
  
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedComprobanteExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  static const int minAliasLength = 3;
  static const int maxAliasLength = 50;
  static const int maxObservacionesLength = 100;
  static const int minDireccionLength = 10;

  // -- Coordenadas (Ecuador) --
  static const double latitudMinEcuador = -5.0;
  static const double latitudMaxEcuador = 2.0;
  static const double longitudMinEcuador = -92.0;
  static const double longitudMaxEcuador = -75.0;
  
  static const double latitudDefaultQuito = -0.1807;
  static const double longitudDefaultQuito = -78.4678;

  // -- Reglas de Negocio --
  static const int pedidosParaVIP = 10;
  static const int pedidosParaRifa = 3;
  static const double calificacionMin = 0.0;
  static const double calificacionMax = 5.0;

  // -- Tiempos --
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration snackbarErrorDuration = Duration(seconds: 5);
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration imageLoadTimeout = Duration(seconds: 10);

  // -- Mensajes --
  static const String msgCargando = 'Cargando...';
  static const String msgGuardando = 'Guardando...';
  static const String msgExito = 'Operacion exitosa';
  static const String msgError = 'Ocurrio un error';
  static const String msgSinConexion = 'Sin conexion a internet';
  
  // -- UI --
  static const double maxWidthTablet = 768.0;
  static const double maxWidthDesktop = 1200.0;
  static const double paddingStandard = 16.0;
}

class JPValidadores {
  JPValidadores._();

  static bool coordenadaValidaEcuador(double lat, double lon) {
    return (lat >= JPConstantes.latitudMinEcuador && lat <= JPConstantes.latitudMaxEcuador) &&
           (lon >= JPConstantes.longitudMinEcuador && lon <= JPConstantes.longitudMaxEcuador);
  }

  static String? validarTextoBasico(String? value, int minLen, String campo) {
    if (value == null || value.trim().isEmpty) return 'El campo $campo es requerido';
    if (value.trim().length < minLen) return 'Minimo $minLen caracteres';
    return null;
  }

  static bool extensionValida(String filename, List<String> allowed) {
    return allowed.contains(filename.split('.').last.toLowerCase());
  }
}

class JPHelpers {
  JPHelpers._();

  static String construirUrlImagen(String? path) {
    if (path == null || path.isEmpty) return JPConstantes.defaultAvatarUrl;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.baseUrl}$path';
  }

  static String formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  static String obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos dias';
    if (hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

enum RegionEcuador { costa, sierra, oriente, galapagos, desconocida }

class JPRegiones {
  static RegionEcuador detectarRegion(double lat, double lon) {
    if (lat >= -3.5 && lat <= 2.0 && lon >= -81.0 && lon <= -75.0) return RegionEcuador.costa;
    if (lat >= -4.5 && lat <= 1.5 && lon >= -79.5 && lon <= -77.0) return RegionEcuador.sierra;
    if (lat >= -5.0 && lat <= 0.5 && lon >= -78.0 && lon <= -75.0) return RegionEcuador.oriente;
    if (lat >= -1.5 && lat <= 1.5 && lon >= -92.0 && lon <= -89.0) return RegionEcuador.galapagos;
    return RegionEcuador.desconocida;
  }
}

enum TipoDireccion { casa, trabajo, otro }
enum TipoMetodoPago { efectivo, transferencia, tarjeta }

class JPFeatures {
  static const bool debugMode = true;
  static const bool enableAnimations = true;
  static const bool enablePushNotifications = true;
}

class JPDebug {
  static void log(String msg) {
    if (JPFeatures.debugMode) developer.log('[JP] $msg', name: 'JPDebug');
  }
  
  static void error(String msg, [Object? err]) {
    if (JPFeatures.debugMode) developer.log('[ERROR] $msg', error: err, name: 'JPDebug');
  }
}