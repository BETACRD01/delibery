// lib/screens/delivery/widgets/card_encargo_activo.dart
// Widget para mostrar encargos activos con flujo de dos etapas

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/pedido_repartidor.dart';

/// Card expandido para encargos (courier) en curso
/// Muestra flujo de dos etapas: Recoger → Entregar
class CardEncargoActivo extends StatelessWidget {
  final PedidoDetalladoRepartidor encargo;
  final VoidCallback? onMarcarRecogido;
  final VoidCallback? onMarcarEntregado;
  final VoidCallback? onNavegar;
  final VoidCallback? onLlamar;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onVerComprobante;

  const CardEncargoActivo({
    super.key,
    required this.encargo,
    this.onMarcarRecogido,
    this.onMarcarEntregado,
    this.onNavegar,
    this.onLlamar,
    this.onWhatsApp,
    this.onVerComprobante,
  });

  // Colores
  static const Color _colorEncargo = Colors.deepOrange;
  static const Color _accent = Color(0xFF0CB7F2);
  static const Color _success = Color(0xFF34C759);

  /// Determina si el repartidor ya recogió el paquete
  bool get _yaRecogio {
    final estado = encargo.estado.toLowerCase();
    return estado == 'en_camino' || estado == 'entregado';
  }

  /// Determina si el encargo ya fue entregado
  bool get _yaEntregado {
    return encargo.estado.toLowerCase() == 'entregado';
  }

