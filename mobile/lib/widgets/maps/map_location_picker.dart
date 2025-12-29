// lib/widgets/maps/map_location_picker.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors_primary.dart';
import '../../theme/jp_theme.dart';

/// Selector de ubicación en mapa interactivo
class MapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double lat, double lng, String address) onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(
    -0.1807,
    -78.4678,
  ); // Quito por defecto
  String _currentAddress = 'Moviendo mapa...';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Si tiene coordenadas iniciales, usarlas
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentPosition = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _getAddressFromLatLng(_currentPosition);
    } else {
      // Intentar obtener ubicación actual
      _obtenerUbicacionActual();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Obtiene la ubicación actual del usuario
  Future<void> _obtenerUbicacionActual() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permisos denegados, usar ubicación por defecto
          setState(() => _isLoadingLocation = false);
          unawaited(_getAddressFromLatLng(_currentPosition));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permisos denegados permanentemente
        setState(() => _isLoadingLocation = false);
        unawaited(_getAddressFromLatLng(_currentPosition));
        return;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _currentPosition = newPosition;
        _isLoadingLocation = false;
      });

      // Animar cámara a la nueva posición
      unawaited(
        _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(newPosition, 15),
            ) ??
            Future.value(),
      );

      // Obtener dirección
      await _getAddressFromLatLng(newPosition);
    } catch (e) {
      if (!mounted) return;
      // Error al obtener ubicación, usar por defecto
      setState(() => _isLoadingLocation = false);
      unawaited(_getAddressFromLatLng(_currentPosition));
    }
  }

  /// Obtiene la dirección desde coordenadas (geocoding reverso)
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = [
          place.street,
          place.subLocality,
          place.locality,
        ].where((part) => part != null && part.isNotEmpty).toList();

        if (!mounted) return;

        setState(() {
          _currentAddress = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Ubicación seleccionada';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress =
            'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position.target;
    });
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_currentPosition);
  }

  void _confirmarUbicacion() {
    widget.onLocationSelected(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _currentAddress,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: JPCupertinoColors.surface(context),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('Seleccionar ubicación'),
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 14,
          color: CupertinoColors.black,
          fontFamily: '.SF Pro Text',
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Mapa
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Botón para volver a centrar en ubicación actual
              Positioned(
                top: 16,
                right: 16,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isLoadingLocation
                      ? null
                      : _obtenerUbicacionActual,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoadingLocation
                        ? const Center(
                            child: CupertinoActivityIndicator(radius: 8),
                          )
                        : const Icon(
                            CupertinoIcons.location_fill,
                            color: AppColorsPrimary.main,
                            size: 24,
                          ),
                  ),
                ),
              ),

              // Pin central - más pequeño y preciso
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pin principal
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColorsPrimary.main,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.white,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.smallcircle_fill_circle,
                          size: 12,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                    // Punto de precisión
                    Container(
                      width: 2,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColorsPrimary.main.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    // Sombra del pin
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Card de información en la parte superior
              Positioned(
                top: 16,
                left: 16,
                right: 76,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.map_pin_ellipse,
                            color: AppColorsPrimary.main,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Ubicación seleccionada',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _isLoadingAddress
                          ? const Row(
                              children: [
                                CupertinoActivityIndicator(radius: 8),
                                SizedBox(width: 8),
                                Text(
                                  'Obteniendo dirección...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _currentAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                ),
              ),

              // Botón de confirmar en la parte inferior
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: CupertinoButton(
                  onPressed: _isLoadingAddress ? null : _confirmarUbicacion,
                  color: AppColorsPrimary.main,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoadingAddress
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Confirmar ubicación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
