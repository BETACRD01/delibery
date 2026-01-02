// lib/widgets/maps/map_location_picker.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/primary_colors.dart';
import '../../theme/jp_theme.dart';

/// Selector de ubicación en mapa interactivo - Diseño Profesional
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

class _MapLocationPickerState extends State<MapLocationPicker>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(
    -0.1807,
    -78.4678,
  ); // Quito por defecto
  String _currentAddress = 'Moviendo mapa...';
  String _currentCity = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  bool _isDragging = false;

  // Animación del pin
  late AnimationController _pinAnimController;
  late Animation<double> _pinBounceAnim;

  @override
  void initState() {
    super.initState();

    // Configurar animación del pin
    _pinAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pinBounceAnim = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOut),
    );

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
    _pinAnimController.dispose();
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
          setState(() => _isLoadingLocation = false);
          unawaited(_getAddressFromLatLng(_currentPosition));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
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
              CameraUpdate.newLatLngZoom(newPosition, 17),
            ) ??
            Future.value(),
      );

      // Obtener dirección
      await _getAddressFromLatLng(newPosition);
    } catch (e) {
      if (!mounted) return;
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

        // Construir dirección principal (calle y número)
        String mainAddress = '';
        if (place.street != null && place.street!.isNotEmpty) {
          mainAddress = place.street!;
        }
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty) {
          mainAddress += ' ${place.subThoroughfare}';
        }

        // Obtener ciudad/localidad
        String city = '';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          city = place.subLocality!;
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          city = place.locality!;
        }

        if (!mounted) return;

        setState(() {
          _currentAddress = mainAddress.isNotEmpty
              ? mainAddress
              : 'Ubicación seleccionada';
          _currentCity = city;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress = 'Ubicación seleccionada';
        _currentCity =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoadingAddress = false;
      });
    }
  }

  void _onCameraMoveStarted() {
    if (!_isDragging) {
      setState(() => _isDragging = true);
      _pinAnimController.forward();
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position.target;
  }

  void _onCameraIdle() {
    if (_isDragging) {
      setState(() => _isDragging = false);
      _pinAnimController.reverse();
    }
    _getAddressFromLatLng(_currentPosition);
  }

  void _confirmarUbicacion() {
    final fullAddress = _currentCity.isNotEmpty
        ? '$_currentAddress, $_currentCity'
        : _currentAddress;
    widget.onLocationSelected(
      _currentPosition.latitude,
      _currentPosition.longitude,
      fullAddress,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? CupertinoColors.black.withValues(alpha: 0.8)
        : CupertinoColors.white.withValues(alpha: 0.95);

    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.label.resolveFrom(context),
            fontFamily: '.SF Pro Text',
            decoration: TextDecoration.none,
          ),
          child: Stack(
            children: [
              // ==================== MAPA FULLSCREEN ====================
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 16,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onCameraMoveStarted: _onCameraMoveStarted,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),

              // ==================== HEADER CON GLASSMORPHISM ====================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Barra de navegación
                          Row(
                            children: [
                              // Botón atrás
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors
                                        .tertiarySystemBackground
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.back,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Título
                              Expanded(
                                child: Text(
                                  'Seleccionar ubicación',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              // Botón mi ubicación
                              GestureDetector(
                                onTap: _isLoadingLocation
                                    ? null
                                    : _obtenerUbicacionActual,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColorsPrimary.main,
                                        AppColorsPrimary.main.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColorsPrimary.main.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _isLoadingLocation
                                      ? const Center(
                                          child: CupertinoActivityIndicator(
                                            color: CupertinoColors.white,
                                            radius: 10,
                                          ),
                                        )
                                      : const Icon(
                                          CupertinoIcons.location_fill,
                                          color: CupertinoColors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Barra de búsqueda (decorativa por ahora)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.tertiarySystemBackground
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: CupertinoColors.separator.resolveFrom(
                                  context,
                                ),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.search,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Buscar dirección...',
                                    style: TextStyle(
                                      color: CupertinoColors.placeholderText
                                          .resolveFrom(context),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ==================== PIN CENTRAL ANIMADO ====================
              Center(
                child: AnimatedBuilder(
                  animation: _pinAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _pinBounceAnim.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pin con gradiente
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColorsPrimary.main,
                                  AppColorsPrimary.main.withValues(alpha: 0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColorsPrimary.main.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.location_solid,
                                size: 24,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                          // Punta del pin
                          CustomPaint(
                            size: const Size(16, 12),
                            painter: _PinPointerPainter(
                              color: AppColorsPrimary.main,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Sombra del pin en el suelo
              if (!_isDragging)
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, 35),
                    child: Container(
                      width: 20,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

              // ==================== CARD INFERIOR CON INFO ====================
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                        bottom: MediaQuery.of(context).padding.bottom + 20,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey4,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Info de ubicación
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icono
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColorsPrimary.main.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  CupertinoIcons.map_pin_ellipse,
                                  color: AppColorsPrimary.main,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Textos
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isLoadingAddress)
                                      Row(
                                        children: [
                                          const CupertinoActivityIndicator(
                                            radius: 8,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Obteniendo dirección...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: CupertinoColors
                                                  .secondaryLabel
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                        ],
                                      )
                                    else ...[
                                      Text(
                                        _currentAddress,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoColors.label
                                              .resolveFrom(context),
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_currentCity.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _currentCity,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Botón confirmar
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              borderRadius: BorderRadius.circular(16),
                              onPressed: _isLoadingAddress
                                  ? null
                                  : _confirmarUbicacion,
                              color: AppColorsPrimary.main,
                              child: _isLoadingAddress
                                  ? const CupertinoActivityIndicator(
                                      color: CupertinoColors.white,
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.checkmark_circle_fill,
                                          color: CupertinoColors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Confirmar ubicación',
                                          style: TextStyle(
                                            fontSize: 17,
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
                ),
              ),

              // ==================== CONTROLES DE ZOOM ====================
              Positioned(
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 200,
                child: Column(
                  children: [
                    // Zoom In
                    _buildZoomButton(
                      icon: CupertinoIcons.plus,
                      onTap: () async {
                        await _mapController?.animateCamera(
                          CameraUpdate.zoomIn(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Zoom Out
                    _buildZoomButton(
                      icon: CupertinoIcons.minus,
                      onTap: () async {
                        await _mapController?.animateCamera(
                          CameraUpdate.zoomOut(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: CupertinoColors.systemGrey, size: 22),
      ),
    );
  }
}

/// Painter para la punta del pin
class _PinPointerPainter extends CustomPainter {
  final Color color;

  _PinPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
