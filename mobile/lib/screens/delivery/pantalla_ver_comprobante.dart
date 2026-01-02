// lib/screens/delivery/pantalla_ver_comprobante.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../apis/helpers/api_exception.dart';
import '../../services/pago/pago_service.dart';
import '../../models/pago_model.dart';

/// Pantalla para que el repartidor vea el comprobante de transferencia
class PantallaVerComprobante extends StatefulWidget {
  final int pagoId;

  const PantallaVerComprobante({super.key, required this.pagoId});

  @override
  State<PantallaVerComprobante> createState() => _PantallaVerComprobanteState();
}

class _PantallaVerComprobanteState extends State<PantallaVerComprobante> {
  final _pagoService = PagoService();

  ComprobanteRepartidor? _comprobante;
  bool _isLoading = true;
  bool _marcandoVisto = false;
  String? _error;
  bool _comprobantePendiente = false;

  static const Color _success = Color(0xFF34C759);
  static const Color _errorColor = Color(0xFFFF3B30);
  static const Color _warningColor = Color(0xFFFF9500);

  // Dynamic Colors
  Color get _surface =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);
  Color get _cardBg =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
  Color get _textPrimary => CupertinoColors.label.resolveFrom(context);
  Color get _textSecondary =>
      CupertinoColors.secondaryLabel.resolveFrom(context);

  @override
  void initState() {
    super.initState();
    _cargarComprobante();
  }

  Future<void> _cargarComprobante() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _comprobantePendiente = false;
    });

    try {
      final comprobante = await _pagoService.verComprobante(widget.pagoId);
      if (!mounted) return;
      setState(() {
        _comprobante = comprobante;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException &&
          e.statusCode == 400 &&
          e.getUserFriendlyMessage().contains('aún no está disponible')) {
        setState(() {
          _comprobante = null;
          _comprobantePendiente = true;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _error =
            'Error al cargar comprobante: ${e is ApiException ? e.getUserFriendlyMessage() : e}';
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarComoVisto() async {
    setState(() => _marcandoVisto = true);

    try {
      await _pagoService.marcarComprobanteVisto(widget.pagoId);
      if (mounted) {
        _mostrarToast(
          'Comprobante marcado como visto',
          icono: CupertinoIcons.checkmark_circle_fill,
        );
        // Recargar para actualizar la fecha de visualización
        await _cargarComprobante();
      }
    } catch (e) {
      if (mounted) {
        _mostrarToast(
          'Error al marcar como visto',
          color: _errorColor,
          icono: CupertinoIcons.exclamationmark_circle_fill,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _marcandoVisto = false);
      }
    }
  }

  void _mostrarToast(String mensaje, {IconData? icono, Color? color}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color ?? _success,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Comprobante'),
          backgroundColor: _cardBg,
          border: const Border(
            bottom: BorderSide(color: Color(0x4D000000), width: 0.0),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildBody()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 64,
                color: _errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: _textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _cargarComprobante,
                borderRadius: BorderRadius.circular(12),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_comprobantePendiente) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.hourglass,
                size: 64,
                color: _warningColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Comprobante no disponible',
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El cliente todavía no ha subido el comprobante de transferencia.',
                style: TextStyle(color: _textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _cargarComprobante,
                borderRadius: BorderRadius.circular(12),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_comprobante == null) {
      return Center(
        child: Text(
          'No se encontró el comprobante',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cliente'),
          _buildInfoCard(),
          const SizedBox(height: 24),

          _buildSectionTitle('Comprobante'),
          if (_comprobante!.comprobanteUrl != null) _buildComprobanteImage(),
          if (_comprobante!.comprobanteUrl == null) _buildNoComprobanteCard(),

          const SizedBox(height: 20),

          if (_comprobante!.fechaVisualizacionRepartidor != null)
            _buildVisualizacionCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGroupedBackground,
              borderRadius: BorderRadius.circular(24), // Circular
              image: _comprobante!.clienteFoto != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                        _comprobante!.clienteFoto!,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _comprobante!.clienteFoto == null
                ? const Icon(
                    CupertinoIcons.person_fill,
                    color: CupertinoColors.systemGrey,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _comprobante!.clienteNombre ?? 'Sin nombre',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteImage() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => _mostrarImagenCompleta(_comprobante!.comprobanteUrl!),
          child: AspectRatio(
            aspectRatio:
                3 / 4, // Aspect ratio fijo para mejor consistencia visual
            child: CachedNetworkImage(
              imageUrl: _comprobante!.comprobanteUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                color: CupertinoColors.systemGroupedBackground,
                child: const Center(child: CupertinoActivityIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: CupertinoColors.systemGroupedBackground,
                child: const Center(
                  child: Icon(
                    CupertinoIcons.exclamationmark_circle,
                    color: _errorColor,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoComprobanteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.doc_text_search,
            size: 56,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'Comprobante no disponible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El cliente aún no ha subido el comprobante de transferencia',
            style: TextStyle(fontSize: 14, color: _textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizacionCard() {
    final fecha = _comprobante!.fechaVisualizacionRepartidor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: _success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comprobante visto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visto el ${_formatearFecha(fecha!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _success.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_comprobante == null || _comprobante!.comprobanteUrl == null) {
      return const SizedBox.shrink();
    }

    // Si ya fue visto, no mostrar el botón
    if (_comprobante!.fechaVisualizacionRepartidor != null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: _marcandoVisto ? null : _marcarComoVisto,
          borderRadius: BorderRadius.circular(14),
          child: _marcandoVisto
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Text(
                  'Marcar como visto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  void _mostrarImagenCompleta(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, _) {
          return CupertinoPageScaffold(
            backgroundColor: Colors.black,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              middle: const Text(
                'Vista previa',
                style: TextStyle(color: Colors.white),
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.xmark, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) =>
                      const CupertinoActivityIndicator(
                        color: Colors.white,
                        radius: 20,
                      ),
                  errorWidget: (context, url, error) => const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (diferencia.inHours < 1) {
      return 'Hace ${diferencia.inMinutes} minutos';
    } else if (diferencia.inDays < 1) {
      return 'Hace ${diferencia.inHours} horas';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year} a las ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    }
  }
}
