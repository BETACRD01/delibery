import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../apis/helpers/api_exception.dart';
import '../../config/api_config.dart';
import '../../services/usuarios_service.dart';

class PantallaRifaDetalleUsuario extends StatefulWidget {
  final String rifaId;
  final Map<String, dynamic>? resumen;

  const PantallaRifaDetalleUsuario({
    super.key,
    required this.rifaId,
    this.resumen,
  });

  @override
  State<PantallaRifaDetalleUsuario> createState() =>
      _PantallaRifaDetalleUsuarioState();
}

class _PantallaRifaDetalleUsuarioState
    extends State<PantallaRifaDetalleUsuario> {
  final _usuarioService = UsuarioService();

  Map<String, dynamic>? _detalle;
  bool _loading = true;
  bool _participando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _usuarioService.obtenerDetalleRifa(widget.rifaId);
      final payload = detail['rifa'] ?? detail;
      setState(() {
        _detalle = payload is Map<String, dynamic> ? payload : detail;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.getUserFriendlyMessage());
    } catch (_) {
      setState(() => _error = 'No se pudo cargar la rifa');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _participar() async {
    setState(() => _participando = true);
    try {
      await _usuarioService.participarEnRifa(widget.rifaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participación registrada')),
      );
      await _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.getUserFriendlyMessage())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la participación')),
      );
    } finally {
      if (mounted) setState(() => _participando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Detalle de rifa',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: Color(0xFF1C1C1E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Color(0xFFFF3B30)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final rifa = _detalle ?? widget.resumen;
    if (rifa == null) {
      return const Center(child: Text('No hay información disponible'));
    }

    final titulo = (rifa['titulo'] ?? 'Rifa').toString();
    final descripcion = (rifa['descripcion'] ?? '').toString();
    final premios = (rifa['premios'] as List<dynamic>?) ?? [];
    final premiosImagenes =
        (rifa['premios_imagenes'] as List<dynamic>?) ?? [];
    final premiosParaGaleria = premios.isNotEmpty
        ? premios
        : premiosImagenes
            .map((imagen) => {'imagen_url': imagen})
            .toList();
    final estadoRaw = (rifa['estado'] ?? '').toString().toLowerCase();
    final estado = (rifa['estado_display'] ?? rifa['estado'] ?? 'Activa')
        .toString();
    final esFinalizada = estadoRaw.contains('finalizada');
    final esCancelada = estadoRaw.contains('cancelada');
    final pedidosMinimos = int.tryParse(
          (rifa['meta_pedidos'] ?? rifa['pedidos_minimos'] ?? 3).toString(),
        ) ??
        3;
    final pedidosCompletados = int.tryParse(
          (rifa['pedidos_usuario_mes'] ?? rifa['mis_pedidos'] ?? 0).toString(),
        ) ??
        0;
    final pedidosMostrados = pedidosMinimos > 0
        ? pedidosCompletados.clamp(0, pedidosMinimos)
        : 0;
    final pedidosFaltantes = int.tryParse(
          (rifa['pedidos_faltantes'] ?? 0).toString(),
        ) ??
        (pedidosMinimos - pedidosCompletados).clamp(0, pedidosMinimos);
    final mensajeUsuario = (rifa['mensaje_usuario'] ?? '').toString();
    final ganoUsuario = rifa['gano_usuario'] == true;
    final participaUsuario = rifa['participa_usuario'] == true;
    final premioGanado =
        rifa['premio_ganado'] is Map<String, dynamic>
            ? rifa['premio_ganado'] as Map<String, dynamic>
            : null;
    final razonNoElegible = (rifa['razon'] ?? '').toString();
    final puedoParticipar =
        (rifa['puede_participar'] ?? rifa['puedo_participar']) == true;
    final yaParticipa = rifa['ya_participa'] == true;
    final progresoValue = (rifa['progreso'] is num)
        ? (rifa['progreso'] as num).toDouble().clamp(0.0, 1.0)
        : (pedidosMinimos > 0
            ? (pedidosMostrados / pedidosMinimos).clamp(0.0, 1.0)
            : 0.0);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _cargar),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(rifa, estado),
                const SizedBox(height: 16),
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildPremiosGaleria(premiosParaGaleria),
                const SizedBox(height: 16),
                _buildDetalleSection(rifa),
                const SizedBox(height: 16),
                _buildProgresoSection(
                  pedidosCompletados: pedidosMostrados,
                  pedidosMinimos: pedidosMinimos,
                  pedidosFaltantes: pedidosFaltantes,
                  progreso: progresoValue,
                  puedoParticipar: puedoParticipar,
                  yaParticipa: yaParticipa,
                  razonNoElegible: razonNoElegible,
                  estadoRifa: estadoRaw,
                ),
                if (esFinalizada || esCancelada) ...[
                  const SizedBox(height: 16),
                  _buildResultadoSection(
                    esFinalizada: esFinalizada,
                    esCancelada: esCancelada,
                    ganoUsuario: ganoUsuario,
                    participaUsuario: participaUsuario,
                    mensajeUsuario: mensajeUsuario,
                    premioGanado: premioGanado,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: (!yaParticipa &&
                            puedoParticipar &&
                            !_participando &&
                            !esFinalizada &&
                            !esCancelada)
                        ? _participar
                        : null,
                    child: Text(
                      _participando
                          ? 'Registrando...'
                          : (esFinalizada
                              ? 'Rifa finalizada'
                              : esCancelada
                                  ? 'Rifa cancelada'
                                  : (yaParticipa
                              ? 'Ya participas'
                              : (puedoParticipar
                                  ? 'Participar'
                                  : 'Completa $pedidosFaltantes pedidos'))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(Map<String, dynamic> rifa, String estado) {
    final imageUrl = _resolveImageUrl(
      rifa['imagen_principal'] ?? rifa['imagen_url'] ?? rifa['imagen'],
    );
    final estadoColor = _colorEstado(estado);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: imageUrl != null
                ? Image.network(
                    imageUrl.startsWith('http')
                        ? imageUrl
                        : '${ApiConfig.baseUrl}$imageUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: estadoColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                estado.toUpperCase(),
                style: TextStyle(
                  color: estadoColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiosGaleria(List<dynamic> premios) {
    final premiosLimitados = premios.take(3).toList();
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premios',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: premiosLimitados.map((premio) {
              final premioMap = premio is Map<String, dynamic> ? premio : {};
              final imageUrl = _resolveImageUrl(
                premioMap['imagen_url'] ?? premioMap['imagen'],
              );
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 68,
                    height: 68,
                    color: const Color(0xFFF2F2F7),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl.startsWith('http')
                                ? imageUrl
                                : '${ApiConfig.baseUrl}$imageUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  CupertinoIcons.gift,
                                  color: Color(0xFF8E8E93),
                                ),
                          )
                        : const Icon(
                            CupertinoIcons.gift,
                            color: Color(0xFF8E8E93),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleSection(Map<String, dynamic> rifa) {
    final fechaInicio = _formatFecha(rifa['fecha_inicio']?.toString());
    final fechaFin = _formatFecha(rifa['fecha_fin']?.toString());
    final pedidosMinimos = int.tryParse(
          (rifa['meta_pedidos'] ?? rifa['pedidos_minimos'] ?? 3).toString(),
        ) ??
        3;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Inicio', fechaInicio.isEmpty ? 'N/D' : fechaInicio),
          const SizedBox(height: 8),
          _buildDetailRow('Fin', fechaFin.isEmpty ? 'N/D' : fechaFin),
          const SizedBox(height: 8),
          _buildDetailRow('Pedidos mínimos', '$pedidosMinimos pedidos'),
          const SizedBox(height: 8),
          const Text(
            'Solo cuentan pedidos entregados del mes actual.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoSection({
    required int pedidosCompletados,
    required int pedidosMinimos,
    required int pedidosFaltantes,
    required double progreso,
    required bool puedoParticipar,
    required bool yaParticipa,
    required String razonNoElegible,
    required String estadoRifa,
  }) {
    final estadoColor = (yaParticipa || puedoParticipar)
        ? const Color(0xFF34C759)
        : const Color(0xFF007AFF);
    final estado = estadoRifa.toLowerCase();
    final esFinalizada = estado.contains('finalizada');
    final esCancelada = estado.contains('cancelada');
    final textoEstado = esFinalizada
        ? 'Rifa finalizada'
        : esCancelada
            ? 'Rifa cancelada'
            : '';

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso del usuario',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pedidos del mes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              Text(
                '$pedidosCompletados / $pedidosMinimos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: estadoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: const Color(0xFFF2F2F7),
              valueColor: AlwaysStoppedAnimation<Color>(estadoColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            esFinalizada || esCancelada
                ? textoEstado
                : (yaParticipa
                    ? 'Participación registrada'
                    : (puedoParticipar
                        ? 'Ya puedes participar'
                        : (razonNoElegible.isNotEmpty
                            ? razonNoElegible
                            : 'Te faltan $pedidosFaltantes pedidos'))),
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoSection({
    required bool esFinalizada,
    required bool esCancelada,
    required bool ganoUsuario,
    required bool participaUsuario,
    required String mensajeUsuario,
    Map<String, dynamic>? premioGanado,
  }) {
    final titulo = esCancelada ? 'Estado de la rifa' : 'Resultado del sorteo';
    final descripcion = mensajeUsuario.isNotEmpty
        ? mensajeUsuario
        : esCancelada
            ? 'La rifa fue cancelada.'
            : (participaUsuario
                ? 'La rifa finalizó. Gracias por participar.'
                : 'La rifa finalizó. No participaste.');

    final premioDescripcion = premioGanado?['descripcion']?.toString() ?? '';
    final posicion = premioGanado?['posicion'];

    IconData icono;
    Color colorIcono;
    if (ganoUsuario) {
      icono = Icons.emoji_events;
      colorIcono = const Color(0xFFFFC107);
    } else if (esCancelada) {
      icono = Icons.cancel;
      colorIcono = const Color(0xFFFF3B30);
    } else {
      icono = Icons.sentiment_dissatisfied;
      colorIcono = const Color(0xFF8E8E93);
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esFinalizada || esCancelada)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: esCancelada
                    ? const Color(0xFFFF3B30).withValues(alpha: 0.12)
                    : const Color(0xFF34C759).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    esCancelada ? Icons.block : Icons.check_circle,
                    color: esCancelada
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF34C759),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    esCancelada ? 'Rifa cancelada' : 'Rifa finalizada',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: esCancelada
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
            ),
          if (esFinalizada || esCancelada) const SizedBox(height: 12),
          Row(
            children: [
              Icon(icono, color: colorIcono),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
          ),
          if (ganoUsuario && premioDescripcion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Premio: $premioDescripcion',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
            if (posicion != null)
              Text(
                'Posición: $posicion',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF1C1C1E)),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: const Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 48,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }

  String _formatFecha(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaIso));
    } catch (_) {
      return fechaIso;
    }
  }

  Color _colorEstado(String estado) {
    final normalized = estado.toLowerCase();
    if (normalized.contains('final')) return const Color(0xFF8E8E93);
    if (normalized.contains('cancel')) return const Color(0xFFFF3B30);
    return const Color(0xFF34C759);
  }

  String? _resolveImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Map<String, dynamic>) {
      for (final key in ['url', 'imagen', 'image', 'foto', 'ruta']) {
        final candidate = value[key];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }
    return null;
  }
}
