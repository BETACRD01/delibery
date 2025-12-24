// lib/screens/delivery/pantalla_ver_comprobante.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/jp_theme.dart' hide JPSnackbar;
import '../../apis/helpers/api_exception.dart';
import '../../services/pago/pago_service.dart';
import '../../models/pago_model.dart';
import '../../widgets/jp_snackbar.dart';

/// Pantalla para que el repartidor vea el comprobante de transferencia
class PantallaVerComprobante extends StatefulWidget {
  final int pagoId;

  const PantallaVerComprobante({
    super.key,
    required this.pagoId,
  });

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
      setState(() {
        _comprobante = comprobante;
        _isLoading = false;
      });
    } catch (e) {
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
        _error = 'Error al cargar comprobante: ${e is ApiException ? e.getUserFriendlyMessage() : e}';
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarComoVisto() async {
    setState(() => _marcandoVisto = true);

    try {
      await _pagoService.marcarComprobanteVisto(widget.pagoId);
      if (mounted) {
        JPSnackbar.success(context, 'Comprobante marcado como visto');
        // Recargar para actualizar la fecha de visualización
        await _cargarComprobante();
      }
    } catch (e) {
      if (mounted) {
        JPSnackbar.error(context, 'Error al marcar como visto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _marcandoVisto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Comprobante',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F2F7),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 14),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: JPColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: JPColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarComprobante,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JPColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_comprobantePendiente) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 64,
              color: JPColors.warning,
            ),
            const SizedBox(height: 16),
            const Text(
              'El comprobante aún no está disponible',
              style: TextStyle(
                color: JPColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'El cliente todavía no ha subido el comprobante.',
              style: TextStyle(color: JPColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarComprobante,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JPColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_comprobante == null) {
      return const Center(
        child: Text(
          'No se encontró el comprobante',
          style: TextStyle(color: JPColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cliente'),
          // Info del cliente
          _buildInfoCard(),
          const SizedBox(height: 20),

          // Imagen del comprobante
          _buildSectionTitle('Comprobante'),
          if (_comprobante!.comprobanteUrl != null) _buildComprobanteImage(),
          if (_comprobante!.comprobanteUrl == null) _buildNoComprobanteCard(),

          const SizedBox(height: 20),

          // Estado de visualización
          if (_comprobante!.fechaVisualizacionRepartidor != null)
            _buildVisualizacionCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF1C1C1E),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _comprobante!.clienteNombre ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => _mostrarImagenCompleta(_comprobante!.comprobanteUrl!),
          child: CachedNetworkImage(
            imageUrl: _comprobante!.comprobanteUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(
              height: 320,
              color: const Color(0xFFEFF1F4),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 14),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 320,
              color: const Color(0xFFEFF1F4),
              child: const Center(
                child: Icon(Icons.error, color: JPColors.error, size: 48),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: Color(0xFF8E8E93),
          ),
          const SizedBox(height: 12),
          const Text(
            'Comprobante no disponible',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'El cliente aún no ha subido el comprobante de transferencia',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizacionCard() {
    final fecha = _comprobante!.fechaVisualizacionRepartidor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFE9CF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comprobante visto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visto el ${_formatearFecha(fecha!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_comprobante == null || _comprobante!.comprobanteUrl == null) {
      return null;
    }

    // Si ya fue visto, no mostrar el botón
    if (_comprobante!.fechaVisualizacionRepartidor != null) {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: ElevatedButton(
          onPressed: _marcandoVisto ? null : _marcarComoVisto,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34C759),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _marcandoVisto
              ? const CupertinoActivityIndicator(
                  radius: 10,
                  color: Colors.white,
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Marcar como visto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _mostrarImagenCompleta(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const CupertinoActivityIndicator(radius: 14),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
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
