// lib/screens/supplier/screens/pantalla_promociones_proveedor.dart

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/products/producto_model.dart';
import '../../../models/products/promocion_model.dart';
import '../../../theme/app_colors_primary.dart';

class PantallaPromocionesProveedor extends StatelessWidget {
  const PantallaPromocionesProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Mis Promociones'),
      ),
      child: Consumer<SupplierController>(
        builder: (context, controller, _) {
          final promos = controller.promociones;
          if (promos.isEmpty) {
            return const Center(child: Text('Sin promociones'));
          }
          return Material(
            type: MaterialType.transparency,
            child: ListView.builder(
              itemCount: promos.length,
              itemBuilder: (_, i) => ListTile(title: Text(promos[i].titulo)),
            ),
          );
        },
      ),
    );
  }
}

// Helper público para reusar el formulario
Widget buildFormularioPromocion({PromocionModel? promo}) {
  return FormularioPromocion(promo: promo);
}

class FormularioPromocion extends StatefulWidget {
  final PromocionModel? promo;

  const FormularioPromocion({super.key, this.promo});

  @override
  State<FormularioPromocion> createState() => _FormularioPromocionState();
}

class _FormularioPromocionState extends State<FormularioPromocion> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _descuentoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Color _colorSeleccionado = const Color(0xFFE91E63);
  File? _imagenSeleccionada;
  bool _procesando = false;
  bool _activa = true;
  String? _errorFormulario;
  String _tipoSeleccionado = 'descuento';
  List<ProductoModel> _productosAsociados =
      []; // Lista de productos seleccionados

  static const List<Color> _opcionesColor = [
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFF009688), // Teal
    Color(0xFFFF9800), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF2196F3), // Blue
  ];

  @override
  void initState() {
    super.initState();
    if (widget.promo != null) {
      debugPrint('\n🎬 INICIANDO EDICIÓN DE PROMOCIÓN');
      debugPrint('   Título: ${widget.promo!.titulo}');
      debugPrint(
        '   IDs asociados en el modelo: ${widget.promo!.productosAsociadosIds}',
      );

      _tituloController.text = widget.promo!.titulo;
      _descripcionController.text = widget.promo!.descripcion;
      _descuentoController.text = widget.promo!.descuento;
      _activa = widget.promo!.activa;
      _colorSeleccionado = widget.promo!.color;

      // Cargar productos asociados (se cargará después de que el widget esté listo)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarProductosAsociados();
      });
    } else {
      debugPrint('\n🆕 CREANDO NUEVA PROMOCIÓN');
    }
  }

  /// Carga los productos asociados cuando se edita una promoción
  Future<void> _cargarProductosAsociados() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔄 CARGANDO PRODUCTOS ASOCIADOS');

    if (widget.promo == null) {
      debugPrint('widget.promo es null');
      return;
    }

    debugPrint('Promoción: ${widget.promo!.titulo}');
    debugPrint(
      'IDs de productos asociados: ${widget.promo!.productosAsociadosIds}',
    );
    debugPrint('Cantidad: ${widget.promo!.productosAsociadosIds.length}');

    if (widget.promo!.productosAsociadosIds.isEmpty) {
      debugPrint('La lista de productos asociados está vacía');
      return;
    }

    final controller = context.read<SupplierController>();

    // Asegurarse de que los productos están cargados
    if (controller.productos.isEmpty) {
      debugPrint('🔄 Cargando productos del proveedor...');
      await controller.refrescarProductos();
      debugPrint('✅ Productos cargados: ${controller.productos.length}');
    } else {
      debugPrint('✅ Productos ya cargados: ${controller.productos.length}');
    }

    // Debug: Mostrar todos los IDs disponibles
    final idsDisponibles = controller.productos
        .map((p) => p.id.toString())
        .toList();
    debugPrint('🔍 IDs de productos disponibles: $idsDisponibles');

    // Filtrar productos que están en la lista de IDs
    final productosSeleccionados = controller.productos.where((producto) {
      final match = widget.promo!.productosAsociadosIds.contains(
        producto.id.toString(),
      );
      if (match) {
        debugPrint('   ✅ Match: ${producto.nombre} (ID: ${producto.id})');
      }
      return match;
    }).toList();

    debugPrint('\n📊 Resultado:');
    debugPrint('   Total seleccionados: ${productosSeleccionados.length}');
    debugPrint(
      '   Productos: ${productosSeleccionados.map((p) => p.nombre).join(", ")}',
    );

    if (mounted) {
      setState(() {
        _productosAsociados = productosSeleccionados;
      });
      debugPrint(
        '✅ Estado actualizado con ${_productosAsociados.length} productos',
      );
    }

    debugPrint('═══════════════════════════════════════\n');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _descuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  widget.promo != null ? 'Editar Promoción' : 'Nueva Promoción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  onPressed: () => _mostrarGuiaPromociones(context),
                  minimumSize: Size(0, 0),
                  child: const Icon(
                    CupertinoIcons.info_circle,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.systemGrey3,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_errorFormulario != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorFormulario!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // Image picker (más grande para ver mejor la imagen)
                  Center(
                    child: GestureDetector(
                      onTap: _mostrarOpcionesImagen,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.systemGrey4.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _imagenSeleccionada != null
                              ? Image.file(
                                  _imagenSeleccionada!,
                                  fit: BoxFit.cover,
                                )
                              : widget.promo?.imagenUrl != null
                              ? Image.network(
                                  widget.promo!.imagenUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  CupertinoIcons.photo_on_rectangle,
                                  size: 36,
                                  color: CupertinoColors.systemGrey.resolveFrom(
                                    context,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form fields in grouped card
                  _buildGroupedCard(context, [
                    _buildTextField(
                      controller: _tituloController,
                      placeholder: 'Título de la promoción',
                    ),
                    _buildDivider(context),
                    _buildTextField(
                      controller: _descripcionController,
                      placeholder: 'Descripción',
                    ),
                    _buildDivider(context),
                    _buildTextField(
                      controller: _descuentoController,
                      placeholder: 'Texto destacado (ej. 20% OFF)',
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Type selector
                  _buildSectionHeader(context, 'TIPO DE PROMOCIÓN'),
                  _buildGroupedCard(context, [_buildTypeSelector()]),
                  const SizedBox(height: 16),

                  // Color selector
                  _buildSectionHeader(context, 'COLOR DEL BANNER'),
                  _buildGroupedCard(context, [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _opcionesColor.map((color) {
                          final isSelected =
                              _colorSeleccionado.toARGB32() == color.toARGB32();
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _colorSeleccionado = color),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      CupertinoIcons.checkmark,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Options
                  _buildGroupedCard(context, [
                    _buildSwitchRow(
                      context,
                      title: 'Promoción activa',
                      value: _activa,
                      onChanged: (v) => setState(() => _activa = v),
                    ),
                    _buildDivider(context),
                    _buildProductRow(context),
                  ]),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: _colorSeleccionado,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _procesando
                          ? null
                          : () => _guardarPromocion(context),
                      child: _procesando
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Guardar Promoción',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildGroupedCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(),
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _tipoSeleccionado,
        children: const {
          'descuento': Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('% OFF', style: TextStyle(fontSize: 13)),
          ),
          'envio': Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Envío', style: TextStyle(fontSize: 13)),
          ),
          '2x1': Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('2x1', style: TextStyle(fontSize: 13)),
          ),
        },
        onValueChanged: (value) {
          if (value != null) setState(() => _tipoSeleccionado = value);
        },
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColorsPrimary.main,
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context) {
    final textoDescripcion = _productosAsociados.isEmpty
        ? 'No seleccionado'
        : '${_productosAsociados.length} producto${_productosAsociados.length > 1 ? 's' : ''} seleccionado${_productosAsociados.length > 1 ? 's' : ''}';

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: () => _mostrarSelectorProducto(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productos asociados',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                Text(
                  textoDescripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                if (_productosAsociados.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _productosAsociados.map((p) => p.nombre).join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: CupertinoColors.systemGrey3.resolveFrom(context),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarPromocion(BuildContext context) async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      setState(() => _errorFormulario = 'El título es obligatorio');
      return;
    }
    final descripcion = _descripcionController.text.trim();
    final descuento = _descuentoController.text.trim();

    setState(() {
      _procesando = true;
      _errorFormulario = null;
    });

    final data = {
      'titulo': titulo,
      'descripcion': descripcion,
      'descuento': descuento,
      'color': '#${_colorHex(_colorSeleccionado)}',
      'activa': _activa ? 'true' : 'false',
      'tipo': _tipoSeleccionado,
      if (_productosAsociados.isNotEmpty)
        'productos_asociados': _productosAsociados
            .map((p) => int.parse(p.id.toString()))
            .toList(),
    };

    final controller = context.read<SupplierController>();

    bool ok;
    if (widget.promo != null) {
      // EDITAR promoción existente
      ok = await controller.editarPromocion(
        int.parse(widget.promo!.id),
        data,
        imagen: _imagenSeleccionada,
      );
    } else {
      // CREAR nueva promoción
      ok = await controller.crearPromocion(data, imagen: _imagenSeleccionada);
    }

    setState(() => _procesando = false);

    if (ok) {
      if (!context.mounted) return;
      Navigator.pop(context);
    } else if (controller.error != null) {
      setState(() => _errorFormulario = controller.error);
    }
  }

  Future<void> _mostrarOpcionesImagen() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _seleccionarImagen(ImageSource.gallery);
            },
            child: const Text('Elegir de Galería'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _seleccionarImagen(ImageSource.camera);
            },
            child: const Text('Tomar Foto'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() => _imagenSeleccionada = File(picked.path));
      }
    } catch (_) {
      setState(() => _errorFormulario = 'No se pudo cargar la imagen');
    }
  }

  Future<void> _mostrarSelectorProducto(BuildContext context) async {
    final controller = context.read<SupplierController>();

    // ✅ Cargar productos si no están cargados
    if (controller.productos.isEmpty) {
      await controller.refrescarProductos();
    }

    if (!context.mounted) return;

    // Crear copia temporal de la selección actual
    final productosTemporales = List<ProductoModel>.from(_productosAsociados);

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DefaultTextStyle(
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.label,
            decoration: TextDecoration.none,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seleccionar Productos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${productosTemporales.length} seleccionado${productosTemporales.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(30, 30),
                        onPressed: () {
                          // Actualizar la selección principal
                          setState(() {
                            _productosAsociados = productosTemporales;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Listo',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColorsPrimary.main,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: controller.productos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.cube_box,
                                size: 64,
                                color: CupertinoColors.systemGrey3.resolveFrom(
                                  context,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes productos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Crea productos primero para\npoder asociarlos a promociones',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      : Material(
                          type: MaterialType.transparency,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: controller.productos.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              indent: 16,
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            itemBuilder: (_, index) {
                              final prod = controller.productos[index];
                              final isSelected = productosTemporales.any(
                                (p) => p.id == prod.id,
                              );

                              return CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      // Deseleccionar
                                      productosTemporales.removeWhere(
                                        (p) => p.id == prod.id,
                                      );
                                    } else {
                                      // Seleccionar
                                      productosTemporales.add(prod);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  color: isSelected
                                      ? AppColorsPrimary.main.withValues(
                                          alpha: 0.1,
                                        )
                                      : null,
                                  child: Row(
                                    children: [
                                      // Imagen del producto
                                      if (prod.imagenUrl != null &&
                                          prod.imagenUrl!.isNotEmpty)
                                        Container(
                                          width: 50,
                                          height: 50,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                prod.imagenUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 50,
                                          height: 50,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey5
                                                .resolveFrom(context),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            CupertinoIcons.cube_box,
                                            color: CupertinoColors.systemGrey
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      // Información
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.nombre,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: CupertinoColors.label
                                                    .resolveFrom(context),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${prod.precio.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColorsPrimary.main,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Checkmark si está seleccionado
                                      if (isSelected)
                                        const Icon(
                                          CupertinoIcons.checkmark_circle_fill,
                                          color: AppColorsPrimary.main,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _colorHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return hex.substring(2);
  }

  void _mostrarGuiaPromociones(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📢 Guía de Promociones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGuideSection(
                        context,
                        icon: '🎯',
                        title: '¿Qué son las promociones?',
                        content:
                            'Las promociones te permiten destacar tus productos y atraer más clientes. Puedes ofrecer descuentos, envío gratis o combos especiales.',
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        context,
                        icon: '📝',
                        title: 'Paso 1: Información básica',
                        content:
                            '• Título: Nombre atractivo para tu promoción (ej: "¡Oferta de Verano!")\n• Descripción: Explica los beneficios de la promoción\n• Texto destacado: Lo que verán los clientes (ej: "20% OFF", "2x1")',
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        context,
                        icon: '🏷️',
                        title: 'Paso 2: Tipo de promoción',
                        content:
                            '• % OFF: Descuento porcentual en productos\n• Envío: Envío gratis o con descuento\n• 2x1: Compra uno y llévate otro gratis',
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        context,
                        icon: '🎨',
                        title: 'Paso 3: Personalización',
                        content:
                            '• Color del banner: Elige un color llamativo que combine con tu marca\n• Imagen: Agrega una foto atractiva de tu producto o promoción',
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        context,
                        icon: '📦',
                        title: 'Paso 4: Producto asociado',
                        content:
                            'Vincula la promoción a un producto específico de tu catálogo. Los clientes podrán ver la promoción directamente en ese producto.',
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        context,
                        icon: '✅',
                        title: 'Paso 5: Activar',
                        content:
                            'Activa la promoción para que sea visible inmediatamente, o déjala pausada para publicarla después.',
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        context,
                        icon: '💡',
                        title: 'Consejos para promociones exitosas',
                        content:
                            '• Usa títulos cortos y llamativos\n• Incluye el descuento en el texto destacado\n• Usa imágenes de alta calidad\n• Limita la duración para crear urgencia\n• Promociona tus mejores productos',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(
    BuildContext context, {
    required String icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
