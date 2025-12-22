import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../services/usuarios_service.dart';
import '../../apis/helpers/api_exception.dart';

class PantallaRifaActiva extends StatefulWidget {
  const PantallaRifaActiva({super.key});

  @override
  State<PantallaRifaActiva> createState() => _PantallaRifaActivaState();
}

class _PantallaRifaActivaState extends State<PantallaRifaActiva>
    with SingleTickerProviderStateMixin {
  final _usuarioService = UsuarioService();
  Map<String, dynamic>? _rifa;
  bool _loading = true;
  bool _participando = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cargar();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _usuarioService.obtenerRifaActiva(forzarRecarga: true);
      _rifa =
          (data?['rifa'] ?? data?['rifa_activa'] ?? data)
              as Map<String, dynamic>?;
      await _animationController.forward();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'No se pudo cargar la rifa activa';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _participar() async {
    final rifaId = _rifa?['id']?.toString();
    if (rifaId == null) return;

    setState(() => _participando = true);
    try {
      await _usuarioService.participarEnRifa(rifaId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Participación registrada')));
      await _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la participación')),
      );
    } finally {
      if (mounted) {
        setState(() => _participando = false);
      }
    }
  }

  String _formatFecha(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return '';
    try {
      final fecha = DateTime.parse(fechaIso);
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (_) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rifa del mes',
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
      return _buildLoadingShimmer();
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_rifa == null) {
      return _buildEmptyState();
    }

    return _buildContent();
  }

  Widget _buildLoadingShimmer() {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 120, 20, 20),
      child: Column(
        children: [
          _ShimmerBox(height: 240, borderRadius: 24),
          SizedBox(height: 16),
          _ShimmerBox(height: 160, borderRadius: 20),
          SizedBox(height: 16),
          _ShimmerBox(height: 180, borderRadius: 20),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 40,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Algo salió mal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            _IOSButton(
              onPressed: _cargar,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Reintentar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_outlined,
                size: 40,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay rifas activas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'En este momento no hay rifas disponibles.\nVuelve pronto para participar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final titulo = _rifa!['titulo'] ?? 'Rifa';
    final premios = (_rifa!['premios'] as List<dynamic>?) ?? [];
    final premiosOrdenados = List<Map<String, dynamic>>.from(premios)
      ..sort((a, b) => (a['posicion'] ?? 0).compareTo(b['posicion'] ?? 0));
    final fechaFin = _formatFecha(_rifa!['fecha_fin']?.toString());
    final diasRestantes = _rifa!['dias_restantes']?.toString() ?? '';
    final totalParticipantes = (_rifa!['total_participantes'] ?? 0).toString();
    final pedidosMinimos =
        int.tryParse((_rifa!['pedidos_minimos'] ?? 3).toString()) ?? 3;
    final pedidosCompletados =
        int.tryParse((_rifa!['mis_pedidos'] ?? 0).toString()) ?? 0;
    final pedidosFaltantes =
        int.tryParse((_rifa!['pedidos_faltantes'] ?? 0).toString()) ?? 0;
    final puedoParticipar = _rifa!['puedo_participar'] == true;
    final yaParticipa = _rifa!['ya_participa'] == true;
    final estadoDisplay = (_rifa!['estado_display'] ?? 'Activa')
        .toString()
        .toUpperCase();
    final progreso = (pedidosMinimos > 0)
        ? (pedidosCompletados / pedidosMinimos).clamp(0.0, 1.0)
        : 0.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(
                titulo: titulo,
                premios: premiosOrdenados,
                fechaFin: fechaFin,
                diasRestantes: diasRestantes,
                totalParticipantes: totalParticipantes,
                estadoDisplay: estadoDisplay,
              ),
              const SizedBox(height: 16),
              _buildElegibilityCard(
                puedoParticipar: puedoParticipar,
                yaParticipa: yaParticipa,
                pedidosCompletados: pedidosCompletados,
                pedidosMinimos: pedidosMinimos,
                pedidosFaltantes: pedidosFaltantes,
                progreso: progreso,
              ),
              const SizedBox(height: 16),
              _buildInstructionsCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required String titulo,
    required List<Map<String, dynamic>> premios,
    required String fechaFin,
    required String diasRestantes,
    required String totalParticipantes,
    required String estadoDisplay,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            estadoDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (diasRestantes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Color(0xFF007AFF),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$diasRestantes días',
                              style: const TextStyle(
                                color: Color(0xFF007AFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                if (premios.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: premios
                        .map(
                          (premio) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${premio['posicion_display'] ?? 'Premio'}: ${premio['descripcion'] ?? ''}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                _buildInfoGrid(fechaFin, totalParticipantes, premios.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(
    String fechaFin,
    String participantes,
    int totalPremios,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (fechaFin.isNotEmpty)
          SizedBox(
            width: 150,
            child: _buildInfoItem(Icons.calendar_today, 'Finaliza', fechaFin),
          ),
        SizedBox(
          width: 150,
          child: _buildInfoItem(Icons.groups, 'Participantes', participantes),
        ),
        SizedBox(
          width: 150,
          child: _buildInfoItem(
            Icons.card_giftcard,
            'Premios',
            totalPremios.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegibilityCard({
    required bool puedoParticipar,
    required bool yaParticipa,
    required int pedidosCompletados,
    required int pedidosMinimos,
    required int pedidosFaltantes,
    required double progreso,
  }) {
    final estadoColor = (yaParticipa || puedoParticipar)
        ? const Color(0xFF34C759)
        : const Color(0xFFFF9500);
    final estadoIcon = (yaParticipa || puedoParticipar)
        ? Icons.check_circle
        : Icons.hourglass_empty;
    final estadoTitulo = yaParticipa
        ? 'Ya estás participando'
        : (puedoParticipar ? '¡Cumples los requisitos!' : 'En progreso');
    final estadoSubtitulo = yaParticipa
        ? 'Tu participación está registrada'
        : (puedoParticipar ? 'Ya puedes participar' : 'Completa más pedidos');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(estadoIcon, color: estadoColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estadoTitulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estadoSubtitulo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pedidos completados',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      Text(
                        '$pedidosCompletados / $pedidosMinimos',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0.0, end: progreso),
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (yaParticipa || puedoParticipar)
                                ? const Color(0xFF34C759)
                                : const Color(0xFF007AFF),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progreso * 100).round()}% completado',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            if (!yaParticipa && puedoParticipar) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _participando ? null : _participar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_participando ? 'Registrando...' : 'Participar'),
                ),
              ),
            ],
            if (!puedoParticipar && pedidosFaltantes > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Te faltan $pedidosFaltantes pedido(s) para participar',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cómo participar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _IOSListItem(
              number: 1,
              text:
                  'Realiza tus pedidos habituales hasta cumplir el mínimo requerido',
            ),
            const SizedBox(height: 12),
            const _IOSListItem(
              number: 2,
              text:
                  'Una vez cumplido, presiona el botón Participar para registrarte',
            ),
            const SizedBox(height: 12),
            const _IOSListItem(
              number: 3,
              text:
                  'Revisa esta sección para ver la fecha de sorteo y participantes',
            ),
          ],
        ),
      ),
    );
  }
}

class _IOSListItem extends StatelessWidget {
  final int number;
  final String text;

  const _IOSListItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1C1C1E),
                height: 1.4,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IOSButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _IOSButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF007AFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double borderRadius;

  const _ShimmerBox({required this.height, required this.borderRadius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE5E5EA),
                Color(0xFFF2F2F7),
                Color(0xFFE5E5EA),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
