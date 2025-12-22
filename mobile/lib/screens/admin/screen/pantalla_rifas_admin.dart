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
  String _filtroEstado = 'todas';
  int _paginaActual = 1;
  int _totalPaginas = 1;

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
        estado: _filtroEstado == 'todas' ? null : _filtroEstado,
        pagina: _paginaActual,
      );

      setState(() {
        _rifas = response['results'] ?? [];
        _totalPaginas = ((response['count'] ?? 0) / 10).ceil();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar rifas';
        _cargando = false;
      });
    }
  }

  void _cambiarFiltro(String? nuevoFiltro) {
    if (nuevoFiltro != null && nuevoFiltro != _filtroEstado) {
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
        return DashboardColors.verde;
      case 'finalizada':
        return DashboardColors.azul;
      case 'cancelada':
        return DashboardColors.rojo;
      default:
        return Colors.grey;
    }
  }

  String _nombreEstado(String estado) {
    switch (estado) {
      case 'activa':
        return 'Activa';
      case 'finalizada':
        return 'Finalizada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  String _getNombrePosicion(int posicion) {
    switch (posicion) {
      case 1:
        return '1er';
      case 2:
        return '2do';
      case 3:
        return '3er';
      default:
        return '$posicion°';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de rifas'),
        backgroundColor: Colors.white,
        foregroundColor: DashboardColors.morado,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaCrearRifa()),
          );
          if (result == true) _cargarRifas();
        },
        backgroundColor: DashboardColors.morado,
        icon: const Icon(Icons.add),
        label: const Text('Crear rifa'),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChipFiltro('Todas', 'todas'),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Activas', 'activa'),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Finalizadas', 'finalizada'),
                  const SizedBox(width: 8),
                  _buildChipFiltro('Canceladas', 'cancelada'),
                ],
              ),
            ),
          ),

          // Lista de rifas
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: DashboardColors.rojo,
                        ),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarRifas,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _rifas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay rifas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primera rifa',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarRifas,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rifas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildRifaCard(_rifas[index]),
                    ),
                  ),
          ),

          // Paginación
          if (_totalPaginas > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _paginaActual > 1
                        ? () => _cambiarPagina(_paginaActual - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    'Página $_paginaActual de $_totalPaginas',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _paginaActual < _totalPaginas
                        ? () => _cambiarPagina(_paginaActual + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String label, String valor) {
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

  Widget _buildRifaCard(Map<String, dynamic> rifa) {
    final estado = rifa['estado'] ?? '';
    final titulo = rifa['titulo'] ?? 'Sin título';
    final premios = (rifa['premios'] as List<dynamic>?) ?? [];
    final participantes = rifa['total_participantes'] ?? 0;
    final imagen = rifa['imagen'];
    final ganadores = premios.where((p) => p['ganador'] != null).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaRifaDetalle(rifaId: rifa['id']),
            ),
          );
          if (result == true) _cargarRifas();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Imagen
            if (imagen != null && imagen.toString().isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imagen.toString().startsWith('http')
                      ? imagen.toString()
                      : '${ApiConfig.baseUrl}$imagen',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Imagen no disponible',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _colorEstado(estado),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _nombreEstado(estado),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Título
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Premios
                  if (premios.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${premios.length} premio${premios.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...premios
                        .take(2)
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(left: 20, top: 2),
                            child: Text(
                              '${_getNombrePosicion(p['posicion'])}: ${p['descripcion']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 8),

                  // Participantes
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: DashboardColors.azul,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$participantes participantes',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  // Ganadores
                  if (ganadores.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${ganadores.length} ganador${ganadores.length > 1 ? 'es' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
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
}
