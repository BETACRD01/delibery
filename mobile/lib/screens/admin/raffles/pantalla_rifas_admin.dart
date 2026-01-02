import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../apis/admin/rifas_admin_api.dart';
import '../../../config/network/api_config.dart';
import '../../../providers/core/theme_provider.dart';
import '../../../theme/primary_colors.dart';
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

  static const Map<String, String> _etiquetasEstado = {
    'activa': 'Activas',
    'finalizada': 'Finalizadas',
    'cancelada': 'Canceladas',
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

  void _mostrarCrearRifa() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaCrearRifa()),
    );
    if (result == true) await _cargarRifas();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final primaryColor = AppColorsPrimary.main;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Gestión de Rifas'),
        backgroundColor: bgColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.add_circled_solid,
              color: primaryColor,
              size: 28,
            ),
            onPressed: _mostrarCrearRifa,
          ),
        ],
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: Column(
        children: [
          // Segmented Control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: bgColor,
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _filtroEstado,
              children: {
                'activa': Text(_etiquetasEstado['activa']!),
                'finalizada': Text(_etiquetasEstado['finalizada']!),
                'cancelada': Text(_etiquetasEstado['cancelada']!),
              },
              onValueChanged: (val) {
                if (val != null) _cambiarFiltro(val);
              },
              thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
              backgroundColor: isDark
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFF767680).withValues(alpha: 0.12),
            ),
          ),

          Expanded(
            child: _cargando
                ? const Center(child: CupertinoActivityIndicator())
                : _error != null
                ? _buildError(isDark, primaryColor)
                : _rifas.isEmpty
                ? _buildEmpty(isDark)
                : RefreshIndicator(
                    onRefresh: _cargarRifas,
                    color: primaryColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rifas.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildRifaCard(
                          _rifas[index],
                          isDark,
                          primaryColor,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRifaCard(
    Map<String, dynamic> rifa,
    bool isDark,
    Color primaryColor,
  ) {
    final title = rifa['titulo'] ?? 'Sin Título';
    final participantes = rifa['total_participantes'] ?? 0;
    final imagen = rifa['imagen_url'] ?? rifa['imagen'];
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PantallaRifaDetalle(rifaId: rifa['id']),
          ),
        );
        if (result == true) await _cargarRifas();
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          // iOS style subtle shadow or border
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            if (imagen != null && imagen.toString().isNotEmpty)
              _buildImagenRifa(imagen)
            else
              Container(
                height: 120,
                width: double.infinity,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: Center(
                  child: Icon(
                    CupertinoIcons.ticket,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$participantes Participantes',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenRifa(dynamic imagen) {
    final url = imagen.toString().startsWith('http')
        ? imagen.toString()
        : '${ApiConfig.baseUrl}$imagen';
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image_not_supported)),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Error desconocido',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _cargarRifas,
            child: Text('Reintentar', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.ticket,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay rifas ${_filtroEstado}s',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
