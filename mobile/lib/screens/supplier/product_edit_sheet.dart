import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/categoria_model.dart';
import '../../models/producto_model.dart';
import '../../services/productos/productos_service.dart';
import '../../theme/app_colors_primary.dart';
import '../../theme/app_colors_support.dart';

class ProductEditSheet extends StatefulWidget {
  final ProductoModel? producto;
  const ProductEditSheet({super.key, this.producto});

  @override
  State<ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends State<ProductEditSheet> {
  // Configuración de Colores Estilo iOS
  static const Color _bgObscuro = Color(
    0xFFF2F2F7,
  ); // System Grouped Background
  static const Color _blanco = Colors.white;
  // Se usan colores del tema en lugar de hardcoded

  // Controladores
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _precioAntCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imagenUrlCtrl = TextEditingController();

  // Estado
  bool _disponible = true;
  bool _destacado = false;
  bool _tieneStock = false;

  // 0 = Subir Foto, 1 = URL
  int _tipoImagen = 0;

  File? _imagenSeleccionada;
  CategoriaModel? _categoriaSeleccionada;
  bool _guardando = false;
  String? _error;

  final ProductosService _service = ProductosService();
  final ImagePicker _picker = ImagePicker();

  // Listas
  List<CategoriaModel> _categoriasDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    _cargarCategorias();
  }

  void _cargarDatosIniciales() {
    final p = widget.producto;
    if (p != null) {
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion;
      _precioCtrl.text = p.precio.toStringAsFixed(2);
      if (p.precioAnterior != null) {
        _precioAntCtrl.text = p.precioAnterior!.toStringAsFixed(2);
      }
      _disponible = p.disponible;
      _destacado = p.destacado;
      _tieneStock = p.tieneStock ?? false;
      if (_tieneStock) {
        _stockCtrl.text = (p.stock ?? 0).toString();
      }

      if (p.imagenUrl != null && p.imagenUrl!.startsWith('http')) {
        _imagenUrlCtrl.text = p.imagenUrl!;
        if (p.imagenUrl!.isEmpty) {
          _tipoImagen = 1;
        }
      }
    }
  }

