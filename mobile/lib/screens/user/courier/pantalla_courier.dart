import 'dart:async';
import 'dart:ui'; // For ImageFilter
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../services/envios/envios_service.dart';
import '../../../../services/core/ui/toast_service.dart';
import '../../../../theme/primary_colors.dart';
import '../../../../widgets/maps/map_location_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PantallaCourier extends StatefulWidget {
  const PantallaCourier({super.key});

  @override
  State<PantallaCourier> createState() => _PantallaCourierState();
}

class _PantallaCourierState extends State<PantallaCourier> {
  // Mapa
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {}; // Para la ruta

  // Datos del Pedido
  String _direccionOrigen = 'Obteniendo ubicación...';
  LatLng? _origen;

  String _direccionDestino = 'Seleccionar destino';
  LatLng? _destino;

  // Información de la ruta
  String? _distanciaRuta;
  String? _tiempoRuta;

  // Nuevos Campos
  final _descripcionCtrl = TextEditingController();
  final _otroDetalleCtrl = TextEditingController(); // Nuevo para "Otro"
  final _nombreRecibeCtrl = TextEditingController();
  final _telefonoRecibeCtrl = TextEditingController();
  String _tipoPaquete = 'Paquete'; // Default

  // Estado
  bool _loading = false;
  bool _loadingRuta = false;
  Map<String, dynamic>? _cotizacion;

  // Lista de tipos de paquetes
  final List<Map<String, dynamic>> _tiposPaquete = [
    {'id': 'Paquete', 'icon': CupertinoIcons.cube_box, 'label': 'Paquete'},
    {'id': 'Documentos', 'icon': CupertinoIcons.doc_text, 'label': 'Docs'},
    {'id': 'Llaves', 'icon': CupertinoIcons.lock, 'label': 'Llaves'},
    {'id': 'Otro', 'icon': CupertinoIcons.question_circle, 'label': 'Otro'},
  ];

