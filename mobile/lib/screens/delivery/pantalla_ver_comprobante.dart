// lib/screens/delivery/pantalla_ver_comprobante.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/jp_theme.dart' hide JPSnackbar;
import '../../services/pago_service.dart';
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

  @override
  void initState() {
    super.initState();
    _cargarComprobante();
  }

  Future<void> _cargarComprobante() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comprobante = await _pagoService.verComprobante(widget.pagoId);
      setState(() {
        _comprobante = comprobante;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar comprobante: $e';
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
      backgroundColor: JPColors.background,
      appBar: AppBar(
        title: const Text('Comprobante de Pago'),
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: JPColors.primary),
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

    if (_comprobante == null) {
      return const Center(
        child: Text(
          'No se encontró el comprobante',
          style: TextStyle(color: JPColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del cliente
          _buildInfoCard(),
          const SizedBox(height: 16),

          // Imagen del comprobante
          if (_comprobante!.comprobanteUrl != null)
            _buildComprobanteImage()
          else
            _buildNoComprobanteCard(),

          const SizedBox(height: 16),

          // Estado de visualización
          if (_comprobante!.fechaVisualizacionRepartidor != null)
            _buildVisualizacionCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JPColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: JPColors.primary,
                    size: 24,
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
                          color: JPColors.textSecondary,
                        ),
                      ),
                      Text(
                        _comprobante!.clienteNombre ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: JPColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComprobanteImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comprobante de Transferencia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: JPColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () => _mostrarImagenCompleta(_comprobante!.comprobanteUrl!),
            child: CachedNetworkImage(
              imageUrl: _comprobante!.comprobanteUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(color: JPColors.primary),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error, color: JPColors.error, size: 48),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca la imagen para ampliar',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNoComprobanteCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Comprobante no disponible',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El cliente aún no ha subido el comprobante de transferencia',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizacionCard() {
    final fecha = _comprobante!.fechaVisualizacionRepartidor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JPColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: JPColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comprobante visto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: JPColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Visto el ${_formatearFecha(fecha!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: JPColors.success.withValues(alpha: 0.8),
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
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _marcandoVisto ? null : _marcarComoVisto,
          style: ElevatedButton.styleFrom(
            backgroundColor: JPColors.success,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _marcandoVisto
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const CircularProgressIndicator(
                    color: Colors.white,
                  ),
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
