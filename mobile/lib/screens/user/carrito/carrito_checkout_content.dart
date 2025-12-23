// lib/screens/user/carrito/carrito_checkout_content.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import '../../../models/usuario.dart';
import '../../../providers/proveedor_carrito.dart';
import '../../../../../theme/app_colors_primary.dart';
import '../../../theme/jp_theme.dart';
import 'carrito_direccion_card.dart';
import 'carrito_resumen_row.dart';

class CarritoCheckoutContent extends StatelessWidget {
  final List<ItemCarrito> items;
  final double subtotal;
  final double envio;
  final double recargoMulti;
  final double recargoNocturno;
  final double total;
  final bool tieneDirecciones;
  final VoidCallback onElegirDireccion;
  final VoidCallback onAgregarDireccion;
  final DireccionModel? direccionSeleccionada;
  final String direccionTitulo;
  final String? direccionCompleta;
  final bool mostrarInstrucciones;
  final TextEditingController instruccionesController;
  final String metodoPago;
  final ValueChanged<String> onMetodoPagoChanged;
  final VoidCallback onConfirmar;

  const CarritoCheckoutContent({
    super.key,
    required this.items,
    required this.subtotal,
    required this.envio,
    required this.recargoMulti,
    required this.recargoNocturno,
    required this.total,
    required this.tieneDirecciones,
    required this.onElegirDireccion,
    required this.onAgregarDireccion,
    required this.direccionSeleccionada,
    required this.direccionTitulo,
    required this.direccionCompleta,
    required this.mostrarInstrucciones,
    required this.instruccionesController,
    required this.metodoPago,
    required this.onMetodoPagoChanged,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                        itemCount: items.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 12,
                          color: JPCupertinoColors.separator(context),
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: JPCupertinoColors.secondaryLabel(
                                    context,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppColorsPrimary.main.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: tieneDirecciones
                      ? onElegirDireccion
                      : onAgregarDireccion,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.location,
                        size: 16,
                        color: AppColorsPrimary.main,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tieneDirecciones
                            ? 'Elegir dirección'
                            : 'Agregar dirección',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColorsPrimary.main,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dirección seleccionada
              if (direccionSeleccionada != null)
                CarritoDireccionCard(
                  titulo: direccionTitulo,
                  direccionCompleta: direccionCompleta,
                  esPredeterminada: direccionSeleccionada!.esPredeterminada,
                ),
              if (direccionSeleccionada != null) const SizedBox(height: 12),

              // Instrucciones
              if (mostrarInstrucciones) ...[
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
                        controller: instruccionesController,
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
                      groupValue: metodoPago,
                      children: const {
                        'efectivo': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.money_dollar_circle,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Transferencia',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value != null) {
                          onMetodoPagoChanged(value);
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
                    ResumenRow(label: 'Subtotal productos', value: subtotal),
                    ResumenRow(label: 'Envío', value: envio),
                    if (recargoNocturno > 0)
                      ResumenRow(
                        label: 'Recargo nocturno',
                        value: recargoNocturno,
                      ),
                    if (recargoMulti > 0)
                      ResumenRow(
                        label: 'Recargo multi-proveedor',
                        value: recargoMulti,
                      ),
                    Divider(
                      height: 20,
                      color: JPCupertinoColors.separator(context),
                    ),
                    ResumenRow(
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

        // Boton confirmar
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: onConfirmar,
              child: const Text(
                'Confirmar pedido',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
