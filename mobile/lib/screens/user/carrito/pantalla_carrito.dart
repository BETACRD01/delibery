// lib/screens/user/carrito/pantalla_carrito.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../theme/jp_theme.dart';
import '../../../providers/proveedor_carrito.dart';
import '../../../services/envio_service.dart';
import '../../../services/usuarios_service.dart';
import '../../../models/usuario.dart';

/// Pantalla del carrito de compras
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
  String? _errorEnvio;
  String? _infoEnvio;
  double? get _recargoNocturno {
    final valor = _cotizacionEnvio?['recargo_nocturno'];
    if (valor == null) return null;
    return double.tryParse(valor.toString());
  }

  bool _mostrarInstrucciones = false;
  String? _errorDireccionManual;
  static const _googlePlacesApiKey = "AIzaSyAVomIe-K4kpGMrQTc-bZaNcBvJtkK-KBA";

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
        _direccionSeleccionada = direcciones.firstWhere(
          (d) => d.esPredeterminada,
          orElse: () =>
              direcciones.isNotEmpty ? direcciones.first : throw Exception(),
        );

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
      _errorDireccionManual = null;
      _errorEnvio = null;
      _infoEnvio = null;
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

  Future<void> _handlePredictionSelection(
    Prediction prediction,
    void Function(void Function()) safeSetModalState,
    ProveedorCarrito carritoProvider,
  ) async {
    final descripcion = prediction.description;
    if (descripcion == null || descripcion.isEmpty) return;

    safeSetModalState(() {
      _direccionSeleccionada = null;
      _errorDireccionManual = null;
      _direccionController.text = descripcion;
      _direccionController.selection = TextSelection.fromPosition(
        TextPosition(offset: descripcion.length),
      );
    });

    try {
      final ubicaciones = await locationFromAddress(descripcion);
      if (ubicaciones.isNotEmpty) {
        await _cotizarEnvioConDestino(
          ubicaciones.first.latitude,
          ubicaciones.first.longitude,
          safeSetModalState,
          carritoProvider,
        );
      }
    } catch (e) {
      safeSetModalState(() {
        _errorDireccionManual = 'No se pudo ubicar la dirección seleccionada.';
      });
    }
  }

  Widget _buildCampoDireccionConAutocompletado(
    void Function(void Function()) safeSetModalState,
    ProveedorCarrito carritoProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GooglePlaceAutoCompleteTextField(
          textEditingController: _direccionController,
          googleAPIKey: _googlePlacesApiKey,
          debounceTime: 300,
          countries: const ["ec"],
          isLatLngRequired: true,
          inputDecoration: InputDecoration(
            hintText: 'Ej. Av. Amazonas y 10 de Agosto',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: JPColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            suffixIcon: _direccionController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      safeSetModalState(() {
                        _direccionController.clear();
                        _destLat = null;
                        _destLng = null;
                      });
                    },
                  )
                : null,
          ),
          textStyle: const TextStyle(fontSize: 14),
          itemBuilder: (context, index, Prediction prediction) {
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.place,
                color: JPColors.primary,
                size: 18,
              ),
              title: Text(
                prediction.description ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
          seperatedBuilder: const Divider(height: 1),
          itemClick: (Prediction prediction) {
            _direccionController.text = prediction.description ?? '';
            _direccionController.selection = TextSelection.fromPosition(
              TextPosition(offset: _direccionController.text.length),
            );
            safeSetModalState(() {
              _direccionSeleccionada = null;
            });
          },
          getPlaceDetailWithLatLng: (Prediction prediction) async {
            await _handlePredictionSelection(
              prediction,
              safeSetModalState,
              carritoProvider,
            );
          },
          isCrossBtnShown: false,
          containerHorizontalPadding: 0,
        ),
      ],
    );
  }

  Future<void> _mostrarSelectorDireccionesGuardadas(
    void Function(void Function()) safeSetModalState,
    ProveedorCarrito carritoProvider,
  ) async {
    if (_direccionesGuardadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aún no tienes direcciones guardadas'),
          backgroundColor: JPColors.warning,
        ),
      );
      return;
    }

    DireccionModel? seleccionTemporal = _direccionSeleccionada;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de arrastre
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Título
                  const Text(
                    'Mis direcciones guardadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: JPColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lista de direcciones
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _direccionesGuardadas.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final direccion = _direccionesGuardadas[index];
                        final estaSeleccionada =
                            seleccionTemporal?.id == direccion.id;

                        return CheckboxListTile(
                          value: estaSeleccionada,
                          activeColor: JPColors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: Text(
                            direccion.direccionCompleta,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (direccion.etiqueta.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.label_outline,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      direccion.etiqueta,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
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
                                    color: JPColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Predeterminada',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: JPColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onChanged: (_) {
                            setSheetState(() {
                              seleccionTemporal = direccion;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JPColors.primary,
                        ),
                        child: const Text(
                          'Seleccionar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: _buildAppBar(),
      body: Consumer<ProveedorCarrito>(
        builder: (context, carritoProvider, _) {
          if (carritoProvider.loading) {
            return _buildLoadingState();
          }

          if (carritoProvider.estaVacio) {
            return _buildEmptyState();
          }

          return _buildCarritoContent(carritoProvider);
        },
      ),
      bottomNavigationBar: Consumer<ProveedorCarrito>(
        builder: (context, carritoProvider, _) {
          if (carritoProvider.estaVacio) return const SizedBox.shrink();
          return _buildBottomBar(carritoProvider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mi Carrito'),
      backgroundColor: Colors.white,
      foregroundColor: JPColors.textPrimary,
      elevation: 0,
      actions: [
        Consumer<ProveedorCarrito>(
          builder: (context, carritoProvider, _) {
            if (carritoProvider.estaVacio) return const SizedBox.shrink();

            return IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _mostrarDialogoLimpiar(carritoProvider),
              tooltip: 'Limpiar carrito',
            );
          },
        ),
      ],
    );
  }

  Widget _buildCarritoContent(ProveedorCarrito carritoProvider) {
    return Column(
      children: [
        _buildHeader(carritoProvider),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: carritoProvider.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = carritoProvider.items[index];
              return _ItemCarritoCard(
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

  Widget _buildHeader(ProveedorCarrito carritoProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: JPColors.primary),
          const SizedBox(width: 12),
          Text(
            '${carritoProvider.cantidadItems} productos',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: JPColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '${carritoProvider.cantidadTotal} items',
            style: const TextStyle(fontSize: 14, color: JPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProveedorCarrito carritoProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(fontSize: 16, color: JPColors.textSecondary),
                ),
                Text(
                  carritoProvider.totalFormateado,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: JPColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: carritoProvider.loading
                    ? null
                    : () => _mostrarCheckout(carritoProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JPColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuar al Pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: JPColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: JPColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: JPColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoLimpiar(ProveedorCarrito carritoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Carrito'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los productos del carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await carritoProvider.limpiarCarrito();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Carrito limpiado'),
                    backgroundColor: JPColors.success,
                  ),
                );
              }
            },
            child: const Text(
              'Limpiar',
              style: TextStyle(color: JPColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarCheckout(ProveedorCarrito carritoProvider) async {
    _metodoPago = 'efectivo';
    _cotizacionEnvio = null;
    _errorEnvio = null;
    _infoEnvio = null;

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
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Text(
                      'Resumen de compra',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: JPColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              itemCount: carritoProvider.items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final item = carritoProvider.items[index];
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: JPColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'x${item.cantidad}',
                                      style: const TextStyle(
                                        color: JPColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // SECCIÓN DE DIRECCIÓN MEJORADA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dirección de entrega',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: JPColors.textPrimary,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _mostrarSelectorDireccionesGuardadas(
                                      safeSetModalState,
                                      carritoProvider,
                                    ),
                                icon: const Icon(
                                  Icons.bookmark_border,
                                  size: 16,
                                ),
                                label: const Text('Elegir dirección'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  side: const BorderSide(
                                    color: JPColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildCampoDireccionConAutocompletado(
                            safeSetModalState,
                            carritoProvider,
                          ),
                          if (_errorDireccionManual != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _errorDireccionManual!,
                                style: const TextStyle(
                                  color: JPColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_errorEnvio != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _errorEnvio!,
                                style: const TextStyle(
                                  color: JPColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_infoEnvio != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: JPColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _infoEnvio!,
                                    style: const TextStyle(
                                      color: JPColors.success,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_mostrarInstrucciones) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instrucciones de entrega',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: JPColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _instruccionesController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              minLines: 1,
                              maxLines: 3,
                              onChanged: (_) => safeSetModalState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Método de pago',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: JPColors.textPrimary,
                            ),
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'efectivo',
                                label: Text('Efectivo'),
                                icon: Icon(Icons.payments_outlined),
                              ),
                              ButtonSegment(
                                value: 'transferencia',
                                label: Text('Transferencia'),
                                icon: Icon(Icons.account_balance_outlined),
                              ),
                            ],
                            selected: {_metodoPago},
                            onSelectionChanged: (v) {
                              if (v.isNotEmpty) {
                                safeSetModalState(() => _metodoPago = v.first);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: JPColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _ResumenRow(
                            label: 'Subtotal productos',
                            value: subtotal,
                          ),
                          _ResumenRow(label: 'Envío', value: envio),
                          if (recargoNocturno > 0)
                            _ResumenRow(
                              label: 'Recargo nocturno',
                              value: recargoNocturno,
                            ),
                          if (recargoMulti > 0)
                            _ResumenRow(
                              label: 'Recargo multi-proveedor',
                              value: recargoMulti,
                            ),
                          const Divider(),
                          _ResumenRow(
                            label: 'Total a pagar',
                            value: total,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JPColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirmar pedido',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            duration: const Duration(seconds: 4),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido creado exitosamente'),
            backgroundColor: JPColors.success,
          ),
        );
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
      _infoEnvio = 'Envío calculado automáticamente';
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

// ═══════════════════════════════════════════════════════════════════
// RESUMEN Y ITEM DEL CARRITO
// ═══════════════════════════════════════════════════════════════════

class _ResumenRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _ResumenRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: JPColors.textPrimary,
              ),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: JPColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET DE ITEM DEL CARRITO
// ═══════════════════════════════════════════════════════════════════

class _ItemCarritoCard extends StatefulWidget {
  final ItemCarrito item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _ItemCarritoCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  State<_ItemCarritoCard> createState() => _ItemCarritoCardState();
}

class _ItemCarritoCardState extends State<_ItemCarritoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.item.esPromocion) {
      return _buildPromocionCard();
    }
    return _buildProductoCard();
  }

  Widget _buildPromocionCard() {
    final promocion = widget.item.promocion!;
    final productosIncluidos = widget.item.productosIncluidos ?? [];

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JPColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: JPColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildPromocionImage(promocion),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: JPColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    promocion.descuento,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promocion.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: JPColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${productosIncluidos.length} productos incluidos',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${widget.item.precioUnitario.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: JPColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildQuantityControls(),
                                const Spacer(),
                                Text(
                                  '\$${widget.item.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: JPColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: JPColors.primary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onRemove,
                  color: Colors.grey[400],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded && productosIncluidos.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                color: JPColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Text(
                      'Productos incluidos:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  ...productosIncluidos.map((producto) {
                    return _buildProductoIncluido(producto);
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductoIncluido(producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 40,
              height: 40,
              color: Colors.grey[100],
              child:
                  producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: producto.imagenUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: JPColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.fastfood_outlined,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.fastfood_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: JPColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${producto.precio.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            onPressed: () => _mostrarDialogoEliminarProducto(producto),
            color: Colors.red[400],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminarProducto(producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Deseas eliminar "${producto.nombre}" de esta promoción?\n\nNota: La promoción completa permanecerá en el carrito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${producto.nombre} eliminado'),
                  backgroundColor: JPColors.success,
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: JPColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromocionImage(promocion) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: JPColors.background,
        child: promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: promocion.imagenUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: JPColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: Icon(
                    Icons.local_offer_outlined,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                ),
              )
            : Container(
                color: Colors.grey[100],
                child: Icon(
                  Icons.local_offer_outlined,
                  color: Colors.grey[400],
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildProductoCard() {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildImage(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.producto!.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: JPColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildProveedorBadge(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${widget.item.precioUnitario.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: JPColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'c/u',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildQuantityControls(),
                          const Spacer(),
                          Text(
                            '\$${widget.item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: JPColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onRemove,
              color: Colors.grey[400],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: JPColors.background,
        child:
            widget.item.producto!.imagenUrl != null &&
                widget.item.producto!.imagenUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.item.producto!.imagenUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: JPColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: Icon(
                    Icons.fastfood_outlined,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                ),
              )
            : Container(
                color: Colors.grey[100],
                child: Icon(
                  Icons.fastfood_outlined,
                  color: Colors.grey[400],
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildProveedorBadge() {
    final logo = widget.item.producto?.proveedorLogoUrl;
    final nombre = widget.item.producto?.proveedorNombre;
    if ((logo == null || logo.isEmpty) && (nombre == null || nombre.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey[200],
          backgroundImage: (logo != null && logo.isNotEmpty)
              ? NetworkImage(logo)
              : null,
          child: (logo == null || logo.isEmpty)
              ? const Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: Colors.grey,
                )
              : null,
        ),
        if (nombre != null && nombre.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nombre,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: JPColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onDecrement,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.remove,
                  size: 18,
                  color: widget.item.cantidad > 1
                      ? JPColors.primary
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${widget.item.cantidad}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: JPColors.textPrimary,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onIncrement,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.add, size: 18, color: JPColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