  // API Key para Directions (usa la misma de Google Maps)
  static const String _googleApiKey = 'AIzaSyAVomIe-K4kpGMrQTc-bZaNcBvJtkK-KBA';

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _origen = LatLng(position.latitude, position.longitude);
            _direccionOrigen = 'Mi ubicación actual';
            _actualizarMarcadores();
          });
          unawaited(_moverCamara(_origen!));
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  void _actualizarMarcadores() {
    _markers.clear();
    if (_origen != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('origen'),
          position: _origen!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Origen (Recogida)'),
        ),
      );
    }
    if (_destino != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destino'),
          position: _destino!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destino (Entrega)'),
        ),
      );
    }
  }

  Future<void> _moverCamara(LatLng pos) async {
    try {
      final GoogleMapController controller = await _controller.future;
      if (!mounted) return;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
    } catch (e) {
      debugPrint('Error moviendo cámara: $e');
    }
  }

  /// Obtiene la ruta desde la API de Directions
  Future<void> _obtenerRuta() async {
    if (_origen == null || _destino == null) return;

    setState(() => _loadingRuta = true);

    try {
      // Calcular distancia simple (línea recta) como fallback
      final distancia = Geolocator.distanceBetween(
        _origen!.latitude,
        _origen!.longitude,
        _destino!.latitude,
        _destino!.longitude,
      );

      // Crear polilínea simple (línea recta entre puntos)
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta'),
          points: [_origen!, _destino!],
          color: AppColorsPrimary.main,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );

      // Calcular tiempo estimado (asumiendo 30 km/h promedio en ciudad)
      final distanciaKm = distancia / 1000;
      final tiempoMinutos = (distanciaKm / 30 * 60).ceil();

      setState(() {
        _distanciaRuta = distanciaKm < 1
            ? '${distancia.toInt()} m'
            : '${distanciaKm.toStringAsFixed(1)} km';
        _tiempoRuta = tiempoMinutos < 60
            ? '$tiempoMinutos min'
            : '${(tiempoMinutos / 60).floor()}h ${tiempoMinutos % 60}min';
        _loadingRuta = false;
      });

      // Intentar obtener ruta real de Directions API
      unawaited(_obtenerRutaReal());

      // Ajustar cámara para mostrar toda la ruta
      unawaited(_ajustarCamaraParaRuta());
    } catch (e) {
      debugPrint('Error obteniendo ruta: $e');
      setState(() => _loadingRuta = false);
    }
  }

  /// Intenta obtener la ruta real usando Directions API
  Future<void> _obtenerRutaReal() async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_origen!.latitude},${_origen!.longitude}'
        '&destination=${_destino!.latitude},${_destino!.longitude}'
        '&mode=driving'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Decodificar polyline
          final puntos = _decodePolyline(route['overview_polyline']['points']);

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('ruta_real'),
                points: puntos,
                color: AppColorsPrimary.main,
                width: 5,
              ),
            );
            _distanciaRuta = leg['distance']['text'];
            _tiempoRuta = leg['duration']['text'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error con Directions API: $e');
      // Mantiene la ruta simple como fallback
    }
  }

  /// Decodifica el polyline de Google
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Ajusta la cámara para mostrar origen y destino
  Future<void> _ajustarCamaraParaRuta() async {
    if (_origen == null || _destino == null) return;

    try {
      final GoogleMapController controller = await _controller.future;
      LatLngBounds bounds = _calcularBounds(_origen!, _destino!);
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (e) {
      debugPrint('Error ajustando cámara: $e');
    }
  }

  Future<void> _seleccionarUbicacion(bool esOrigen) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: esOrigen ? _origen?.latitude : _destino?.latitude,
          initialLongitude: esOrigen ? _origen?.longitude : _destino?.longitude,
          onLocationSelected: (lat, lng, address) {
            setState(() {
              if (esOrigen) {
                _origen = LatLng(lat, lng);
                _direccionOrigen = address;
              } else {
                _destino = LatLng(lat, lng);
                _direccionDestino = address;
              }
              _actualizarMarcadores();
              _cotizacion = null; // Reset cotización al cambiar puntos
              _polylines.clear();
              _distanciaRuta = null;
              _tiempoRuta = null;
            });

            // Si ambos puntos están seleccionados, obtener ruta
            if (_origen != null && _destino != null) {
              _obtenerRuta();
            } else {
              unawaited(_moverCamara(LatLng(lat, lng)));
            }
          },
        ),
      ),
    );
  }

  /// Intercambia origen y destino
  void _swapUbicaciones() {
    if (_origen == null && _destino == null) return;

    setState(() {
      final tempLatLng = _origen;
      final tempDireccion = _direccionOrigen;

      _origen = _destino;
      _direccionOrigen = _direccionDestino;

      _destino = tempLatLng;
      _direccionDestino = tempDireccion;

      _actualizarMarcadores();
      _cotizacion = null;
    });

    if (_origen != null && _destino != null) {
      _obtenerRuta();
    }
  }

  Future<void> _cotizar() async {
    // Validaciones
    if (_origen == null || _destino == null) {
      ToastService().showWarning(context, 'Selecciona origen y destino');
      return;
    }
    if (_nombreRecibeCtrl.text.isEmpty || _telefonoRecibeCtrl.text.isEmpty) {
      ToastService().showWarning(context, 'Completa datos del destinatario');
      return;
    }

    setState(() => _loading = true);

    try {
      final service = EnviosService();
      final resultado = await service.cotizarEnvio(
        latDestino: _destino!.latitude,
        lngDestino: _destino!.longitude,
        latOrigen: _origen!.latitude,
        lngOrigen: _origen!.longitude,
        tipoServicio: 'courier',
      );

      setState(() {
        _cotizacion = resultado;
        _loading = false;
      });

      // Ajustar camara para ver ambos puntos si es posible
      final GoogleMapController controller = await _controller.future;
      LatLngBounds bounds = _calcularBounds(_origen!, _destino!);
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastService().showError(context, e.toString());
    }
  }

  LatLngBounds _calcularBounds(LatLng p1, LatLng p2) {
    return LatLngBounds(
      southwest: LatLng(
        p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
      ),
      northeast: LatLng(
        p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
      ),
    );
  }

  // ================== PAYMENT & ORDER LOGIC ==================

  void _mostrarModalPago() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Método de Pago'),
        message: const Text(
          'Selecciona cómo pagarás al repartidor al recibir tu pedido.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _crearPedido('EFECTIVO');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.money, color: AppColorsPrimary.main),
                SizedBox(width: 8),
                Text('Efectivo'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _crearPedido('TRANSFERENCIA');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.account_balance, color: AppColorsPrimary.main),
                SizedBox(width: 8),
                Text('Transferencia'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _crearPedido(String metodoPago) async {
    setState(() => _loading = true);
    try {
      final service = EnviosService();

      // Payload para crear el pedido
      final origen = {
        'lat': _origen!.latitude,
        'lng': _origen!.longitude,
        'direccion': _direccionOrigen,
      };
      final destino = {
        'lat': _destino!.latitude,
        'lng': _destino!.longitude,
        'direccion': _direccionDestino,
      };
      final receptor = {
        'nombre': _nombreRecibeCtrl.text,
        'telefono': _telefonoRecibeCtrl.text,
      };
      final paquete = {
        'tipo': _tipoPaquete,
        'descripcion': _tipoPaquete == 'Otro'
            ? 'Otro: ${_otroDetalleCtrl.text} - ${_descripcionCtrl.text}'
            : _descripcionCtrl.text,
        'instrucciones': _otroDetalleCtrl.text,
      };
      final pago = {
        'metodo': metodoPago,
        'total_estimado': _cotizacion!['total_envio'],
      };

      // Llamar al servicio real
      final resultado = await service.crearPedidoCourier(
        origen: origen,
        destino: destino,
        receptor: receptor,
        paquete: paquete,
        pago: pago,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      final numeroPedido = resultado['pedido']?['numero_pedido'] ?? 'S/N';

      // Mostrar confirmación
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: Colors.green,
            size: 50,
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '¡Pedido Solicitado!\n\nNúmero: $numeroPedido\n\nEstamos buscando un repartidor cercano.',
              style: const TextStyle(fontSize: 15),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.pop(context); // Solo cerrar el diálogo
                _limpiarFormulario(); // Resetear formulario
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastService().showError(context, 'Error al crear pedido: $e');
    }
  }

  /// Restablece el formulario a su estado inicial
  void _limpiarFormulario() {
    setState(() {
      // Resetear destinos
      _direccionDestino = 'Seleccionar destino';
      _destino = null;

      // Resetear ruta
      _distanciaRuta = null;
      _tiempoRuta = null;
      _cotizacion = null;

      // Limpiar mapa
      _polylines.clear();
      _markers.clear();

      // Limpiar campos de texto
      _descripcionCtrl.clear();
      _otroDetalleCtrl.clear();
      _nombreRecibeCtrl.clear();
      _telefonoRecibeCtrl.clear();
      _tipoPaquete = 'Paquete';

      // Resetear origen y buscar ubicación actual de nuevo
      _direccionOrigen = 'Obteniendo ubicación...';
      _origen = null;
    });

    // Volver a obtener la ubicación actual
    _obtenerUbicacionActual();
  }

  @override
  Widget build(BuildContext context) {
    // Usar tema adaptativo para colores
    // Glass effect background color
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? CupertinoColors.black.withValues(alpha: 0.85)
        : CupertinoColors.white.withValues(alpha: 0.92);
    final textColor = CupertinoColors.label.resolveFrom(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      resizeToAvoidBottomInset: false, // Evitar que el teclado rompa el layout
      body: Stack(
        children: [
          // 1. MAPA DE FONDO (TODA LA PANTALLA)
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-1.24908, -78.61675),
                zoom: 6,
              ),
              markers: _markers,
              polylines: _polylines, // Agregar polylines
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
            ),
          ),

          // 2. INFORMACIÓN DE RUTA EN LA PARTE SUPERIOR
          if (_origen != null && _destino != null && _distanciaRuta != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Distancia
                        _buildRouteInfoItem(
                          icon: CupertinoIcons.map,
                          label: 'Distancia',
                          value: _loadingRuta ? '...' : _distanciaRuta!,
                          color: AppColorsPrimary.main,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: CupertinoColors.systemGrey4,
                        ),
                        // Tiempo
                        _buildRouteInfoItem(
                          icon: CupertinoIcons.clock,
                          label: 'Tiempo est.',
                          value: _loadingRuta ? '...' : _tiempoRuta!,
                          color: CupertinoColors.systemOrange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. PANEL INFERIOR CON ALTURA LIMITADA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.52, // Máximo 52% de pantalla
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- STATIC HEADER SECTION ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Handle bar
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey3,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Título con precio
                              Row(
                                children: [
                                  Text(
                                    'Nuevo Envío',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_cotizacion != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColorsPrimary.main,
                                            AppColorsPrimary.main.withValues(
                                              alpha: 0.8,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColorsPrimary.main
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '\$${_cotizacion!['total_envio']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),

                        // --- SCROLLABLE CONTENT SECTION ---
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 10,
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // SECCIÓN 1: RUTA MEJORADA
                                _buildEnhancedRouteSelector(context, textColor),

                                const SizedBox(height: 20),

                                // SECCIÓN 2: TIPO DE PAQUETE
                                Text(
                                  '¿Qué envías?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 75,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _tiposPaquete.length,
                                    separatorBuilder: (c, i) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (context, index) {
                                      final item = _tiposPaquete[index];
                                      final isSelected =
                                          _tipoPaquete == item['id'];
                                      return _buildPackageTypeOption(
                                        context,
                                        item,
                                        isSelected,
                                      );
                                    },
                                  ),
                                ),

                                if (_tipoPaquete == 'Otro') ...[
                                  const SizedBox(height: 10),
                                  _buildInput(
                                    context,
                                    controller: _otroDetalleCtrl,
                                    icon: CupertinoIcons.question_circle,
                                    placeholder: 'Especifique qué va a enviar',
                                    maxLines: 1,
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // SECCIÓN 3: DESTINATARIO
                                Text(
                                  '¿Quién recibe el paquete?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      flex: 4, // 40% para nombre
                                      child: _buildInput(
                                        context,
                                        controller: _nombreRecibeCtrl,
                                        icon: CupertinoIcons.person,
                                        placeholder: 'Nombres',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex:
                                          6, // 60% para teléfono (necesita mas espacio por la bandera)
                                      child: Container(
                                        height:
                                            50, // Altura fija para igualar al input vecino
                                        decoration: BoxDecoration(
                                          color: CupertinoColors
                                              .tertiarySystemBackground
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: CupertinoColors.separator
                                                .resolveFrom(context),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: IntlPhoneField(
                                          controller: _telefonoRecibeCtrl,
                                          decoration: InputDecoration(
                                            hintText: 'Teléfono',
                                            hintStyle: TextStyle(
                                              color: CupertinoColors
                                                  .placeholderText
                                                  .resolveFrom(context),
                                              fontSize: 15,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            counterText: '',
                                            contentPadding:
                                                const EdgeInsets.only(
                                                  top: 14,
                                                ), // Centrado vertical
                                            isDense: true,
                                          ),
                                          initialCountryCode: 'EC',
                                          languageCode: 'es',
                                          style: TextStyle(
                                            color: CupertinoColors.label
                                                .resolveFrom(context),
                                            fontSize: 15,
                                          ),
                                          dropdownTextStyle: TextStyle(
                                            color: CupertinoColors.label
                                                .resolveFrom(context),
                                            fontSize: 15,
                                          ),
                                          dropdownIcon: Icon(
                                            Icons.arrow_drop_down,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                            size: 18,
                                          ),
                                          flagsButtonPadding:
                                              const EdgeInsets.only(left: 8),
                                          showCountryFlag: true,
                                          disableLengthCheck: true,
                                          showDropdownIcon:
                                              false, // Ahorrar espacio
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // SECCIÓN 4: DESCRIPCIÓN
                                _buildInput(
                                  context,
                                  controller: _descripcionCtrl,
                                  icon:
                                      CupertinoIcons.pencil_ellipsis_rectangle,
                                  placeholder: 'Instrucciones (Opcional)',
                                  maxLines: 1,
                                ),

                                const SizedBox(height: 20),

                                // BOTÓN DE ACCIÓN
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    borderRadius: BorderRadius.circular(16),
                                    color: AppColorsPrimary.main,
                                    onPressed: _cotizacion == null
                                        ? _cotizar
                                        : _mostrarModalPago,
                                    child: Text(
                                      _cotizacion == null
                                          ? 'Cotizar Envío'
                                          : 'Solicitar Shopper',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
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
          ),

          // 4. OVERLAY DE CARGA (Pantalla Completa)
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground.resolveFrom(
                          context,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CupertinoActivityIndicator(radius: 18),
                          const SizedBox(height: 16),
                          Text(
                            _cotizacion == null
                                ? 'Calculando tarifa...'
                                : 'Procesando...',
                            style: TextStyle(
                              color: CupertinoColors.label.resolveFrom(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Widget de información de ruta
  Widget _buildRouteInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  /// Selector de ruta mejorado con diseño visual
  Widget _buildEnhancedRouteSelector(BuildContext context, Color textColor) {
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Iconos y línea conectora
          Column(
            children: [
              // Icono origen
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColorsPrimary.main.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColorsPrimary.main, width: 2),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: AppColorsPrimary.main,
                  size: 18,
                ),
              ),
              // Línea conectora con puntos
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: CustomPaint(
                  painter: _DottedLinePainter(
                    color: CupertinoColors.systemGrey3,
                  ),
                ),
              ),
              // Icono destino
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.systemRed,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: CupertinoColors.systemRed,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Textos de dirección
          Expanded(
            child: Column(
              children: [
                // ORIGEN
                GestureDetector(
                  onTap: () => _seleccionarUbicacion(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemBackground
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECOGIDA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColorsPrimary.main,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _direccionOrigen,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: secondaryLabel,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // DESTINO
                GestureDetector(
                  onTap: () => _seleccionarUbicacion(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemBackground
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ENTREGA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.systemRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _direccionDestino,
                                style:
                                    _direccionDestino == 'Seleccionar destino'
                                    ? TextStyle(
                                        color: secondaryLabel,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      )
                                    : TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: secondaryLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botón de swap
          GestureDetector(
            onTap: _swapUbicaciones,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemBackground.resolveFrom(
                  context,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
              child: Icon(
                CupertinoIcons.arrow_up_arrow_down,
                size: 18,
                color: secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageTypeOption(
    BuildContext context,
    Map<String, dynamic> item,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _tipoPaquete = item['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 68,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsPrimary.main.withValues(alpha: 0.15)
              : CupertinoColors.tertiarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColorsPrimary.main, width: 2)
              : Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColorsPrimary.main.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item['icon'],
              color: isSelected
                  ? AppColorsPrimary.main
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item['label'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColorsPrimary.main
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: null, // Remove default border
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 15,
              ),
              placeholderStyle: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter para línea punteada
class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
