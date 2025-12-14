// lib/services/location_service.dart

import 'dart:math' show cos, sqrt, asin;
import 'package:geolocator/geolocator.dart';

/// Servicio de geolocalización para obtener ubicación del usuario
/// y calcular distancias entre coordenadas
class LocationService {
  /// Obtiene la posición actual del usuario
  /// Retorna null si no se pueden obtener los permisos o la ubicación
  Future<Position?> obtenerUbicacionActual() async {
    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 2. Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 3. Obtener posición actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si los permisos de ubicación están concedidos
  Future<bool> tienePermisos() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Verifica si el servicio de ubicación está habilitado
  Future<bool> servicioHabilitado() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Solicita permisos de ubicación
  Future<bool> solicitarPermisos() async {
    try {
      // Primero intentar con geolocator
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Abre la configuración de la aplicación para que el usuario pueda
  /// habilitar los permisos manualmente
  Future<void> abrirConfiguracion() async {
    await Geolocator.openLocationSettings();
  }

  /// Calcula la distancia entre dos puntos geográficos usando la fórmula de Haversine
  /// Retorna la distancia en kilómetros
  ///
  /// [lat1] Latitud del primer punto
  /// [lon1] Longitud del primer punto
  /// [lat2] Latitud del segundo punto
  /// [lon2] Longitud del segundo punto
  double calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;

    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Calcula la distancia desde la posición actual del usuario hasta un punto
  /// Retorna null si no se puede obtener la ubicación actual
  Future<double?> calcularDistanciaDesdeUsuario(
    double latDestino,
    double lonDestino,
  ) async {
    final posicion = await obtenerUbicacionActual();
    if (posicion == null) return null;

    return calcularDistancia(
      posicion.latitude,
      posicion.longitude,
      latDestino,
      lonDestino,
    );
  }

  /// Formatea la distancia en un formato legible
  /// Ejemplo: "1.5 km", "500 m"
  String formatearDistancia(double distanciaKm) {
    if (distanciaKm < 1) {
      final metros = (distanciaKm * 1000).round();
      return '$metros m';
    }
    return '${distanciaKm.toStringAsFixed(1)} km';
  }

  /// Verifica el estado completo de ubicación y permisos
  /// Retorna un objeto con el estado detallado
  Future<EstadoUbicacion> verificarEstado() async {
    final servicioHabilitado = await this.servicioHabilitado();
    final tienePermisos = await this.tienePermisos();
    final posicion = tienePermisos && servicioHabilitado
        ? await obtenerUbicacionActual()
        : null;

    return EstadoUbicacion(
      servicioHabilitado: servicioHabilitado,
      tienePermisos: tienePermisos,
      posicion: posicion,
    );
  }
}

/// Modelo que representa el estado de la ubicación
class EstadoUbicacion {
  final bool servicioHabilitado;
  final bool tienePermisos;
  final Position? posicion;

  EstadoUbicacion({
    required this.servicioHabilitado,
    required this.tienePermisos,
    this.posicion,
  });

  bool get puedeObtenerUbicacion =>
      servicioHabilitado && tienePermisos && posicion != null;

  String get mensajeError {
    if (!servicioHabilitado) {
      return 'El servicio de ubicación está deshabilitado';
    }
    if (!tienePermisos) {
      return 'No se tienen permisos de ubicación';
    }
    if (posicion == null) {
      return 'No se pudo obtener la ubicación';
    }
    return '';
  }
}
