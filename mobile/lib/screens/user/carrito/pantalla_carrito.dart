// lib/screens/user/carrito/pantalla_carrito.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, NetworkImage, Divider;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geocoding/geocoding.dart';
import '../../../theme/jp_theme.dart';
import '../../../providers/proveedor_carrito.dart';
import '../../../services/envio_service.dart';
import '../../../services/usuarios_service.dart';
import '../../../models/usuario.dart';
import '../../../services/toast_service.dart';
import '../../user/perfil/configuracion/direcciones/pantalla_mis_direcciones.dart';

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

  Widget _buildCardDireccionSeleccionada() {
    final dir = _direccionSeleccionada!;
    final titulo = _nombreDireccionVisible(dir);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.location_solid,
              color: JPCupertinoColors.systemBlue(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: JPCupertinoColors.label(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dir.direccionCompleta.isNotEmpty &&
                    !_esPlaceholder(dir.direccionCompleta)) ...[
                  const SizedBox(height: 2),
                  Text(
                    dir.direccionCompleta,
                    style: TextStyle(
                      fontSize: 13,
                      color: JPCupertinoColors.secondaryLabel(context),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (dir.esPredeterminada) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Predeterminada',
                      style: TextStyle(
                        fontSize: 10,
                        color: JPCupertinoColors.systemBlue(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
        _direccionSeleccionada = direcciones.where((d) => d.esPredeterminada).fold<
                DireccionModel?>(
            null, (prev, curr) => curr)
          ??
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final direccion = _direccionesGuardadas[index];
                          final nombreAmigable = _nombreDireccionVisible(direccion);
                          final isSelected = seleccionTemporal?.id == direccion.id;

                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                seleccionTemporal = direccion;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1)
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombreAmigable,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: JPCupertinoColors.label(context),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (direccion.etiqueta.isNotEmpty &&
                                            !_esPlaceholder(direccion.etiqueta)) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.tag,
                                                size: 14,
                                                color: JPCupertinoColors.secondaryLabel(context),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                direccion.etiqueta,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: JPCupertinoColors.secondaryLabel(context),
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
                                              color: JPCupertinoColors.systemBlue(context)
                                                  .withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Predeterminada',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: JPCupertinoColors.systemBlue(context),
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
                          await _irAAgregarDireccion();
                          await _cargarDireccionesGuardadas();
                          setSheetState(() {
                            seleccionTemporal = _direccionSeleccionada;
                          });
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
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
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
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: _buildNavigationBar(),
      child: Consumer<ProveedorCarrito>(
        builder: (context, carritoProvider, _) {
          if (carritoProvider.loading) {
            return _buildLoadingState();
          }

          if (carritoProvider.estaVacio) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              _buildCarritoContent(carritoProvider),
              if (!carritoProvider.estaVacio)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomBar(carritoProvider),
                ),
            ],
          );
        },
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: JPCupertinoColors.surface(context),
      middle: const Text('Mi Carrito'),
      trailing: Consumer<ProveedorCarrito>(
        builder: (context, carritoProvider, _) {
          if (carritoProvider.estaVacio) return const SizedBox.shrink();

          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _mostrarDialogoLimpiar(carritoProvider),
            child: Icon(
              CupertinoIcons.trash,
              color: JPCupertinoColors.systemRed(context),
            ),
          );
        },
      ),
      border: Border(
        bottom: BorderSide(
          color: JPCupertinoColors.separator(context),
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildCarritoContent(ProveedorCarrito carritoProvider) {
    return Column(
      children: [
        _buildHeader(carritoProvider),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.cart_fill,
            color: JPCupertinoColors.systemBlue(context),
          ),
          const SizedBox(width: 12),
          Text(
            '${carritoProvider.cantidadItems} productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: JPCupertinoColors.label(context),
            ),
          ),
          const Spacer(),
          Text(
            '${carritoProvider.cantidadTotal} items',
            style: TextStyle(
              fontSize: 14,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProveedorCarrito carritoProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 16,
                    color: JPCupertinoColors.secondaryLabel(context),
                  ),
                ),
                Text(
                  carritoProvider.totalFormateado,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: JPCupertinoColors.label(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: carritoProvider.loading
                    ? null
                    : () => _mostrarCheckout(carritoProvider),
                child: const Text(
                  'Continuar al Pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
    return Center(
      child: CupertinoActivityIndicator(
        radius: 14,
        color: JPCupertinoColors.systemGrey(context),
      ),
    );
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
                color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.cart,
                size: 80,
                color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.label(context),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
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

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: JPCupertinoColors.background(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    Text(
                      'Resumen de compra',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: JPCupertinoColors.label(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contenido scrollable
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Productos
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: JPCupertinoColors.surface(context),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: JPConstants.cardShadow(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Productos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: JPCupertinoColors.label(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 160,
                                  child: ListView.separated(
                                    itemCount: carritoProvider.items.length,
                                    separatorBuilder: (_, __) =>
                                        Divider(
                                          height: 12,
                                          color: JPCupertinoColors.separator(context),
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = carritoProvider.items[index];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.nombre,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: JPCupertinoColors.label(context),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'x${item.cantidad}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: JPCupertinoColors.secondaryLabel(context),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '\$${item.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
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

                          // Botón de dirección
                          Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: () => _direccionesGuardadas.isNotEmpty
                                  ? _mostrarSelectorDireccionesGuardadas(
                                      safeSetModalState,
                                      carritoProvider,
                                    )
                                  : _irAAgregarDireccion(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.location,
                                    size: 16,
                                    color: JPCupertinoColors.systemBlue(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _direccionesGuardadas.isNotEmpty
                                        ? 'Elegir dirección'
                                        : 'Agregar dirección',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: JPCupertinoColors.systemBlue(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Dirección seleccionada
                          if (_direccionSeleccionada != null)
                            _buildCardDireccionSeleccionada(),
                          if (_direccionSeleccionada != null)
                            const SizedBox(height: 12),

                          // Instrucciones
                          if (_mostrarInstrucciones) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: JPCupertinoColors.surface(context),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: JPConstants.cardShadow(context),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instrucciones de entrega',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: JPCupertinoColors.label(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CupertinoTextField(
                                    controller: _instruccionesController,
                                    placeholder: 'Ej: Tocar el timbre',
                                    style: const TextStyle(fontSize: 13),
                                    placeholderStyle: TextStyle(
                                      fontSize: 13,
                                      color: JPCupertinoColors.systemGrey(context),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: JPCupertinoColors.systemGrey6(context),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minLines: 2,
                                    maxLines: 3,
                                    onChanged: (_) => safeSetModalState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Método de pago
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: JPCupertinoColors.surface(context),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: JPConstants.cardShadow(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Método de pago',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: JPCupertinoColors.label(context),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CupertinoSlidingSegmentedControl<String>(
                                  groupValue: _metodoPago,
                                  children: const {
                                    'efectivo': Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.money_dollar, size: 14),
                                          SizedBox(width: 4),
                                          Text('Efectivo', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    'transferencia': Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.money_dollar_circle, size: 14),
                                          SizedBox(width: 4),
                                          Text('Transferencia', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  },
                                  onValueChanged: (value) {
                                    if (value != null) {
                                      safeSetModalState(() => _metodoPago = value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Resumen
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: JPCupertinoColors.systemGrey6(context),
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
                                Divider(
                                  height: 20,
                                  color: JPCupertinoColors.separator(context),
                                ),
                                _ResumenRow(
                                  label: 'Total a pagar',
                                  value: total,
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Botón confirmar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          onPressed: () {
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
                          child: const Text(
                            'Confirmar pedido',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

        ToastService().showWarning(context, mensaje, duration: const Duration(seconds: 4));
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
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: JPCupertinoColors.label(context),
              ),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: JPCupertinoColors.label(context),
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
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                color: JPCupertinoColors.systemBlue(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.tag_fill,
                                    size: 12,
                                    color: CupertinoColors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    promocion.descuento,
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              promocion.titulo,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: JPCupertinoColors.label(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${productosIncluidos.length} productos incluidos',
                              style: TextStyle(
                                fontSize: 13,
                                color: JPCupertinoColors.secondaryLabel(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${widget.item.precioUnitario.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: JPCupertinoColors.systemBlue(context),
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: JPCupertinoColors.label(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        color: JPCupertinoColors.systemBlue(context),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  onPressed: widget.onRemove,
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 24,
                    color: JPCupertinoColors.systemGrey3(context),
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded && productosIncluidos.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: const BorderRadius.only(
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
                        color: JPCupertinoColors.secondaryLabel(context),
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
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: JPCupertinoColors.separator(context),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 40,
              height: 40,
              color: JPCupertinoColors.systemGrey6(context),
              child:
                  producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: producto.imagenUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CupertinoActivityIndicator(
                          radius: 8,
                          color: JPCupertinoColors.systemGrey(context),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        CupertinoIcons.cube_box,
                        color: JPCupertinoColors.systemGrey3(context),
                        size: 20,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.cube_box,
                      color: JPCupertinoColors.systemGrey3(context),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: JPCupertinoColors.label(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${producto.precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: JPCupertinoColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            onPressed: () => _mostrarDialogoEliminarProducto(producto),
            child: Icon(
              CupertinoIcons.minus_circle,
              size: 24,
              color: JPCupertinoColors.systemRed(context),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminarProducto(producto) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Deseas eliminar "${producto.nombre}" de esta promoción?\n\nNota: La promoción completa permanecerá en el carrito.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ToastService().showSuccess(context, '${producto.nombre} eliminado');
            },
            child: const Text('Eliminar'),
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
        color: JPCupertinoColors.systemGrey6(context),
        child: promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: promocion.imagenUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CupertinoActivityIndicator(
                    radius: 10,
                    color: JPCupertinoColors.systemGrey(context),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  CupertinoIcons.tag,
                  color: JPCupertinoColors.systemGrey3(context),
                  size: 32,
                ),
              )
            : Icon(
                CupertinoIcons.tag,
                color: JPCupertinoColors.systemGrey3(context),
                size: 32,
              ),
      ),
    );
  }

  Widget _buildProductoCard() {
    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: JPCupertinoColors.separator(context),
        ),
        boxShadow: JPConstants.cardShadow(context),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: JPCupertinoColors.label(context),
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
                            style: TextStyle(
                              fontSize: 15,
                              color: JPCupertinoColors.systemBlue(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'c/u',
                            style: TextStyle(
                              fontSize: 12,
                              color: JPCupertinoColors.secondaryLabel(context),
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: JPCupertinoColors.label(context),
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
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: widget.onRemove,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 24,
                color: JPCupertinoColors.systemGrey3(context),
              ),
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
        color: JPCupertinoColors.systemGrey6(context),
        child:
            widget.item.producto!.imagenUrl != null &&
                widget.item.producto!.imagenUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.item.producto!.imagenUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CupertinoActivityIndicator(
                    radius: 10,
                    color: JPCupertinoColors.systemGrey(context),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  CupertinoIcons.cube_box,
                  color: JPCupertinoColors.systemGrey3(context),
                  size: 32,
                ),
              )
            : Icon(
                CupertinoIcons.cube_box,
                color: JPCupertinoColors.systemGrey3(context),
                size: 32,
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
          backgroundColor: JPCupertinoColors.systemGrey5(context),
          backgroundImage: (logo != null && logo.isNotEmpty)
              ? NetworkImage(logo)
              : null,
          child: (logo == null || logo.isEmpty)
              ? Icon(
                  CupertinoIcons.building_2_fill,
                  size: 14,
                  color: JPCupertinoColors.systemGrey(context),
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
                color: JPCupertinoColors.secondaryLabel(context),
                fontWeight: FontWeight.w500,
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
        color: JPCupertinoColors.systemGrey6(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: JPCupertinoColors.separator(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            minimumSize: Size.zero,
            onPressed: widget.onDecrement,
            child: Icon(
              CupertinoIcons.minus,
              size: 18,
              color: widget.item.cantidad > 1
                  ? JPCupertinoColors.systemBlue(context)
                  : JPCupertinoColors.systemGrey3(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${widget.item.cantidad}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: JPCupertinoColors.label(context),
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            minimumSize: Size.zero,
            onPressed: widget.onIncrement,
            child: Icon(
              CupertinoIcons.plus,
              size: 18,
              color: JPCupertinoColors.systemBlue(context),
            ),
          ),
        ],
      ),
    );
  }
}
