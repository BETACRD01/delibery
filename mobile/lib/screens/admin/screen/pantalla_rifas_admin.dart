import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../apis/admin/rifas_admin_api.dart';
import '../../../config/api_config.dart';
import '../dashboard/constants/dashboard_colors.dart';
import 'pantalla_crear_rifa.dart';
import 'pantalla_rifa_detalle.dart';

class PantallaRifasAdmin extends StatefulWidget {
  const PantallaRifasAdmin({super.key});

  @override
  State<PantallaRifasAdmin> createState() => _PantallaRifasAdminState();
}

class _PantallaRifasAdminState extends State<PantallaRifasAdmin> {
  final _api = RifasAdminApi();

  List<dynamic> _rifas = [];
  bool _cargando = true;
  String? _error;
  String _filtroEstado = 'activa';
  int _paginaActual = 1;
  int _totalPaginas = 1;

  static const List<String> _estadosDisponibles = ['activa', 'finalizada', 'cancelada'];
  static const Map<String, String> _etiquetasEstado = {
    'activa': 'Activas',
    'finalizada': 'Finalizadas',
    'cancelada': 'Canceladas',
  };
  static const Map<String, String> _nombreEstadoSingular = {
    'activa': 'Activa',
    'finalizada': 'Finalizada',
    'cancelada': 'Cancelada',
  };

  @override
  void initState() {
    super.initState();
    _cargarRifas();
  }

  Future<void> _cargarRifas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final response = await _api.listarRifas(
        estado: _filtroEstado,
        pagina: _paginaActual,
      );

      if (!mounted) return;

