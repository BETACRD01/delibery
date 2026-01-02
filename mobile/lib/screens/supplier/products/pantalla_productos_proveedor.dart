import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/network/api_config.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/products/producto_model.dart';
import '../../../theme/app_colors_primary.dart';
import 'product_detail_screen.dart';
import 'product_edit_sheet.dart';

/// Pantalla dedicada para gestionar productos del proveedor
/// Rediseñada con estilo nativo iOS
class PantallaProductosProveedor extends StatefulWidget {
  const PantallaProductosProveedor({super.key});

  @override
  State<PantallaProductosProveedor> createState() =>
      _PantallaProductosProveedorState();
}

class _PantallaProductosProveedorState
    extends State<PantallaProductosProveedor> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        child: SafeArea(
          child: Consumer<SupplierController>(
            builder: (context, controller, child) {
              // Mostrar indicador de carga tipo iOS mientras se cargan los datos
              if (controller.loading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(radius: 14),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando...',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!controller.verificado) {
                return _buildSinVerificar(context);
              }

              if (controller.productos.isEmpty) {
                return _buildVacio(context);
              }

              return Column(
                children: [
                  // Header
                  _buildHeader(context, controller),
                  // Product list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => controller.refrescar(),
                      color: AppColorsPrimary.main,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: controller.productos.length,
                        itemBuilder: (context, index) {
                          final producto = controller.productos[index];
                          return _buildProductoItem(
                            context,
                            producto,
                            index,
                            controller.productos.length,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SupplierController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mis Productos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _mostrarFormularioProducto(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorsPrimary.main,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoItem(
    BuildContext context,
    ProductoModel producto,
    int index,
    int total,
  ) {
    final bool esPrimero = index == 0;
    final bool esUltimo = index == total - 1;
    const double radio = 12.0;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(esPrimero ? radio : 0),
          topRight: Radius.circular(esPrimero ? radio : 0),
          bottomLeft: Radius.circular(esUltimo ? radio : 0),
          bottomRight: Radius.circular(esUltimo ? radio : 0),
        ),
      ),
      child: Column(
        children: [
          _buildCupertinoListTile(context, producto),
          if (!esUltimo)
            Padding(
              padding: const EdgeInsets.only(left: 76),
              child: Container(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCupertinoListTile(BuildContext context, ProductoModel producto) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _abrirDetalleProducto(producto),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildImagenProducto(context, producto.imagenUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (producto.stock != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'Stock: ${producto.stock}',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${_formatPrecio(producto.precio)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildBadgeEstado(producto.disponible),
                    ],
                  ),
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
      ),
    );
  }

  Widget _buildImagenProducto(BuildContext context, String? imagenUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        child: imagenUrl != null && imagenUrl.isNotEmpty
            ? Image.network(
                imagenUrl.startsWith('http')
                    ? imagenUrl
                    : '${ApiConfig.baseUrl}$imagenUrl',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  CupertinoIcons.photo,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                  size: 24,
                ),
              )
            : Icon(
                CupertinoIcons.photo,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                size: 24,
              ),
      ),
    );
  }

  Widget _buildBadgeEstado(bool disponible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: disponible
            ? CupertinoColors.activeGreen.withValues(alpha: 0.15)
            : CupertinoColors.systemRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        disponible ? 'Disponible' : 'No disponible',
        style: TextStyle(
          color: disponible
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemRed,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVacio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColorsPrimary.main.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.cube_box,
                size: 48,
                color: AppColorsPrimary.main,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin productos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer producto para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => _mostrarFormularioProducto(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 18),
                  SizedBox(width: 8),
                  Text('Agregar Producto'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinVerificar(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CupertinoColors.activeOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 48,
                color: CupertinoColors.activeOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cuenta pendiente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu cuenta está siendo revisada. Podrás agregar productos cuando sea verificada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrecio(double? precio) {
    if (precio == null) return '0.00';
    return precio.toStringAsFixed(2);
  }

  void _mostrarFormularioProducto([ProductoModel? producto]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductEditSheet(producto: producto),
    );
  }

  void _abrirDetalleProducto(ProductoModel producto) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ProductDetailScreen(productId: producto.id),
      ),
    );
  }
}
