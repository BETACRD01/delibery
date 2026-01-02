// lib/screens/user/carrito/carrito_item_card.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, NetworkImage;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/products/producto_model.dart';
import '../../../models/products/promocion_model.dart';
import '../../../providers/cart/proveedor_carrito.dart';
import '../../../services/core/ui/toast_service.dart';
import '../../../../../theme/primary_colors.dart';
import '../../../theme/jp_theme.dart';

class ItemCarritoCard extends StatefulWidget {
  final ItemCarrito item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const ItemCarritoCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  State<ItemCarritoCard> createState() => _ItemCarritoCardState();
}

class _ItemCarritoCardState extends State<ItemCarritoCard> {
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
          color: AppColorsPrimary.main.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorsPrimary.main.withValues(alpha: 0.08),
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
                                color: AppColorsPrimary.main,
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
                                color: JPCupertinoColors.secondaryLabel(
                                  context,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${widget.item.precioUnitario.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColorsPrimary.main,
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
                        color: AppColorsPrimary.main,
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

  Widget _buildProductoIncluido(ProductoModel producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: JPCupertinoColors.separator(context)),
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

  void _mostrarDialogoEliminarProducto(ProductoModel producto) {
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
              ToastService().showSuccess(
                context,
                '${producto.nombre} eliminado',
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromocionImage(PromocionModel promocion) {
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
        border: Border.all(color: JPCupertinoColors.separator(context)),
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
                              color: AppColorsPrimary.main,
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
        border: Border.all(color: JPCupertinoColors.separator(context)),
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
                  ? AppColorsPrimary.main
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
              color: AppColorsPrimary.main,
            ),
          ),
        ],
      ),
    );
  }
}
