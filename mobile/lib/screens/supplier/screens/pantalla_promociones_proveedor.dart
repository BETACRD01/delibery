// lib/screens/supplier/screens/pantalla_promociones_proveedor.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/producto_model.dart';
import '../../../models/promocion_model.dart';

class PantallaPromocionesProveedor extends StatelessWidget {
  const PantallaPromocionesProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Promociones'),
      ),
      body: Consumer<SupplierController>(
        builder: (context, controller, _) {
          final promos = controller.promociones;
          if (promos.isEmpty) {
            return const Center(child: Text('Sin promociones'));
          }
          return ListView.builder(
            itemCount: promos.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(promos[i].titulo),
            ),
          );
        },
      ),
    );
  }
}

// Helper público para reusar el formulario (stub)
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
  Color _colorSeleccionado = Colors.pink;
  File? _imagenSeleccionada;
  bool _procesando = false;
  bool _activa = true;
  bool _programar = false;
  String? _errorFormulario;
  String _tipoSeleccionado = 'descuento';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  ProductoModel? _productoAsociado;

  static const List<Color> _opcionesColor = [
    Colors.pink,
    Colors.indigo,
    Colors.teal,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.promo != null) {
      _tituloController.text = widget.promo!.titulo;
      _descripcionController.text = widget.promo!.descripcion;
      _descuentoController.text = widget.promo!.descuento;
      _activa = widget.promo!.activa;
      _colorSeleccionado = widget.promo!.color;
      _tipoSeleccionado = widget.promo!.tipoNavegacion == 'producto' ? 'descuento' : _tipoSeleccionado;
    }
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.promo != null ? 'Editar Promoción' : 'Nueva Promoción',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _mostrarOpcionesImagen,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _imagenSeleccionada != null
                        ? Image.file(_imagenSeleccionada!, fit: BoxFit.cover)
                        : widget.promo?.imagenUrl != null
                            ? Image.network(widget.promo!.imagenUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.campaign_outlined, size: 32, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_errorFormulario != null)
              Text(_errorFormulario!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descuentoController,
              decoration: const InputDecoration(
                labelText: 'Texto destacado (ej. 20% OFF)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('% Descuento'),
                  selected: _tipoSeleccionado == 'descuento',
                  onSelected: (_) => setState(() => _tipoSeleccionado = 'descuento'),
                ),
                ChoiceChip(
                  label: const Text('Envío gratis'),
                  selected: _tipoSeleccionado == 'envio',
                  onSelected: (_) => setState(() => _tipoSeleccionado = 'envio'),
                ),
                ChoiceChip(
                  label: const Text('2x1'),
                  selected: _tipoSeleccionado == '2x1',
                  onSelected: (_) => setState(() => _tipoSeleccionado = '2x1'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Color del banner', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _opcionesColor
                  .map((color) => ChoiceChip(
                        label: const Text(''),
                        backgroundColor: color,
                        selectedColor: color,
                        selected: _colorSeleccionado == color,
                        onSelected: (_) => setState(() => _colorSeleccionado = color),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _activa,
              onChanged: (value) => setState(() => _activa = value),
              title: const Text('Promoción activa'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _programar,
              onChanged: (value) => setState(() => _programar = value),
              title: const Text('Programar publicación'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_programar) ...[
              Row(
                children: [
                  Expanded(child: _buildFechaPicker(context, 'Inicio', _fechaInicio, (date) => setState(() => _fechaInicio = date))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFechaPicker(context, 'Fin', _fechaFin, (date) => setState(() => _fechaFin = date))),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Producto asociado'),
              subtitle: Text(_productoAsociado?.nombre ?? 'No se seleccionó'),
              trailing: TextButton(
                onPressed: () => _mostrarSelectorProducto(context),
                child: const Text('Seleccionar'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _procesando ? null : () => _guardarPromocion(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _colorSeleccionado,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar promoción', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
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

    if (_programar && (_fechaInicio == null || _fechaFin == null)) {
      setState(() {
        _errorFormulario = 'Selecciona fechas de inicio y fin';
        _procesando = false;
      });
      return;
    }

    final data = {
      'titulo': titulo,
      'descripcion': descripcion,
      'descuento': descuento,
      'color': '#${_colorHex(_colorSeleccionado)}',
      'activa': _activa ? 'true' : 'false',
      'tipo': _tipoSeleccionado,
      if (_programar) 'fecha_inicio': _fechaInicio?.toIso8601String(),
      if (_programar) 'fecha_fin': _fechaFin?.toIso8601String(),
      if (_productoAsociado != null) 'producto_asociado': _productoAsociado!.id,
    };

    final controller = context.read<SupplierController>();
    final ok = await controller.crearPromocion(
      data,
      imagen: _imagenSeleccionada,
    );

    setState(() => _procesando = false);

    if (ok) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promoción guardada'), backgroundColor: Colors.green),
      );
    } else if (controller.error != null) {
      setState(() => _errorFormulario = controller.error);
    }
  }

  Future<void> _mostrarOpcionesImagen() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Cámara'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        final picked = await _picker.pickImage(source: source, imageQuality: 70);
        if (picked != null) {
          setState(() => _imagenSeleccionada = File(picked.path));
        }
      } catch (_) {
        setState(() => _errorFormulario = 'No se pudo cargar la imagen');
      }
    }
  }

  Widget _buildFechaPicker(
    BuildContext context,
    String label,
    DateTime? fecha,
    ValueChanged<DateTime?> onSelected,
  ) {
    final texto = fecha != null ? fecha.toLocal().toString().split(' ').first : 'Seleccionar';
    return GestureDetector(
      onTap: () async {
        final seleccionado = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (seleccionado != null) {
          onSelected(seleccionado);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(texto),
            const SizedBox(width: 4),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarSelectorProducto(BuildContext context) async {
    final controller = context.read<SupplierController>();
    final productoSeleccionado = await showModalBottomSheet<ProductoModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ListView.builder(
          itemCount: controller.productos.length,
          itemBuilder: (_, index) {
            final producto = controller.productos[index];
            return ListTile(
              title: Text(producto.nombre),
              subtitle: Text('Stock: ${producto.stock ?? 0}'),
              onTap: () => Navigator.pop(ctx, producto),
            );
          },
        );
      },
    );
    if (productoSeleccionado != null) {
      setState(() => _productoAsociado = productoSeleccionado);
    }
  }

  String _colorHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return hex.substring(2);
  }
}
