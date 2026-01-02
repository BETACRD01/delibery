import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../models/pedido_model.dart';
import '../../../providers/proveedor_pedido.dart';
import '../../../theme/jp_theme.dart';
import '../../../widgets/ratings/dialogo_calificar_repartidor.dart';
import '../../../../widgets/common/jp_cupertino_button.dart';
import '../../../services/pago/pago_service.dart';
import 'pantalla_subir_comprobante_courier.dart';

class PantallaDetalleCourier extends StatefulWidget {
  final int pedidoId;

  const PantallaDetalleCourier({super.key, required this.pedidoId});

  @override
  State<PantallaDetalleCourier> createState() => _PantallaDetalleCourierState();
}

class _PantallaDetalleCourierState extends State<PantallaDetalleCourier> {
  final PagoService _pagoService = PagoService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<PedidoProvider>();
        provider.limpiarError();
        provider.cargarDetalle(widget.pedidoId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Detalle del Encargo'),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Consumer<PedidoProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (provider.error != null) {
              return Center(child: Text(provider.error!));
            }

            final pedido = provider.pedidoActual;
            if (pedido == null) {
              return const Center(child: Text('Encargo no encontrado'));
            }

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderStatus(pedido),
                  const SizedBox(height: 16),
                  _buildMapaInfo(pedido), // Placeholder visual o mapa estático
                  const SizedBox(height: 16),
                  _buildDetalleEncargo(pedido),
                  const SizedBox(height: 16),
                  if (pedido.repartidor != null) ...[
                    _buildRepartidorCard(pedido),
                    const SizedBox(height: 16),
                    // Calificación
                    if (pedido.estado.toLowerCase() == 'entregado' &&
                        (pedido.puedeCalificarRepartidor ||
                            pedido.calificacionRepartidor == null)) ...[
                      _buildCalificacionRepartidorCTA(pedido),
                      const SizedBox(height: 16),
                    ] else if (pedido.calificacionRepartidor != null) ...[
                      _buildCalificacionRepartidorResumen(pedido),
                      const SizedBox(height: 16),
                    ],
                  ],
                  _buildDesgloseCostos(pedido),
                  const SizedBox(height: 16),
                  _buildAccionesCard(pedido),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderStatus(Pedido pedido) {
    Color colorEstado = _getColorEstado(pedido.estado);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Encargo #${pedido.numeroPedido}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: JPCupertinoColors.label(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorEstado.withValues(alpha: 0.3)),
                ),
                child: Text(
                  pedido.estadoDisplay,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Creado hace: ${pedido.tiempoTranscurrido}',
            style: TextStyle(
              color: JPCupertinoColors.secondaryLabel(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaInfo(Pedido pedido) {
    // Si no tenemos mapa real aun, mostramos un visualizador de ruta bonito
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Column(
        children: [
          _buildPuntoRuta(
            icon: Icons.my_location,
            color: CupertinoColors.systemGrey,
            titulo: 'RETIRO',
            direccion: _limpiarDireccion(
              pedido.direccionOrigen ?? 'Ubicación origen',
            ),
          ),
          Container(
            height: 30,
            margin: const EdgeInsets.only(left: 11),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: JPCupertinoColors.separator(context),
                  width: 2,
                  style: BorderStyle.solid, // O dashed si pudiera
                ),
              ),
            ),
          ),
          _buildPuntoRuta(
            icon: Icons.location_on,
            color: CupertinoColors.activeBlue,
            titulo: 'ENTREGA',
            direccion: _limpiarDireccion(pedido.direccionEntrega),
          ),
          if (pedido.datosEnvio != null &&
              pedido.datosEnvio!.distanciaKm != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  Icons.directions_car,
                  '${pedido.datosEnvio!.distanciaKm} km',
                ),
                _buildStat(
                  Icons.schedule,
                  '${pedido.datosEnvio!.tiempoEstimadoMins} min',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _limpiarDireccion(String raw) {
    // Eliminar país y códigos postales comunes para limpiar la vista
    var texto = raw.replaceAll(', Ecuador', '').replaceAll(', EC', '');
    return texto.trim();
  }

  Widget _buildPuntoRuta({
    required IconData icon,
    required Color color,
    required String titulo,
    required String direccion,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: JPCupertinoColors.secondaryLabel(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                direccion,
                style: TextStyle(
                  fontSize: 15,
                  color: JPCupertinoColors.label(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: JPCupertinoColors.secondaryLabel(context)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: JPCupertinoColors.secondaryLabel(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleEncargo(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información del Paquete'),
          const SizedBox(height: 12),
          _buildInfoRow('Descripción', pedido.descripcion),

          // Aquí podriamos poner el tipo de paquete si viniera en el modelo,
          // por ahora usamos descripción.
          if (pedido.instruccionesEntrega != null &&
              pedido.instruccionesEntrega!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildInfoRow(
                'Instrucciones',
                pedido.instruccionesEntrega!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRepartidorCard(Pedido pedido) {
    final repartidor = pedido.repartidor!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Repartidor Asignado'),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: CupertinoColors.activeGreen.withValues(
                  alpha: 0.1,
                ),
                child: repartidor.fotoPerfil != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: repartidor.fotoPerfil!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: CupertinoColors.activeGreen,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repartidor.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: JPCupertinoColors.label(context),
                      ),
                    ),
                    if (repartidor.telefono != null)
                      Text(
                        repartidor.telefono!,
                        style: TextStyle(
                          fontSize: 13,
                          color: JPCupertinoColors.secondaryLabel(context),
                        ),
                      ),
                  ],
                ),
              ),
              // Botones de acción (Llamar / Whatsapp)
              if (repartidor.telefono != null) ...[
                IconButton(
                  icon: const Icon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.green,
                  ),
                  onPressed: () => _abrirWhatsapp(repartidor.telefono!),
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.phone_fill,
                    color: Colors.blue,
                  ),
                  onPressed: () => _llamar(repartidor.telefono!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesgloseCostos(Pedido pedido) {
    if (pedido.datosEnvio == null) return const SizedBox.shrink();
    final envio = pedido.datosEnvio!;

    // Calcular total real incluyendo recargo nocturno
    final costoBase = envio.costoEnvio ?? 0.0;
    final recargoNocturno = envio.recargoNocturnoAplicado
        ? (envio.recargoNocturno ?? 0.0)
        : 0.0;
    final totalCalculado = costoBase + recargoNocturno;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Resumen de Costos'),
          const SizedBox(height: 12),
          _buildCostoRow('Tarifa Base', costoBase),

          if (envio.recargoNocturnoAplicado && recargoNocturno > 0)
            _buildCostoRow('Recargo Nocturno', recargoNocturno),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: JPCupertinoColors.label(context),
                ),
              ),
              Text(
                '\$${totalCalculado.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 12),
          _buildInfoRow('Método de Pago', pedido.metodoPagoDisplay),
        ],
      ),
    );
  }

  Widget _buildAccionesCard(Pedido pedido) {
    bool esTransferencia = pedido.metodoPago.toLowerCase() == 'transferencia';
    bool sinComprobante =
        pedido.transferenciaComprobanteUrl == null ||
        pedido.transferenciaComprobanteUrl!.isEmpty;
    bool tieneRepartidor =
        pedido.repartidor != null || pedido.aceptadoPorRepartidor;
    bool pedidoEnCurso =
        pedido.estado != 'cancelado' && pedido.estado != 'entregado';

    // Mostrar botón si: Es transferencia, no ha subido comprobante, tiene repartidor asignado, y el pedido sigue activo
    bool mostrarSubirComprobante =
        esTransferencia &&
        sinComprobante &&
        tieneRepartidor &&
        pedidoEnCurso &&
        pedido.pagoId != null;

    if (!mostrarSubirComprobante) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Acciones'),
          const SizedBox(height: 12),
          JPCupertinoButton.filled(
            text: 'Datos de Transferencia',
            icon: Icons.upload_file,
            onPressed: () => _abrirSubirComprobante(pedido),
          ),
          const SizedBox(height: 8),
          Text(
            'Sube el comprobante de la transferencia para confirmar el pago al repartidor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: JPCupertinoColors.secondaryLabel(context),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: JPCupertinoColors.secondaryLabel(context),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: JPCupertinoColors.label(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostoRow(String label, double? amount) {
    if (amount == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: JPCupertinoColors.secondaryLabel(context)),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(color: JPCupertinoColors.label(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionRepartidorCTA(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: CupertinoColors.activeGreen.withValues(alpha: 0.1),
            child: const Icon(
              Icons.star,
              color: CupertinoColors.activeGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Califica tu experiencia',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: JPCupertinoColors.label(context),
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Valorar al repartidor',
                  style: TextStyle(
                    fontSize: 13,
                    color: JPCupertinoColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: () async {
              final result = await showCupertinoModalPopup<bool>(
                context: context,
                builder: (context) => DialogoCalificarRepartidor(
                  pedidoId: pedido.id,
                  repartidorNombre: pedido.repartidor?.nombre ?? 'Repartidor',
                  repartidorFoto: pedido.repartidor?.fotoPerfil,
                ),
              );
              if (result == true && mounted) {
                final provider = context.read<PedidoProvider>();
                provider.limpiarError();
                await provider.cargarDetalle(widget.pedidoId);
              }
            },
            child: const Text(
              'Calificar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionRepartidorResumen(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: CupertinoColors.activeGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Has calificado al repartidor: ',
            style: TextStyle(
              color: JPCupertinoColors.secondaryLabel(context),
              fontSize: 14,
            ),
          ),
          Text(
            '${pedido.calificacionRepartidor?.toStringAsFixed(1) ?? ''} ⭐',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: JPCupertinoColors.label(context),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFFF9500);
      case 'en_ruta':
        return const Color(0xFF34C759);
      case 'entregado':
        return const Color(0xFF34C759);
      case 'cancelado':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  void _abrirWhatsapp(String telefono) async {
    final url = Uri.parse('https://wa.me/$telefono');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _llamar(String telefono) async {
    final url = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _abrirSubirComprobante(Pedido pedido) async {
    if (pedido.pagoId == null) return;
    final pagoId = pedido.pagoId!;

    try {
      final datos = await _pagoService.obtenerDatosBancariosPago(pagoId);
      if (!mounted) return;

      final result = await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => PantallaSubirComprobanteCourier(
            pagoId: pagoId,
            datosBancarios: datos,
          ),
        ),
      );

      // Al volver, refrescamos el detalle para actualizar el estado del comprobante
      if (result == true && mounted) {
        final provider = context.read<PedidoProvider>();
        provider.limpiarError();
        await provider.cargarDetalle(widget.pedidoId);
      }
    } catch (e) {
      if (!mounted) return;

      // Extraer mensaje limpio del error de forma segura
      String mensaje = 'No se pudo obtener datos bancarios';
      bool esFaltaDatosBancarios = false;
      if (e.toString().contains('ApiException:')) {
        final match = RegExp(
          r'ApiException: (.+?) \|',
        ).firstMatch(e.toString());
        if (match != null) {
          mensaje = match.group(1) ?? mensaje;
          if (mensaje.contains('no ha configurado sus datos bancarios')) {
            esFaltaDatosBancarios = true;
          }
        }
      } else {
        mensaje = e.toString();
      }

      if (esFaltaDatosBancarios) {
        await showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Datos faltantes'),
            content: Text(
              '$mensaje.\n\nPor favor, contacta al repartidor para que configure su cuenta bancaria o paga el pedido en efectivo si es posible.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Entendido'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: CupertinoColors.systemOrange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
