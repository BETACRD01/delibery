import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../apis/productos/categorias_api.dart';
import '../../../providers/core/theme_provider.dart';
import '../../../theme/app_colors_primary.dart';

class PantallaGestionCategorias extends StatefulWidget {
  const PantallaGestionCategorias({super.key});

  @override
  State<PantallaGestionCategorias> createState() =>
      _PantallaGestionCategoriasState();
}

class _PantallaGestionCategoriasState extends State<PantallaGestionCategorias> {
  final _api = CategoriasApi();
  bool _cargando = true;
  List<dynamic> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final res = await _api.getCategorias();
      if (mounted) {
        setState(() {
          if (res is List) {
            _categorias = res;
          } else if (res is Map && res.containsKey('results')) {
            _categorias = res['results'];
          } else if (res is Map && res.containsKey('data')) {
            _categorias = res['data'];
          } else {
            _categorias = [];
          }
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        _mostrarError('Error cargando categorías: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColorsPrimary.main,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _eliminarCategoria(Map<String, dynamic> categoria) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: CupertinoAlertDialog(
          title: const Text('🗑️ Eliminar Categoría'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '¿Seguro que deseas eliminar "${categoria['nombre']}"?\n\nEsta acción no se puede deshacer.',
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _api.eliminarCategoria(categoria['id'].toString());
      if (mounted) {
        _mostrarExito('Categoría eliminada correctamente');
        await _cargarCategorias();
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al eliminar: $e');
      }
    }
  }

  void _mostrarModalFormulario({Map<String, dynamic>? categoria}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _FormularioCategoriaModal(categoria: categoria),
    ).then((val) {
      if (val == true) _cargarCategorias();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final primaryColor = AppColorsPrimary.main;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        backgroundColor: bgColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 16),
            onPressed: () => _mostrarModalFormulario(),
            child: Icon(
              CupertinoIcons.plus_circle_fill,
              color: primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : _categorias.isEmpty
          ? _buildEmptyState(isDark, primaryColor)
          : RefreshIndicator(
              onRefresh: _cargarCategorias,
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Lista de categorías
                  _buildCategoriasCard(isDark, primaryColor),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.square_grid_2x2,
              size: 48,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay categorías',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera categoría para\norganizar tus productos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () => _mostrarModalFormulario(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.plus, size: 18),
                SizedBox(width: 8),
                Text('Crear Categoría'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriasCard(bool isDark, Color primaryColor) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _categorias.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final isLast = index == _categorias.length - 1;

          return Column(
            children: [
              _buildCategoriaItem(cat, isDark, primaryColor, textColor),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 86,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriaItem(
    Map<String, dynamic> cat,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final imgUrl = cat['imagen_url'] ?? cat['imagen'];
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _mostrarModalFormulario(categoria: cat),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Imagen
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: imgUrl != null && imgUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CupertinoActivityIndicator(color: primaryColor),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        CupertinoIcons.photo,
                        color: hintColor,
                        size: 24,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.square_grid_2x2,
                      color: hintColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${cat['total_productos'] ?? 0} productos',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Acciones
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8),

                  onPressed: () => _mostrarModalFormulario(categoria: cat),
                  child: Icon(
                    CupertinoIcons.pencil_circle_fill,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),

                  onPressed: () => _eliminarCategoria(cat),
                  child: const Icon(
                    CupertinoIcons.trash_circle_fill,
                    color: CupertinoColors.destructiveRed,
                    size: 28,
                  ),
                ),
              ],
            ),
            Icon(CupertinoIcons.chevron_right, color: hintColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FormularioCategoriaModal extends StatefulWidget {
  final Map<String, dynamic>? categoria;

  const _FormularioCategoriaModal({this.categoria});

  @override
  State<_FormularioCategoriaModal> createState() =>
      _FormularioCategoriaModalState();
}

class _FormularioCategoriaModalState extends State<_FormularioCategoriaModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  File? _imagenFile;
  String? _imagenActualUrl;

  final _picker = ImagePicker();
  bool _enviando = false;

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreCtrl.text = widget.categoria!['nombre'] ?? '';
      _imagenActualUrl =
          widget.categoria!['imagen_url'] ?? widget.categoria!['imagen'];
      if (_imagenActualUrl != null && _imagenActualUrl!.startsWith('http')) {
        _urlCtrl.text = _imagenActualUrl!;
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Seleccionar Imagen'),
          message: const Text('Elige de dónde quieres obtener la imagen'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null && mounted) {
                  setState(() => _imagenFile = File(picked.path));
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.photo),
                  SizedBox(width: 10),
                  Text('Galería'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null && mounted) {
                  setState(() => _imagenFile = File(picked.path));
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.camera),
                  SizedBox(width: 10),
                  Text('Cámara'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_esEdicion && _imagenFile == null && _urlCtrl.text.isEmpty) {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => Material(
            type: MaterialType.transparency,
            child: CupertinoAlertDialog(
              title: const Text('Imagen Requerida'),
              content: const Text(
                'Debe seleccionar una imagen o ingresar una URL.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      if (_esEdicion) {
        await CategoriasApi().actualizarCategoria(
          id: widget.categoria!['id'].toString(),
          nombre: _nombreCtrl.text.trim(),
          imagen: _imagenFile,
          imagenUrl: _urlCtrl.text.trim().isNotEmpty
              ? _urlCtrl.text.trim()
              : null,
        );
      } else {
        await CategoriasApi().crearCategoria(
          nombre: _nombreCtrl.text.trim(),
          imagen: _imagenFile,
          imagenUrl: _urlCtrl.text.trim().isNotEmpty
              ? _urlCtrl.text.trim()
              : null,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => Material(
              type: MaterialType.transparency,
              child: CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('$e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final primaryColor = AppColorsPrimary.main;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Título
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _esEdicion
                          ? CupertinoIcons.pencil
                          : CupertinoIcons.plus_circle,
                      color: primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _esEdicion ? 'Editar Categoría' : 'Nueva Categoría',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preview de imagen
                Center(
                  child: GestureDetector(
                    onTap: _seleccionarImagen,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _imagenFile != null
                              ? primaryColor
                              : (isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!),
                          width: 2,
                        ),
                        boxShadow: [
                          if (_imagenFile != null)
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_imagenFile != null)
                            Image.file(_imagenFile!, fit: BoxFit.cover)
                          else if (_imagenActualUrl != null &&
                              _imagenActualUrl!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: _imagenActualUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CupertinoActivityIndicator(),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                CupertinoIcons.photo,
                                color: hintColor,
                                size: 32,
                              ),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.camera_fill,
                                  color: hintColor,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para\nseleccionar',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          // Overlay de edición
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: const Icon(
                                CupertinoIcons.pencil,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Campo Nombre
                Text(
                  'Nombre de la Categoría',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _nombreCtrl,
                  placeholder: 'Ej: Electrónica, Ropa, Alimentos...',
                  padding: const EdgeInsets.all(14),
                  style: TextStyle(color: textColor),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.tag, color: hintColor, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // URL opcional
                Row(
                  children: [
                    Icon(CupertinoIcons.link, color: hintColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'URL de imagen (opcional)',
                      style: TextStyle(
                        color: hintColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _urlCtrl,
                  placeholder: 'https://ejemplo.com/imagen.png',
                  padding: const EdgeInsets.all(14),
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.url,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 28),

                // Botón guardar
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _enviando ? null : _guardar,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _enviando ? Colors.grey : primaryColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _enviando
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _esEdicion
                                    ? CupertinoIcons.checkmark_circle
                                    : CupertinoIcons.plus_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _esEdicion
                                    ? 'Guardar Cambios'
                                    : 'Crear Categoría',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
