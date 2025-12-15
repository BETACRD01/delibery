// lib/screens/user/busqueda/pantalla_busqueda.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../controllers/user/busqueda_controller.dart';
import '../../../models/producto_model.dart';
import '../../../theme/jp_theme.dart';
import '../../../providers/proveedor_carrito.dart';
import '../../../config/rutas.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({super.key});

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusquedaController(),
      child: Consumer<BusquedaController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F5F9),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.4,
              foregroundColor: JPColors.textPrimary,
              titleSpacing: 0,
              title: const Text(
                'Buscar productos',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              actions: [
                if (controller.controladorBusqueda.text.isNotEmpty)
                  IconButton(
                    icon: Badge(
                      isLabelVisible: controller.tieneFiltrosActivos,
                      child: const Icon(Icons.filter_list),
                    ),
                    onPressed: () => _mostrarFiltros(context, controller),
                  ),
                if (controller.resultados.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.sort_rounded),
                    onPressed: () => _mostrarOrdenamiento(context, controller),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: Colors.grey.shade200),
              ),
            ),
            body: Column(
              children: [
                // Barra de búsqueda
                _buildBarraBusqueda(context, controller),

                // Chips de filtros activos
                if (controller.tieneFiltrosActivos)
                  _buildChipsFiltros(controller),

                // Resultados
                Expanded(
                  child: controller.buscando
                      ? const Center(child: CircularProgressIndicator())
                      : controller.error != null
                      ? _buildEstadoError(controller.error!)
                      : controller.controladorBusqueda.text.isEmpty
                      ? _buildEstadoInicial(controller)
                      : controller.resultados.isEmpty
                      ? _buildSinResultados()
                      : _buildListaResultados(controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS MODULARES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBarraBusqueda(BuildContext context, BusquedaController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: TextField(
          controller: controller.controladorBusqueda,
          onChanged: (query) => controller.buscarProductos(query),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Buscar productos o tiendas',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.controladorBusqueda.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: controller.limpiarBusqueda,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: JPColors.primary, width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoInicial(BusquedaController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Búsquedas recientes
          if (controller.historialBusqueda.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Búsquedas recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                TextButton(
                  onPressed: controller.limpiarHistorial,
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...controller.historialBusqueda.take(10).map((query) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => controller.eliminarDelHistorial(query),
                ),
                onTap: () => controller.buscarDesdeHistorial(query),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Sugerencias
          Center(
            child: Column(
              children: [
                Icon(Icons.search, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Busca tus productos favoritos',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Escribe en el cuadro de búsqueda',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

 Widget _buildEstadoError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: JPColors.error),
            const SizedBox(height: 16),
            Text(
              'Fallo la conexión',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[700], 
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaResultados(BusquedaController controller) {
    return Column(
      children: [
        // Contador de resultados
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '${controller.resultados.length} resultado${controller.resultados.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: JPColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: controller.resultados.length,
            itemBuilder: (context, index) {
              final ProductoModel producto = controller.resultados[index];
              return _ProductoCard(producto: producto);
            },
          ),
        ),
      ],
    );
  }

  // Chips de filtros activos
  Widget _buildChipsFiltros(BusquedaController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (controller.categoriaSeleccionada != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Categoría'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => controller.setCategoria(null),
              ),
            ),
          if (controller.precioMin > 0 || controller.precioMax < 1000)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('\$${controller.precioMin.toInt()} - \$${controller.precioMax.toInt()}'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => controller.setRangoPrecio(0, 1000),
              ),
            ),
          if (controller.ratingMin > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('${controller.ratingMin}+ ⭐'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => controller.setRatingMinimo(0),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: const Text('Limpiar filtros'),
              onPressed: controller.limpiarFiltros,
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo de filtros
  void _mostrarFiltros(BuildContext context, BusquedaController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return ChangeNotifierProvider.value(
            value: controller,
            child: Consumer<BusquedaController>(
              builder: (context, ctrl, _) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtros',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              ctrl.limpiarFiltros();
                              Navigator.pop(context);
                            },
                            child: const Text('Limpiar todo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // Categorías
                            const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Todas'),
                                  selected: ctrl.categoriaSeleccionada == null,
                                  onSelected: (_) => ctrl.setCategoria(null),
                                ),
                                ...ctrl.categorias.map((cat) {
                                  return ChoiceChip(
                                    label: Text(cat.nombre),
                                    selected: ctrl.categoriaSeleccionada == cat.id,
                                    onSelected: (_) => ctrl.setCategoria(cat.id),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Rango de precio
                            const Text('Rango de precio', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            RangeSlider(
                              values: RangeValues(ctrl.precioMin, ctrl.precioMax),
                              min: 0,
                              max: 1000,
                              divisions: 20,
                              labels: RangeLabels(
                                '\$${ctrl.precioMin.toInt()}',
                                '\$${ctrl.precioMax.toInt()}',
                              ),
                              onChanged: (values) {
                                ctrl.setRangoPrecio(values.start, values.end);
                              },
                            ),
                            Text(
                              '\$${ctrl.precioMin.toInt()} - \$${ctrl.precioMax.toInt()}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),

                            // Rating mínimo
                            const Text('Calificación mínima', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                                return ChoiceChip(
                                  label: Text(rating == 0 ? 'Todas' : '$rating+ ⭐'),
                                  selected: ctrl.ratingMin == rating,
                                  onSelected: (_) => ctrl.setRatingMinimo(rating),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Diálogo de ordenamiento
  void _mostrarOrdenamiento(BuildContext context, BusquedaController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordenar por',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Relevancia'),
                trailing: controller.ordenamiento == 'relevancia'
                    ? const Icon(Icons.check, color: JPColors.primary)
                    : null,
                onTap: () {
                  controller.setOrdenamiento('relevancia');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Precio: menor a mayor'),
                trailing: controller.ordenamiento == 'precio_asc'
                    ? const Icon(Icons.check, color: JPColors.primary)
                    : null,
                onTap: () {
                  controller.setOrdenamiento('precio_asc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Precio: mayor a menor'),
                trailing: controller.ordenamiento == 'precio_desc'
                    ? const Icon(Icons.check, color: JPColors.primary)
                    : null,
                onTap: () {
                  controller.setOrdenamiento('precio_desc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Mejor calificados'),
                trailing: controller.ordenamiento == 'rating'
                    ? const Icon(Icons.check, color: JPColors.primary)
                    : null,
                onTap: () {
                  controller.setOrdenamiento('rating');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CARD DE PRODUCTO CON IMAGEN Y ADD TO CART
// ══════════════════════════════════════════════════════════════════════════

class _ProductoCard extends StatelessWidget {
  final ProductoModel producto;

  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final carritoProvider = Provider.of<ProveedorCarrito>(context, listen: false);
    final tieneDescuento = producto.precioAnterior != null &&
        producto.precioAnterior! > producto.precio;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pushNamed(
            context,
            Rutas.productoDetalle,
            arguments: producto,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: producto.imagenUrl!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 88,
                          height: 88,
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 88,
                          height: 88,
                          color: Colors.grey[200],
                          child: Icon(Icons.fastfood, size: 32, color: Colors.grey[600]),
                        ),
                      )
                    : Container(
                        width: 88,
                        height: 88,
                        color: Colors.grey[200],
                        child: Icon(Icons.fastfood, size: 32, color: Colors.grey[600]),
                      ),
              ),
              const SizedBox(width: 12),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildProveedorBadge(),
                    const SizedBox(height: 6),
                    Text(
                      producto.descripcion,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    if (producto.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            producto.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),

                    // Precio y botón
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tieneDescuento) ...[
                              Text(
                                producto.precioAnteriorFormateado,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              producto.precioFormateado,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: JPColors.primary,
                              ),
                            ),
                          ],
                        ),

                        // Botón agregar al carrito
                        ElevatedButton.icon(
                          onPressed: producto.disponible
                              ? () async {
                                  await carritoProvider.agregarProducto(producto);
                                }
                              : null,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
      ),
    );
  }
  Widget _buildProveedorBadge() {
    final tieneLogo = producto.proveedorLogoUrl != null && producto.proveedorLogoUrl!.isNotEmpty;
    final tieneNombre = (producto.proveedorNombre ?? '').isNotEmpty;
    if (!tieneLogo && !tieneNombre) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: Colors.grey[200],
          backgroundImage: tieneLogo ? NetworkImage(producto.proveedorLogoUrl!) : null,
          child: !tieneLogo
              ? const Icon(Icons.storefront_outlined, size: 12, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 6),
        if (tieneNombre)
          Expanded(
            child: Text(
              producto.proveedorNombre!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
