// lib/screens/supplier/tabs/productos_tab.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/network/api_config.dart';
import '../../../../controllers/supplier/supplier_controller.dart';
import '../../../../models/products/producto_model.dart';
import '../product_detail_screen.dart';
import '../product_edit_sheet.dart';
import '../pantalla_productos_proveedor.dart';

/// Tab de productos - Diseño limpio y profesional
class ProductosTab extends StatefulWidget {
  const ProductosTab({super.key});

  @override
  State<ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<ProductosTab> {
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _exito = Color(0xFF10B981);
  static const Color _alerta = Color(0xFFF59E0B);

  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'todos';
  bool _stockBajo = false;
  bool _vistaAgrupada = true; // Vista por categorías habilitada por defecto
  final Set<String> _seleccionados = {};
  final Set<String> _categoriasExpandidas = {}; // Categorías expandidas

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductoModel> _filtrarProductos(List<ProductoModel> items) {
    var filtrados = items.where((producto) {
      final query = _searchController.text.toLowerCase();
      final nombre = producto.nombre.toLowerCase();
      if (query.isNotEmpty && !nombre.contains(query)) return false;
      if (_statusFilter == 'activos' && !producto.disponible) return false;
      if (_statusFilter == 'agotados' && producto.disponible) return false;
      if (_stockBajo && (producto.stock == null || producto.stock! > 5)) {
        return false;
      }
      return true;
    }).toList();
    return filtrados;
  }

  void _toggleSeleccion(String id) {
    setState(() {
      if (_seleccionados.contains(id)) {
        _seleccionados.remove(id);
      } else {
        _seleccionados.add(id);
      }
    });
  }

  void _limpiarSeleccion() {
    setState(() => _seleccionados.clear());
  }

  bool get _modoSeleccion => _seleccionados.isNotEmpty;

  // Agrupa productos por categoría
  Map<String, List<ProductoModel>> _agruparPorCategoria(
    List<ProductoModel> productos,
  ) {
    final Map<String, List<ProductoModel>> grupos = {};
    for (final producto in productos) {
      final categoria = producto.categoriaNombre ?? 'Sin categoría';
      grupos.putIfAbsent(categoria, () => []).add(producto);
    }
    // Ordenar categorías alfabéticamente
    final sortedKeys = grupos.keys.toList()..sort();
    return {for (var k in sortedKeys) k: grupos[k]!};
  }

  void _toggleCategoria(String categoria) {
    setState(() {
      if (_categoriasExpandidas.contains(categoria)) {
        _categoriasExpandidas.remove(categoria);
      } else {
        _categoriasExpandidas.add(categoria);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        // Primero verificar si está cargando - mostrar loader iOS
        if (controller.loading) {
          return const Center(child: CupertinoActivityIndicator(radius: 16));
        }

        // Luego verificar si la cuenta está verificada
        if (!controller.verificado) {
          return _buildEstadoVacio(
            icono: Icons.verified_user_outlined,
            titulo: 'Verificación pendiente',
            mensaje: 'Tu cuenta debe ser verificada para agregar productos.',
            color: _alerta,
          );
        }

        final productosFiltrados = _filtrarProductos(controller.productos);

        if (productosFiltrados.isEmpty) {
          return _buildEmpty(context, controller);
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => controller.refrescarProductos(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  if (_vistaAgrupada)
                    ..._buildProductosPorCategoria(
                      context,
                      controller,
                      productosFiltrados,
                    )
                  else
                    ...productosFiltrados.map(
                      (producto) =>
                          _buildProductoCard(context, controller, producto),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            if (_modoSeleccion)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildAccionesMasivas(controller),
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: const ProductEditSheet(),
                    ),
                  );
                  if (result == true) {
                    if (context.mounted) {
                      await controller.refrescarProductos();
                    }
                  }
                },
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar productos',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () async {
            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: const ProductEditSheet(),
              ),
            );
            if (result == true) {
              if (mounted) {
                await context.read<SupplierController>().refrescarProductos();
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _exito,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: _exito.withValues(alpha: 0.3), blurRadius: 8),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          runSpacing: 8,
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: _statusFilter == 'todos',
              onSelected: (_) => setState(() => _statusFilter = 'todos'),
            ),
            ChoiceChip(
              label: const Text('Activos'),
              selected: _statusFilter == 'activos',
              onSelected: (_) => setState(() => _statusFilter = 'activos'),
            ),
            ChoiceChip(
              label: const Text('Agotados'),
              selected: _statusFilter == 'agotados',
              onSelected: (_) => setState(() => _statusFilter = 'agotados'),
            ),
            FilterChip(
              label: const Text('Stock bajo'),
              selected: _stockBajo,
              onSelected: (value) => setState(() => _stockBajo = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Toggle vista agrupada/lista
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _vistaAgrupada
                ? _exito.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _vistaAgrupada
                  ? _exito.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _vistaAgrupada
                      ? _exito.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _vistaAgrupada ? Icons.folder : Icons.view_list,
                  size: 18,
                  color: _vistaAgrupada ? _exito : _textoSecundario,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vistaAgrupada ? 'Vista por Carpetas' : 'Vista en Lista',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _vistaAgrupada ? _exito : Colors.black87,
                      ),
                    ),
                    Text(
                      _vistaAgrupada
                          ? 'Productos agrupados por categoría'
                          : 'Todos los productos en orden',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _vistaAgrupada,
                onChanged: (v) => setState(() => _vistaAgrupada = v),
                activeTrackColor: _exito,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Genera secciones de productos agrupados por categoría
  List<Widget> _buildProductosPorCategoria(
    BuildContext context,
    SupplierController controller,
    List<ProductoModel> productos,
  ) {
    final grupos = _agruparPorCategoria(productos);
    final widgets = <Widget>[];

    // Si no hay categorías expandidas, expandir todas por defecto
    if (_categoriasExpandidas.isEmpty && grupos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _categoriasExpandidas.addAll(grupos.keys);
        });
      });
    }

    for (final entry in grupos.entries) {
      final categoria = entry.key;
      final prods = entry.value;
      final expandida = _categoriasExpandidas.contains(categoria);

      // Header de categoría (carpeta)
      widgets.add(
        GestureDetector(
          onTap: () => _toggleCategoria(categoria),
          child: Container(
            margin: EdgeInsets.only(bottom: expandida ? 4 : 8, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _exito.withValues(alpha: 0.08),
                  _exito.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: expandida
                    ? _exito.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.15),
                width: expandida ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _exito.withValues(alpha: 0.1),
                  blurRadius: expandida ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono de carpeta más grande y destacado
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _exito.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _exito.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    expandida ? Icons.folder_open : Icons.folder,
                    color: _exito,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: expandida ? _exito : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${prods.length} producto${prods.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textoSecundario,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Flecha animada
                AnimatedRotation(
                  turns: expandida ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: expandida ? _exito : _textoSecundario,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Productos de la categoría (si está expandida)
      if (expandida) {
        for (final producto in prods) {
          widgets.add(_buildProductoCard(context, controller, producto));
        }
      }

      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _buildProductoCard(
    BuildContext context,
    SupplierController controller,
    ProductoModel producto,
  ) {
    final seleccionada = _seleccionados.contains(producto.id);
    return GestureDetector(
      onLongPress: () => _toggleSeleccion(producto.id),
      onTap: () {
        if (_modoSeleccion) {
          _toggleSeleccion(producto.id);
          return;
        }
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: producto.id),
              ),
            )
            .then((_) async {
              if (context.mounted) {
                await controller.refrescarProductos();
              }
            }); // Recargar lista al volver
      },
      child: Dismissible(
        key: ValueKey(producto.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          // Mostrar diálogo de confirmación
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar producto'),
                  content: Text(
                    '¿Estás seguro de que deseas eliminar "${producto.nombre}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) async {
          // Llamar al API para eliminar el producto
          try {
            await controller.eliminarProducto(producto.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Producto "${producto.nombre}" eliminado'),
                  backgroundColor: _exito,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al eliminar: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              // Recargar para mostrar el producto nuevamente
              await controller.refrescarProductos();
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionada ? _exito : Colors.grey.withValues(alpha: 0.2),
              width: seleccionada ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: _buildImagenProducto(
              producto.imagenUrl,
              heroTag: 'producto-${producto.id}',
            ),
            title: Text(
              producto.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${_formatPrecio(producto.precio)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _exito,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (producto.stock != null) ...[
                      _buildStockBadge(producto.stock!),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: producto.disponible
                            ? _exito.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        producto.disponible ? 'Publicado' : 'Pausado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: producto.disponible ? _exito : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar producto'),
                        content: Text(
                          '¿Estás seguro de que deseas eliminar "${producto.nombre}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true && context.mounted) {
                      try {
                        await controller.eliminarProducto(producto.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Producto "${producto.nombre}" eliminado',
                              ),
                              backgroundColor: _exito,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al eliminar: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagenProducto(String? imagen, {required String heroTag}) {
    String? urlCompleta;
    if (imagen != null && imagen.isNotEmpty) {
      urlCompleta = imagen.startsWith('http')
          ? imagen
          : '${ApiConfig.baseUrl}$imagen';
    }

    return Hero(
      tag: heroTag,
      flightShuttleBuilder:
          (
            BuildContext flightContext,
            Animation<double> animation,
            HeroFlightDirection flightDirection,
            BuildContext fromHeroContext,
            BuildContext toHeroContext,
          ) {
            // Mantener el estilo del destino durante el vuelo para evitar bordes amarillos
            return Material(
              type: MaterialType.transparency,
              child: toHeroContext.widget,
            );
          },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: urlCompleta != null
              ? Image.network(
                  urlCompleta,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
    );
  }

  Widget _buildEmpty(BuildContext context, SupplierController controller) {
    return _buildEstadoVacio(
      icono: Icons.inventory_2_outlined,
      titulo: 'Sin productos',
      mensaje: 'Agrega tu primer producto para comenzar a vender.',
      color: _textoSecundario,
      accion: FilledButton.icon(
        onPressed: () async => _irAGestionProductos(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Crear producto'),
      ),
    );
  }

  Widget _buildEstadoVacio({
    required IconData icono,
    required String titulo,
    required String mensaje,
    required Color color,
    Widget? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 64, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _textoSecundario,
                height: 1.4,
              ),
            ),
            if (accion != null) ...[const SizedBox(height: 24), accion],
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    // Determinar el color y el ícono según el nivel de stock
    Color badgeColor;
    IconData icon;
    String text;

    if (stock == 0) {
      badgeColor = Colors.red;
      icon = Icons.warning_rounded;
      text = 'Agotado';
    } else if (stock <= 5) {
      badgeColor = _alerta;
      icon = Icons.error_outline_rounded;
      text = 'Stock: $stock';
    } else if (stock <= 10) {
      badgeColor = const Color(0xFF3B82F6); // Azul
      icon = Icons.inventory_2_outlined;
      text = 'Stock: $stock';
    } else {
      badgeColor = _exito;
      icon = Icons.check_circle_outline_rounded;
      text = 'Stock: $stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: stock <= 5
            ? Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrecio(dynamic precio) {
    if (precio is num) return precio.toStringAsFixed(2);
    if (precio is String) return precio;
    return '0.00';
  }

  void _irAGestionProductos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PantallaProductosProveedor()),
    );
  }

  Widget _buildAccionesMasivas(SupplierController controller) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_seleccionados.length} seleccionados',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _limpiarSeleccion,
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Acción masiva ejecutada')),
                    );
                  },
                  child: const Text('Pausar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
