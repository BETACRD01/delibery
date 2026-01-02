// lib/screens/delivery/historial/pantalla_detalle_entrega.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/orders/entrega_historial.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de detalle completo de una entrega del historial
class PantallaDetalleEntrega extends StatelessWidget {
  final EntregaHistorial entrega;

  const PantallaDetalleEntrega({super.key, required this.entrega});

  static const Color _accent = Color(0xFF0CB7F2);
  static const Color _success = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    final surface = CupertinoColors.systemGroupedBackground.resolveFrom(
      context,
    );
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    );
    final cardBorder = CupertinoColors.separator.resolveFrom(context);
    final textPrimary = CupertinoColors.label.resolveFrom(context);
    final textSecondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: surface,
        navigationBar: CupertinoNavigationBar(
          middle: Text('Pedido #${entrega.id}'),
          backgroundColor: surface,
          border: null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de estado
                _buildEstadoCard(context, cardBg, cardBorder, textPrimary),
                const SizedBox(height: 20),

                // Información del cliente
                _buildSeccion(
                  context,
                  'INFORMACIÓN DEL CLIENTE',
                  cardBg,
                  cardBorder,
                  textSecondary,
                  [
                    _buildInfoRow(
                      context,
                      CupertinoIcons.person_fill,
                      'Cliente',
                      entrega.clienteNombre.isEmpty
                          ? 'Cliente invitado'
                          : entrega.clienteNombre,
                      textPrimary,
                      textSecondary,
                    ),
                    _buildDivider(cardBorder),
                    _buildInfoRow(
                      context,
                      CupertinoIcons.location_solid,
                      'Dirección',
                      entrega.clienteDireccion,
                      textPrimary,
                      textSecondary,
                    ),
                    if (entrega.clienteTelefono != null &&
                        entrega.clienteTelefono!.isNotEmpty) ...[
                      _buildDivider(cardBorder),
                      _buildInfoRowWithAction(
                        context,
                        CupertinoIcons.phone_fill,
                        'Teléfono',
                        entrega.clienteTelefono!,
                        textPrimary,
                        textSecondary,
                        onTap: () => _llamarTelefono(entrega.clienteTelefono!),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Detalles del pedido
                _buildSeccion(
                  context,
                  'DETALLES DEL PEDIDO',
                  cardBg,
                  cardBorder,
                  textSecondary,
                  [
                    _buildInfoRow(
                      context,
                      CupertinoIcons.number,
                      'Número de pedido',
                      '#${entrega.id}',
                      textPrimary,
                      textSecondary,
                    ),
                    _buildDivider(cardBorder),
                    _buildInfoRow(
                      context,
                      CupertinoIcons.calendar,
                      'Fecha de entrega',
                      entrega.fechaFormateada,
                      textPrimary,
                      textSecondary,
                    ),
                    _buildDivider(cardBorder),
                    _buildInfoRow(
                      context,
                      CupertinoIcons.creditcard_fill,
                      'Método de pago',
                      _formatearMetodoPago(entrega.metodoPago),
                      textPrimary,
                      textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Información financiera
                _buildSeccion(
                  context,
                  'INFORMACIÓN FINANCIERA',
                  cardBg,
                  cardBorder,
                  textSecondary,
                  [
                    _buildMoneyRow(
                      context,
                      'Total del pedido',
                      entrega.montoTotal,
                      textPrimary,
                      textSecondary,
                      isTotal: false,
                    ),
                    _buildDivider(cardBorder),
                    _buildMoneyRow(
                      context,
                      'Tu ganancia',
                      entrega.comisionRepartidor,
                      textPrimary,
                      textSecondary,
                      isTotal: true,
                      color: _success,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Comprobante
                _buildSeccion(
                  context,
                  'COMPROBANTE',
                  cardBg,
                  cardBorder,
                  textSecondary,
                  [
                    _buildComprobanteRow(
                      context,
                      entrega,
                      textPrimary,
                      textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Entrega Completada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entrega.fechaFormateada,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(
    BuildContext context,
    String titulo,
    Color cardBg,
    Color cardBorder,
    Color textSecondary,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithAction(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary, {
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.phone_arrow_up_right, color: _accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyRow(
    BuildContext context,
    String label,
    double amount,
    Color textPrimary,
    Color textSecondary, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color ?? textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteRow(
    BuildContext context,
    EntregaHistorial entrega,
    Color textPrimary,
    Color textSecondary,
  ) {
    final tiene = entrega.tieneComprobante;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (tiene ? _success : CupertinoColors.systemGrey).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tiene ? CupertinoIcons.doc_text_fill : CupertinoIcons.doc_text,
              color: tiene ? _success : CupertinoColors.systemGrey,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  tiene ? 'Comprobante adjunto' : 'Sin comprobante',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: tiene ? _success : textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (tiene)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              onPressed: () =>
                  _verComprobante(context, entrega.urlComprobante!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: color,
      indent: 16,
      endIndent: 16,
    );
  }

  String _formatearMetodoPago(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia Bancaria';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return metodo[0].toUpperCase() + metodo.substring(1);
    }
  }

  Future<void> _llamarTelefono(String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _verComprobante(BuildContext context, String url) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => _PantallaVerImagen(url: url)),
    );
  }
}

/// Pantalla simple para ver el comprobante
class _PantallaVerImagen extends StatelessWidget {
  final String url;

  const _PantallaVerImagen({required this.url});

  @override
  Widget build(BuildContext context) {
    final surface = CupertinoColors.systemGroupedBackground.resolveFrom(
      context,
    );

    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Comprobante'),
        backgroundColor: surface,
      ),
      child: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CupertinoActivityIndicator();
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar imagen',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
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
}