  Future<void> _cargarCategorias() async {
    final cats = await _service.getCategorias();
    if (!mounted) return;
    setState(() {
      _categoriasDisponibles = cats;
      if (widget.producto != null) {
        try {
          _categoriaSeleccionada = cats.firstWhere(
            (c) => c.id == widget.producto!.categoriaId,
          );
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _precioAntCtrl.dispose();
    _stockCtrl.dispose();
    _imagenUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el padding superior del sistema (notch, status bar)
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          color: _bgObscuro,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _buildNavBar(context, topPadding),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildImageSection(),
                  _buildInfoSection(),
                  _buildPriceSection(),
                  _buildStockSection(),
                  if (_error != null) _buildErrorMessage(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, double topPadding) {
    return Container(
      decoration: BoxDecoration(
        color: _blanco,
        border: const Border(
          bottom: BorderSide(color: Colors.black12, width: 0.5),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle (indicador visual de bottom sheet)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Barra de navegación
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: Row(
              children: [
                // Botón Cancelar
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AppColorsPrimary.main,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Título centrado
                Expanded(
                  child: Text(
                    widget.producto != null
                        ? 'Editar Producto'
                        : 'Nuevo Producto',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Botón Guardar o Loader
                if (_guardando)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoActivityIndicator(),
                  )
                else
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    onPressed: _guardar,
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                        color: AppColorsPrimary.main,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              thumbColor: _blanco,
              children: const {0: Text('Subir Foto'), 1: Text('Enlace URL')},
              groupValue: _tipoImagen,
              onValueChanged: (v) => setState(() => _tipoImagen = v ?? 0),
            ),
          ),
        ),
        if (_tipoImagen == 0)
          GestureDetector(
            onTap: _mostrarOpcionesImagen,
            child: Container(
              height: 150,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imagenSeleccionada != null
                    ? Image.file(_imagenSeleccionada!, fit: BoxFit.cover)
                    : widget.producto?.imagenUrl != null &&
                          _imagenUrlCtrl.text.isEmpty
                    ? Image.network(
                        widget.producto!.imagenUrl!,
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            CupertinoIcons.camera_fill,
                            size: 40,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Toca para añadir foto',
                            style: TextStyle(color: AppColorsPrimary.main),
                          ),
                        ],
                      ),
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoTextField(
              controller: _imagenUrlCtrl,
              placeholder: 'https://ejemplo.com/imagen.jpg',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

        if (_tipoImagen == 1 && _imagenUrlCtrl.text.isNotEmpty)
          Container(
            height: 150,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                _imagenUrlCtrl.text,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),

        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 20),
          child: Text(
            'Imagen principal del producto',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('INFORMACIÓN BÁSICA'),
      children: [
        CupertinoTextFormFieldRow(
          controller: _nombreCtrl,
          placeholder: 'Nombre del producto',
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        CupertinoTextFormFieldRow(
          controller: _descCtrl,
          placeholder: 'Descripción',
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          maxLines: 3,
        ),
        GestureDetector(
          onTap: _mostrarSelectorCategorias,
          child: Container(
            color: _blanco,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Categoría', style: TextStyle(fontSize: 17)),
                Row(
                  children: [
                    Text(
                      _categoriaSeleccionada?.nombre ?? 'Seleccionar',
                      style: TextStyle(
                        color: _categoriaSeleccionada != null
                            ? Colors.black
                            : Colors.grey,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _blanco,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Destacado', style: TextStyle(fontSize: 17)),
              CupertinoSwitch(
                value: _destacado,
                onChanged: (v) => setState(() => _destacado = v),
                activeTrackColor: Colors.amber,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    double? precio = double.tryParse(_precioCtrl.text);
    double? anterior = double.tryParse(_precioAntCtrl.text);
    int? descuento;
    if (precio != null && anterior != null && anterior > precio) {
      descuento = ((anterior - precio) / anterior * 100).round();
    }

    return CupertinoFormSection.insetGrouped(
      header: const Text('PRECIOS Y OFERTAS'),
      footer: const Text(
        'Si añades un precio anterior mayor al actual, se mostrará como una oferta automáticamente.',
      ),
      children: [
        CupertinoTextFormFieldRow(
          controller: _precioCtrl,
          prefix: const Text('Precio', style: TextStyle(fontSize: 17)),
          placeholder: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.end,
          onChanged: (_) => setState(() {}),
        ),
        CupertinoTextFormFieldRow(
          controller: _precioAntCtrl,
          prefix: const Text('Precio Anterior', style: TextStyle(fontSize: 17)),
          placeholder: 'Opcional',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.end,
          onChanged: (_) => setState(() {}),
        ),
        if (descuento != null && descuento > 0)
          Container(
            color: _blanco,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Descuento calculado',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$descuento% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStockSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('INVENTARIO'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Disponible para venta',
                style: TextStyle(fontSize: 17),
              ),
              CupertinoSwitch(
                value: _disponible,
                onChanged: (v) => setState(() => _disponible = v),
                activeTrackColor: AppColorsPrimary.main,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Controlar Stock', style: TextStyle(fontSize: 17)),
              CupertinoSwitch(
                value: _tieneStock,
                onChanged: (v) => setState(() => _tieneStock = v),
                activeTrackColor: AppColorsPrimary.main,
              ),
            ],
          ),
        ),
        if (_tieneStock)
          CupertinoTextFormFieldRow(
            controller: _stockCtrl,
            prefix: const Text(
              'Cantidad en Stock',
              style: TextStyle(fontSize: 17),
            ),
            placeholder: '0',
            keyboardType: TextInputType.number,
            textAlign: TextAlign.end,
          ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorsSupport.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColorsSupport.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColorsSupport.error),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorCategorias() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerRight,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Listo',
                  style: TextStyle(
                    color: AppColorsPrimary.main,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  if (_categoriasDisponibles.isNotEmpty) {
                    setState(
                      () => _categoriaSeleccionada =
                          _categoriasDisponibles[index],
                    );
                  }
                },
                children: _categoriasDisponibles.isEmpty
                    ? [const Center(child: Text('Cargando categorías...'))]
                    : _categoriasDisponibles
                          .map((c) => Center(child: Text(c.nombre)))
                          .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarOpcionesImagen() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Foto del producto'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _seleccionarImagen(ImageSource.gallery);
            },
            child: const Text('Galería'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _seleccionarImagen(ImageSource.camera);
            },
            child: const Text('Cámara'),
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

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        setState(() => _imagenSeleccionada = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio');
      return;
    }

    final precio = double.tryParse(_precioCtrl.text);
    if (precio == null || precio <= 0) {
      setState(() => _error = 'El precio debe ser mayor a 0');
      return;
    }

    final stock = int.tryParse(_stockCtrl.text) ?? 0;
    if (_tieneStock && stock < 0) {
      setState(() => _error = 'El stock no puede ser negativo');
      return;
    }

    if (_categoriaSeleccionada == null && widget.producto == null) {
      setState(() => _error = 'Debes seleccionar una categoría');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> data = {
        'nombre': nombre,
        'descripcion': _descCtrl.text.trim(),
        'precio': precio.toString(),
        'disponible': _disponible.toString(),
        'destacado': _destacado.toString(),
        'tiene_stock': _tieneStock.toString(),
      };

      if (_categoriaSeleccionada != null) {
        data['categoria_id'] = _categoriaSeleccionada!.id;
      }

      if (_tipoImagen == 1 && _imagenUrlCtrl.text.isNotEmpty) {
        data['imagen_url'] = _imagenUrlCtrl.text.trim();
        _imagenSeleccionada = null;
      }

      final precioAnt = double.tryParse(_precioAntCtrl.text);
      if (precioAnt != null) {
        data['precio_anterior'] = precioAnt.toString();
      } else {
        data['precio_anterior'] = '';
      }

      if (_tieneStock) {
        data['stock'] = stock.toString();
      }

      if (widget.producto != null) {
        await _service.actualizarProductoProveedor(
          widget.producto!.id,
          data,
          imagen: _imagenSeleccionada,
        );
      } else {
        await _service.crearProductoProveedor(
          data,
          imagen: _imagenSeleccionada,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
