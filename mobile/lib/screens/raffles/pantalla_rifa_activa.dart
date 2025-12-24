import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/usuarios/usuarios_service.dart';
import '../../apis/helpers/api_exception.dart';
import '../../config/api_config.dart';
import 'pantalla_rifa_detalle_usuario.dart';

class PantallaRifaActiva extends StatefulWidget {
  const PantallaRifaActiva({super.key});

  @override
  State<PantallaRifaActiva> createState() => _PantallaRifaActivaState();
}

class _PantallaRifaActivaState extends State<PantallaRifaActiva>
    with SingleTickerProviderStateMixin {
  final _usuarioService = UsuarioService();
  List<Map<String, dynamic>> _rifas = [];
  bool _loading = true;
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
      _rifas = await _usuarioService.obtenerRifasMesActual(
        forzarRecarga: true,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rifas del mes',
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
    if (_rifas.isEmpty) {
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
              'No hay rifas activas este mes',
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _cargar),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildRifaCard(_rifas[index]),
                  ),
                  childCount: _rifas.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRifaCard(Map<String, dynamic> rifa) {
    final titulo = (rifa['titulo'] ?? 'Rifa').toString();
    final pedidosMinimos =
        int.tryParse((rifa['meta_pedidos'] ?? rifa['pedidos_minimos'] ?? 3).toString()) ?? 3;
    final pedidosCompletados = int.tryParse(
          (rifa['pedidos_usuario_mes'] ?? rifa['mis_pedidos'] ?? 0).toString(),
        ) ??
        0;
    final pedidosMostrados = pedidosMinimos > 0
        ? pedidosCompletados.clamp(0, pedidosMinimos)
        : 0;
    final progreso = (rifa['progreso'] is num)
        ? (rifa['progreso'] as num).toDouble().clamp(0.0, 1.0)
        : (pedidosMinimos > 0
            ? (pedidosMostrados / pedidosMinimos).clamp(0.0, 1.0)
            : 0.0);
    final estadoLabel = (rifa['estado_display'] ?? rifa['estado'] ?? 'Activa')
        .toString();
    final estadoColor = _colorEstado(estadoLabel);
    final imagen = _resolveImageUrl(
      rifa['imagen_principal'] ?? rifa['imagen_url'] ?? rifa['imagen'],
    );

    return GestureDetector(
      onTap: () {
        final rifaId = rifa['id']?.toString();
        if (rifaId == null) return;
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => PantallaRifaDetalleUsuario(
              rifaId: rifaId,
              resumen: rifa,
            ),
          ),
        ).then((_) => _cargar());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRifaCover(imagen, estadoLabel, estadoColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgresoResumen(
                    pedidosCompletados: pedidosMostrados,
                    pedidosMinimos: pedidosMinimos,
                    progreso: progreso,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRifaCover(String? imagen, String estado, Color estadoColor) {
    return Stack(
      children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: imagen != null
              ? Image.network(
                  imagen.startsWith('http')
                      ? imagen
                      : '${ApiConfig.baseUrl}$imagen',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
        Positioned(
          top: 12,
          right: 12,
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
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgresoResumen({
    required int pedidosCompletados,
    required int pedidosMinimos,
    required double progreso,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progreso del mes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
            Text(
              '$pedidosCompletados/$pedidosMinimos pedidos',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progreso,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: const Center(
        child: Icon(
          CupertinoIcons.photo,
          color: Color(0xFF8E8E93),
          size: 40,
        ),
      ),
    );
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