  /// Determina si tiene comprobante de transferencia para mostrar
  bool get _tieneComprobante {
    return encargo.metodoPago.toLowerCase() == 'transferencia' &&
        encargo.transferenciaComprobanteUrl != null &&
        encargo.transferenciaComprobanteUrl!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    );
    final cardBorder = CupertinoColors.separator.resolveFrom(context);
    final textPrimary = CupertinoColors.label.resolveFrom(context);
    final textSecondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 0.5),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Badge + Estado
            _buildHeader(context),

            const SizedBox(height: 16),

            // Indicador de etapa visual
            _buildEtapaIndicador(context, textSecondary),

            const SizedBox(height: 16),

            // Direcciones (origen y destino)
            _buildDirecciones(context, textPrimary, textSecondary),

            const SizedBox(height: 16),

            // Info del cliente/destinatario
            _buildInfoDestinatario(context, textPrimary, textSecondary),

            // Descripción si existe
            if (encargo.descripcion != null &&
                encargo.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDescripcion(context, textSecondary),
            ],

            // Comprobante de transferencia (si existe)
            if (_tieneComprobante) ...[
              const SizedBox(height: 12),
              _buildComprobanteSection(context),
            ],

            const SizedBox(height: 16),

            // Totales
            _buildTotales(context),

            const SizedBox(height: 16),

            // Botones de acción
            _buildBotonesAccion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _colorEncargo.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.paperplane_fill,
                  size: 18,
                  color: _colorEncargo,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '📦 Encargo #${encargo.numeroPedido}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildChipEstado(),
      ],
    );
  }

  Widget _buildChipEstado() {
    Color color;
    String texto;

    if (_yaEntregado) {
      color = _success;
      texto = 'Entregado';
    } else if (_yaRecogio) {
      color = _accent;
      texto = 'En Camino';
    } else {
      color = _colorEncargo;
      texto = 'Por Recoger';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEtapaIndicador(BuildContext context, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_yaRecogio ? _accent : _colorEncargo).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_yaRecogio ? _accent : _colorEncargo).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Etapa 1: Recoger
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _yaRecogio ? _success : _colorEncargo,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _yaRecogio
                        ? CupertinoIcons.checkmark
                        : CupertinoIcons.arrow_up_circle_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _yaRecogio ? 'Recogido' : 'Ir a Recoger',
                    style: TextStyle(
                      fontWeight: _yaRecogio
                          ? FontWeight.w500
                          : FontWeight.bold,
                      fontSize: 13,
                      color: _yaRecogio ? textSecondary : _colorEncargo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Línea conectora
          Container(
            width: 30,
            height: 2,
            color: _yaRecogio ? _success : Colors.grey.shade300,
          ),
          // Etapa 2: Entregar
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _yaEntregado ? 'Entregado' : 'Ir a Entregar',
                    style: TextStyle(
                      fontWeight: _yaRecogio && !_yaEntregado
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                      color: _yaRecogio
                          ? (_yaEntregado ? _success : _accent)
                          : textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _yaEntregado
                        ? _success
                        : (_yaRecogio ? _accent : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _yaEntregado
                        ? CupertinoIcons.checkmark
                        : CupertinoIcons.location_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirecciones(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    final origenActivo = !_yaRecogio;
    final destinoActivo = _yaRecogio && !_yaEntregado;

    return Column(
      children: [
        // Punto de Recogida (Origen)
        _buildDireccionItem(
          context,
          icono: CupertinoIcons.arrow_up_circle_fill,
          color: origenActivo ? _colorEncargo : textSecondary,
          titulo: 'PUNTO DE RECOGIDA',
          direccion: encargo.direccionOrigen ?? 'Origen no especificado',
          activo: origenActivo,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        // Línea conectora
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Row(
            children: [
              Container(width: 2, height: 24, color: Colors.grey.shade300),
            ],
          ),
        ),

        // Punto de Entrega (Destino)
        _buildDireccionItem(
          context,
          icono: CupertinoIcons.location_fill,
          color: destinoActivo ? _accent : textSecondary,
          titulo: 'PUNTO DE ENTREGA',
          direccion: encargo.direccionEntrega,
          activo: destinoActivo,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ],
    );
  }

  Widget _buildDireccionItem(
    BuildContext context, {
    required IconData icono,
    required Color color,
    required String titulo,
    required String direccion,
    required bool activo,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: activo
            ? color.withValues(alpha: 0.08)
            : CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: activo ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  direccion,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                    color: activo ? textPrimary : textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (activo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ACTUAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoDestinatario(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _accent.withValues(alpha: 0.2),
            backgroundImage: encargo.cliente.foto != null
                ? NetworkImage(encargo.cliente.foto!)
                : null,
            child: encargo.cliente.foto == null
                ? Icon(CupertinoIcons.person_fill, color: _accent, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destinatario',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  encargo.cliente.nombre,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Botones de contacto
          if (encargo.cliente.telefono != null) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onLlamar,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.phone_fill,
                  color: _success,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onWhatsApp,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat,
                  color: Color(0xFF25D366),
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescripcion(BuildContext context, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.doc_text, color: textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrucciones',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  encargo.descripcion!,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección para mostrar el comprobante de transferencia del encargo
  Widget _buildComprobanteSection(BuildContext context) {
    return GestureDetector(
      onTap: onVerComprobante,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.doc_checkmark_fill,
                color: Colors.green,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comprobante de Transferencia',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'El cliente ya subió el comprobante',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Colors.green,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotales(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total del envío:'),
              Text(
                '\$${encargo.totalConRecargo.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (encargo.comisionRepartidor != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tu ganancia:', style: TextStyle(color: _success)),
                Text(
                  '\$${encargo.comisionRepartidor!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _success,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context) {
    if (_yaEntregado) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _success),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: _success, size: 20),
            SizedBox(width: 8),
            Text(
              'Entregado',
              style: TextStyle(color: _success, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Botón Navegar
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: CupertinoColors.systemGrey5.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            onPressed: onNavegar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.navigation, color: _accent, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Navegar',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Botón de acción principal
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: _yaRecogio ? _success : _colorEncargo,
            borderRadius: BorderRadius.circular(12),
            onPressed: _yaRecogio ? onMarcarEntregado : onMarcarRecogido,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _yaRecogio
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.cube_box_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _yaRecogio ? 'Entregado' : 'Recogido',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