      setState(() {
        _rifas = response['results'] ?? [];
        _totalPaginas = ((response['count'] ?? 0) / 10).ceil();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar rifas';
        _cargando = false;
      });
    }
  }

  void _cambiarFiltro(String nuevoFiltro) {
    if (nuevoFiltro != _filtroEstado) {
      setState(() {
        _filtroEstado = nuevoFiltro;
        _paginaActual = 1;
      });
      _cargarRifas();
    }
  }

  void _cambiarPagina(int nuevaPagina) {
    if (nuevaPagina >= 1 && nuevaPagina <= _totalPaginas) {
      setState(() => _paginaActual = nuevaPagina);
      _cargarRifas();
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'activa':
        return CupertinoColors.systemGreen;
      case 'finalizada':
        return CupertinoColors.systemBlue;
      case 'cancelada':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String _nombreEstado(String estado) => _nombreEstadoSingular[estado] ?? estado;

  void _mostrarCrearRifa() async {
    final result = await Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (_) => const PantallaCrearRifa())
          : MaterialPageRoute(builder: (_) => const PantallaCrearRifa()),
    );
    if (result == true) await _cargarRifas();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSLayout();
    }
    return _buildMaterialLayout();
  }

  Widget _buildIOSLayout() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Gestión de rifas'),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        border: const Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _mostrarCrearRifa,
          child: const Icon(CupertinoIcons.add_circled_solid),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildFiltrosIOS(),
            Expanded(child: _buildContenido(true)),
            if (_totalPaginas > 1) _buildPaginacionIOS(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de rifas'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 75, 160, 225),
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarCrearRifa,
        backgroundColor: const Color.fromARGB(255, 39, 142, 176),
        icon: const Icon(Icons.add),
        label: const Text('Crear rifa'),
      ),
      body: Column(
        children: [
          _buildFiltrosMaterial(),
          Expanded(child: _buildContenido(false)),
          if (_totalPaginas > 1) _buildPaginacionMaterial(),
        ],
      ),
    );
  }

  Widget _buildFiltrosIOS() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: const Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var estado in _estadosDisponibles) ...[
              _buildChipFiltroIOS(_etiquetasEstado[estado] ?? estado, estado),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosMaterial() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var estado in _estadosDisponibles) ...[
              _buildChipFiltroMaterial(_etiquetasEstado[estado] ?? estado, estado),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChipFiltroIOS(String label, String valor) {
    final seleccionado = _filtroEstado == valor;
    return GestureDetector(
      onTap: () => _cambiarFiltro(valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? CupertinoColors.activeBlue : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
            fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildChipFiltroMaterial(String label, String valor) {
    final seleccionado = _filtroEstado == valor;
    return FilterChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) => _cambiarFiltro(valor),
      backgroundColor: Colors.white,
      selectedColor: DashboardColors.morado.withValues(alpha: 0.2),
      checkmarkColor: DashboardColors.morado,
      labelStyle: TextStyle(
        color: seleccionado ? DashboardColors.morado : Colors.black87,
        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildContenido(bool isIOS) {
    if (_cargando) {
      return Center(child: isIOS ? const CupertinoActivityIndicator(radius: 16) : const CupertinoActivityIndicator(radius: 14));
    }

    if (_error != null) {
      return _buildEstadoError(isIOS);
    }

    if (_rifas.isEmpty) {
      return _buildEstadoVacio(isIOS);
    }

    return CustomScrollView(
      physics: isIOS ? const BouncingScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isIOS) CupertinoSliverRefreshControl(onRefresh: _cargarRifas),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRifaCard(_rifas[index], isIOS),
              ),
              childCount: _rifas.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoError(bool isIOS) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
              size: 64,
              color: isIOS ? CupertinoColors.systemRed : DashboardColors.rojo,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: isIOS ? CupertinoColors.label.resolveFrom(context) : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isIOS)
              CupertinoButton.filled(onPressed: _cargarRifas, child: const Text('Reintentar'))
            else
              ElevatedButton(onPressed: _cargarRifas, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVacio(bool isIOS) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isIOS ? CupertinoIcons.tray : Icons.inbox_outlined, size: 80, color: CupertinoColors.systemGrey),
            const SizedBox(height: 16),
            Text(
              'No hay rifas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: isIOS ? CupertinoColors.label.resolveFrom(context) : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera rifa para comenzar',
              style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRifaCard(Map<String, dynamic> rifa, bool isIOS) {
    final estado = rifa['estado'] ?? '';
    final titulo = rifa['titulo'] ?? 'Sin título';
    final descripcion = rifa['descripcion'] ?? '';
    final premios = (rifa['premios'] as List<dynamic>?) ?? [];
    final participantes = rifa['total_participantes'] ?? 0;
    final imagen = rifa['imagen_url'] ?? rifa['imagen'];
    final ganadores = premios.where((p) => p['ganador'] != null).toList();

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          isIOS
              ? CupertinoPageRoute(builder: (_) => PantallaRifaDetalle(rifaId: rifa['id']))
              : MaterialPageRoute(builder: (_) => PantallaRifaDetalle(rifaId: rifa['id'])),
        );
        if (result == true) await _cargarRifas();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isIOS ? CupertinoColors.systemBackground.resolveFrom(context) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagen != null && imagen.toString().isNotEmpty) _buildImagenRifa(imagen),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isIOS ? CupertinoColors.label.resolveFrom(context) : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildChipEstado(estado, isIOS),
                    ],
                  ),
                  if (descripcion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    isIOS ? CupertinoIcons.person_2 : Icons.people,
                    '$participantes participantes',
                    CupertinoColors.systemBlue,
                    isIOS,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    isIOS ? CupertinoIcons.gift : Icons.card_giftcard,
                    '${premios.length} premio${premios.length == 1 ? '' : 's'}',
                    CupertinoColors.systemOrange,
                    isIOS,
                  ),
                  if (ganadores.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      isIOS ? CupertinoIcons.star_fill : Icons.emoji_events,
                      '${ganadores.length} ganador${ganadores.length == 1 ? '' : 'es'}',
                      CupertinoColors.systemYellow,
                      isIOS,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenRifa(dynamic imagen) {
    final url = imagen.toString().startsWith('http') ? imagen.toString() : '${ApiConfig.baseUrl}$imagen';

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            child: Center(
              child: Platform.isIOS ? const CupertinoActivityIndicator() : const CupertinoActivityIndicator(radius: 14),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Platform.isIOS ? CupertinoIcons.photo : Icons.image_not_supported,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 8),
              Text('Imagen no disponible', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipEstado(String estado, bool isIOS) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _colorEstado(estado).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorEstado(estado).withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        _nombreEstado(estado),
        style: TextStyle(color: _colorEstado(estado), fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color, bool isIOS) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: isIOS ? CupertinoColors.secondaryLabel.resolveFrom(context) : Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginacionIOS() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: const Border(top: BorderSide(color: CupertinoColors.separator, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _paginaActual > 1 ? () => _cambiarPagina(_paginaActual - 1) : null,
            child: Icon(
              CupertinoIcons.chevron_left,
              color: _paginaActual > 1 ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
            ),
          ),
          Text(
            'Página $_paginaActual de $_totalPaginas',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _paginaActual < _totalPaginas ? () => _cambiarPagina(_paginaActual + 1) : null,
            child: Icon(
              CupertinoIcons.chevron_right,
              color: _paginaActual < _totalPaginas ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginacionMaterial() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _paginaActual > 1 ? () => _cambiarPagina(_paginaActual - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Página $_paginaActual de $_totalPaginas', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: _paginaActual < _totalPaginas ? () => _cambiarPagina(_paginaActual + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
