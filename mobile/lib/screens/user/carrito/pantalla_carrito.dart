// lib/screens/user/carrito/pantalla_carrito.dart

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../../../theme/jp_theme.dart';
import '../../../providers/proveedor_carrito.dart';
import '../../../services/envio_service.dart';
import '../../../services/usuarios_service.dart';
import '../../../models/usuario.dart';
import '../../../services/toast_service.dart';
import '../../user/perfil/configuracion/direcciones/pantalla_mis_direcciones.dart';
import 'carrito_bottom_bar.dart';
import 'carrito_checkout_content.dart';
import 'carrito_empty_state.dart';
import 'carrito_header.dart';
import 'carrito_item_card.dart';
import 'carrito_loading_state.dart';
import 'carrito_navigation_bar.dart';

/// Pantalla del carrito de compras iOS-style
class PantallaCarrito extends StatefulWidget {
  const PantallaCarrito({super.key});

  @override
  State<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends State<PantallaCarrito> {
  final _direccionController = TextEditingController();
  final _instruccionesController = TextEditingController();
  final _usuarioService = UsuarioService();

  String _metodoPago = 'efectivo';
  Map<String, dynamic>? _cotizacionEnvio;
  double? _destLat;
  double? _destLng;
  double? get _recargoNocturno {
    final valor = _cotizacionEnvio?['recargo_nocturno'];
    if (valor == null) return null;
    return double.tryParse(valor.toString());
  }

  String _nombreDireccionVisible(DireccionModel dir) {
    if (dir.etiqueta.isNotEmpty && !_esPlaceholder(dir.etiqueta)) {
      return dir.etiqueta;
    }

    final partes = <String>[];

    if (dir.direccion.isNotEmpty && !_esPlaceholder(dir.direccion)) {
      partes.add(dir.direccion);
    } else if (dir.direccionCompleta.isNotEmpty &&
        !_esPlaceholder(dir.direccionCompleta)) {
      partes.add(dir.direccionCompleta);
    }

    if (dir.ciudad != null && dir.ciudad!.isNotEmpty) {
      partes.add(dir.ciudad!);
    }

    if (partes.isEmpty) return 'Dirección guardada';
    return partes.join(', ');
  }

  Future<void> _irAAgregarDireccion() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PantallaAgregarDireccion()),
    );
    await _cargarDireccionesGuardadas();
  }

  bool _esPlaceholder(String valor) {
    final v = valor.toLowerCase().trim();
    return RegExp(r'^direcci[oó]n\s*\d+$').hasMatch(v);
  }

  bool _mostrarInstrucciones = false;

  // Direcciones guardadas
  List<DireccionModel> _direccionesGuardadas = [];
  DireccionModel? _direccionSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorCarrito>().cargarCarrito();
      _cargarDireccionesGuardadas();
    });
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _instruccionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDireccionesGuardadas() async {
    try {
      final direcciones = await _usuarioService.listarDirecciones();
      setState(() {
        _direccionesGuardadas = direcciones;
        _direccionSeleccionada =
            direcciones
                .where((d) => d.esPredeterminada)
                .fold<DireccionModel?>(null, (prev, curr) => curr) ??
            (direcciones.isNotEmpty ? direcciones.first : null);

        if (_direccionSeleccionada != null) {
          _direccionController.text = _direccionSeleccionada!.direccionCompleta;
          _destLat = _direccionSeleccionada!.latitud;
          _destLng = _direccionSeleccionada!.longitud;
          _mostrarInstrucciones =
              _direccionSeleccionada!.indicaciones?.isNotEmpty == true;
          if (_mostrarInstrucciones) {
            _instruccionesController.text =
                _direccionSeleccionada!.indicaciones!;
          } else {
            _instruccionesController.clear();
          }
        } else {
          _direccionController.clear();
          _destLat = null;
          _destLng = null;
          _mostrarInstrucciones = false;
          _instruccionesController.clear();
        }
      });
    } catch (e) {
      debugPrint('Error cargando direcciones: $e');
    }
  }

  void _aplicarDireccionGuardada(
    DireccionModel direccion,
    void Function(void Function()) safeSetModalState,
    ProveedorCarrito carritoProvider,
  ) {
    safeSetModalState(() {
      _direccionSeleccionada = direccion;
      _direccionController.text = direccion.direccionCompleta;
      _destLat = direccion.latitud;
      _destLng = direccion.longitud;
      _mostrarInstrucciones = direccion.indicaciones?.isNotEmpty == true;
      if (_mostrarInstrucciones) {
        _instruccionesController.text = direccion.indicaciones!;
      } else {
        _instruccionesController.clear();
      }
    });

    _cotizarEnvioConDestino(
      direccion.latitud,
      direccion.longitud,
      safeSetModalState,
      carritoProvider,
    );
  }

  Future<void> _mostrarSelectorDireccionesGuardadas(
    void Function(void Function()) safeSetModalState,
    ProveedorCarrito carritoProvider,
  ) async {
    if (_direccionesGuardadas.isEmpty) {
      ToastService().showWarning(
        context,
        'Aún no tienes direcciones guardadas',
      );
      return;
    }

    DireccionModel? seleccionTemporal = _direccionSeleccionada;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: JPCupertinoColors.surface(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: JPCupertinoColors.systemGrey4(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Título
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Mis direcciones guardadas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: JPCupertinoColors.label(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Lista de direcciones
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _direccionesGuardadas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final direccion = _direccionesGuardadas[index];
                          final nombreAmigable = _nombreDireccionVisible(
                            direccion,
                          );
                          final isSelected =
                              seleccionTemporal?.id == direccion.id;

                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                seleccionTemporal = direccion;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? JPCupertinoColors.systemBlue(
                                        context,
                                      ).withValues(alpha: 0.1)
                                    : JPCupertinoColors.systemGrey6(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? JPCupertinoColors.systemBlue(context)
                                      : JPCupertinoColors.separator(context),
                                  width: isSelected ? 2 : 0.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? CupertinoIcons.checkmark_circle_fill
                                        : CupertinoIcons.circle,
                                    color: isSelected
                                        ? JPCupertinoColors.systemBlue(context)
                                        : JPCupertinoColors.systemGrey(context),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombreAmigable,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: JPCupertinoColors.label(
                                              context,
                                            ),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (direccion.etiqueta.isNotEmpty &&
                                            !_esPlaceholder(
                                              direccion.etiqueta,
                                            )) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.tag,
                                                size: 14,
                                                color:
                                                    JPCupertinoColors.secondaryLabel(
                                                      context,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  direccion.etiqueta,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        JPCupertinoColors.secondaryLabel(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (direccion.esPredeterminada) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  JPCupertinoColors.systemBlue(
                                                    context,
                                                  ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Predeterminada',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    JPCupertinoColors.systemBlue(
                                                      context,
                                                    ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Agregar nueva
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          // Cerrar el bottom sheet de direcciones guardadas
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          // Cerrar el bottom sheet de resumen de compra
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          // Luego navegar a agregar dirección
                          await _irAAgregarDireccion();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.add_circled,
                              color: JPCupertinoColors.systemBlue(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Agregar nueva dirección',
                              style: TextStyle(
                                color: JPCupertinoColors.systemBlue(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botones
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              color: JPCupertinoColors.systemGrey5(context),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: JPCupertinoColors.label(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              color: seleccionTemporal == null
                                  ? JPCupertinoColors.systemGrey4(context)
                                  : JPCupertinoColors.systemBlue(context),
                              onPressed: seleccionTemporal == null
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _aplicarDireccionGuardada(
                                        seleccionTemporal!,
                                        safeSetModalState,
                                        carritoProvider,
                                      );
                                    },
                              child: const Text(
                                'Seleccionar',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final carritoProvider = context.watch<ProveedorCarrito>();
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CarritoNavigationBar(
        estaVacio: carritoProvider.estaVacio,
        onLimpiar: () => _mostrarDialogoLimpiar(carritoProvider),
      ),
      child: Builder(
        builder: (context) {
          if (carritoProvider.loading) {
            return const CarritoLoadingState();
          }

          if (carritoProvider.estaVacio) {
            return const CarritoEmptyState();
          }

          return Stack(
            children: [
              _buildCarritoContent(carritoProvider),
              if (!carritoProvider.estaVacio)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CarritoBottomBar(
                    subtotalText: carritoProvider.totalFormateado,
                    loading: carritoProvider.loading,
                    onContinuar: () => _mostrarCheckout(carritoProvider),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCarritoContent(ProveedorCarrito carritoProvider) {
    return Column(
      children: [
        CarritoHeader(
          cantidadItems: carritoProvider.cantidadItems,
          cantidadTotal: carritoProvider.cantidadTotal,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: carritoProvider.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = carritoProvider.items[index];
              return ItemCarritoCard(
                item: item,
                onIncrement: () => carritoProvider.incrementarCantidad(item.id),
                onDecrement: () => carritoProvider.decrementarCantidad(item.id),
                onRemove: () => carritoProvider.removerProducto(item.id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoLimpiar(ProveedorCarrito carritoProvider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Limpiar Carrito'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los productos del carrito?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final success = await carritoProvider.limpiarCarrito();
              if (success && context.mounted) {
                ToastService().showSuccess(context, 'Carrito limpiado');
              }
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarCheckout(ProveedorCarrito carritoProvider) async {
    _metodoPago = 'efectivo';
    _cotizacionEnvio = null;

    if (_direccionesGuardadas.isEmpty) {
      await _cargarDireccionesGuardadas();
    }

    if (_cotizacionEnvio == null && _destLat != null && _destLng != null) {
      await _cotizarEnvioConDestino(
        _destLat!,
        _destLng!,
        (fn) => setState(fn),
        carritoProvider,
      );
    }

    if (!mounted) return;

    bool sheetMounted = true;
    final resultado = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void safeSetModalState(VoidCallback fn) {
              if (!sheetMounted) return;
              try {
                setModalState(fn);
              } catch (_) {}
            }

            final envio = _cotizacionEnvio != null
                ? double.tryParse(
                        _cotizacionEnvio!['total_envio'].toString(),
                      ) ??
                      0.0
                : 0.0;
            final subtotal = carritoProvider.total;
            final recargoMulti = _cotizacionEnvio != null
                ? double.tryParse(
                        _cotizacionEnvio!['recargo_multi_proveedor'].toString(),
                      ) ??
                      0.0
                : 0.0;
            final recargoNocturno = _recargoNocturno ?? 0.0;
            final total = subtotal + envio + recargoMulti + recargoNocturno;
            final direccionSeleccionada = _direccionSeleccionada;
            final tituloDireccion = direccionSeleccionada != null
                ? _nombreDireccionVisible(direccionSeleccionada)
                : '';
            final direccionCompleta =
                direccionSeleccionada != null &&
                    direccionSeleccionada.direccionCompleta.isNotEmpty &&
                    !_esPlaceholder(direccionSeleccionada.direccionCompleta)
                ? direccionSeleccionada.direccionCompleta
                : null;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: JPCupertinoColors.background(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: CarritoCheckoutContent(
                  items: carritoProvider.items,
                  subtotal: subtotal,
                  envio: envio,
                  recargoMulti: recargoMulti,
                  recargoNocturno: recargoNocturno,
                  total: total,
                  tieneDirecciones: _direccionesGuardadas.isNotEmpty,
                  onElegirDireccion: () => _mostrarSelectorDireccionesGuardadas(
                    safeSetModalState,
                    carritoProvider,
                  ),
                  onAgregarDireccion: _irAAgregarDireccion,
                  direccionSeleccionada: direccionSeleccionada,
                  direccionTitulo: tituloDireccion,
                  direccionCompleta: direccionCompleta,
                  mostrarInstrucciones: _mostrarInstrucciones,
                  instruccionesController: _instruccionesController,
                  metodoPago: _metodoPago,
                  onMetodoPagoChanged: (value) {
                    safeSetModalState(() => _metodoPago = value);
                  },
                  onConfirmar: () {
                    if (_direccionSeleccionada == null ||
                        _destLat == null ||
                        _destLng == null) {
                      ToastService().showWarning(
                        context,
                        'Selecciona o agrega una dirección para continuar',
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => sheetMounted = false);

    if (!mounted) return;
    if (resultado == true) {
      if (_destLat == null || _destLng == null) {
        final mensaje = _direccionesGuardadas.isEmpty
            ? 'No se encontró ninguna dirección guardada. Agrega una dirección en Ajustes para continuar.'
            : 'Debes seleccionar una ubicación en el mapa o elegir una dirección guardada.';

        ToastService().showWarning(
          context,
          mensaje,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      String direccion = _direccionController.text.trim();
      if (direccion.isEmpty) {
        direccion = await _obtenerDireccionLegible(_destLat!, _destLng!);
        _direccionController.text = direccion;
      }

      final response = await carritoProvider.checkout(
        direccionEntrega: direccion,
        metodoPago: _metodoPago,
        datosEnvio: _cotizacionEnvio,
        latitudDestino: _destLat,
        longitudDestino: _destLng,
        direccionId: _direccionSeleccionada?.id,
        instruccionesEntrega: _instruccionesController.text.trim(),
      );

      if (response != null && mounted) {
        ToastService().showSuccess(context, 'Pedido creado exitosamente');
      }
    }
  }

  Future<void> _cotizarEnvioConDestino(
    double latDestino,
    double lngDestino,
    void Function(void Function()) setModalState,
    ProveedorCarrito carritoProvider,
  ) async {
    _destLat = latDestino;
    _destLng = lngDestino;

    final proveedores = carritoProvider.items
        .map((e) => e.producto?.proveedorId)
        .where((id) => id != null)
        .toSet()
        .length;

    final origenLat =
        carritoProvider.items.first.producto?.proveedorLatitud ?? latDestino;
    final origenLng =
        carritoProvider.items.first.producto?.proveedorLongitud ?? lngDestino;

    final resp = await EnvioService().cotizarEnvio(
      latOrigen: origenLat,
      lngOrigen: origenLng,
      latDestino: latDestino,
      lngDestino: lngDestino,
      proveedores: proveedores == 0 ? 1 : proveedores,
    );

    setModalState(() {
      _cotizacionEnvio = resp;
    });
  }

  Future<String> _obtenerDireccionLegible(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final partes = <String>[
          if (p.street?.isNotEmpty == true) p.street!,
          if (p.subLocality?.isNotEmpty == true) p.subLocality!,
          if (p.locality?.isNotEmpty == true) p.locality!,
          if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
          if (p.country?.isNotEmpty == true) p.country!,
        ];
        if (partes.isNotEmpty) return partes.join(', ');
      }
    } catch (_) {}
    return 'Ubicación aproximada';
  }
}
