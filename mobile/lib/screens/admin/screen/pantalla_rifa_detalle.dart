import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../apis/admin/rifas_admin_api.dart';
import '../../../config/api_config.dart';
import '../dashboard/constants/dashboard_colors.dart';

class PantallaRifaDetalle extends StatefulWidget {
  final String rifaId;

  const PantallaRifaDetalle({super.key, required this.rifaId});

  @override
  State<PantallaRifaDetalle> createState() => _PantallaRifaDetalleState();
}

class _PantallaRifaDetalleState extends State<PantallaRifaDetalle> {
  final _api = RifasAdminApi();
  final _picker = ImagePicker();

  Map<String, dynamic>? _rifa;
  List<dynamic> _participantes = [];
  bool _cargando = true;
  bool _editando = false;
  String? _error;

  // Controllers para edición básica
  late TextEditingController _tituloCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _pedidosMinCtrl;

  File? _nuevaImagen;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _pedidosMinCtrl = TextEditingController();
    _cargarDetalle();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _pedidosMinCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final rifa = await _api.obtenerRifa(widget.rifaId);
      final participantes = await _api.obtenerParticipantes(widget.rifaId);

      setState(() {
        _rifa = rifa;
        _participantes = participantes['participantes'] ?? [];
        _cargando = false;

        // Cargar datos básicos en controllers
        _tituloCtrl.text = rifa['titulo'] ?? '';
        _descripcionCtrl.text = rifa['descripcion'] ?? '';
        _pedidosMinCtrl.text = (rifa['pedidos_minimos'] ?? 3).toString();
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar detalles';
        _cargando = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _nuevaImagen = File(picked.path));
    }
  }

  Future<void> _guardarCambios() async {
    if (_rifa == null) return;

    try {
      await _api.actualizarRifa(
        rifaId: widget.rifaId,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        pedidosMinimos: int.tryParse(_pedidosMinCtrl.text.trim()),
        imagen: _nuevaImagen,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rifa actualizada correctamente'),
            backgroundColor: DashboardColors.verde,
          ),
        );
        setState(() {
          _editando = false;
          _nuevaImagen = null;
        });
        _cargarDetalle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar rifa'),
            backgroundColor: DashboardColors.rojo,
          ),
        );
      }
    }
  }

  Future<void> _realizarSorteo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Realizar sorteo'),
        content: const Text(
          '¿Estás seguro de realizar el sorteo ahora? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardColors.verde,
            ),
            child: const Text('Realizar sorteo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final resultado = await _api.realizarSorteo(widget.rifaId);

      if (mounted) {
        final premiosGanados = resultado['premios_ganados'] as List<dynamic>?;
        final ganadores =
            premiosGanados?.where((p) => p['ganador'] != null).toList() ?? [];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                SizedBox(width: 8),
                Text('¡Sorteo realizado!'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ganadores.isEmpty)
                    const Text('No hubo participantes elegibles')
                  else
                    ...ganadores.map((premio) {
                      final ganador = premio['ganador'];
                      final posicion = premio['posicion'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getNombrePosicion(posicion),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${ganador['first_name']} ${ganador['last_name']}',
                            ),
                            Text(
                              ganador['email'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        _cargarDetalle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar sorteo: ${e.toString()}'),
            backgroundColor: DashboardColors.rojo,
          ),
        );
      }
    }
  }

  String _getNombrePosicion(int posicion) {
    switch (posicion) {
      case 1:
        return '1er Lugar';
      case 2:
        return '2do Lugar';
      case 3:
        return '3er Lugar';
      default:
        return '$posicion° Lugar';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de rifa'),
        backgroundColor: Colors.white,
        foregroundColor: DashboardColors.morado,
        elevation: 1,
        actions: [
          if (_rifa != null && _rifa!['estado'] == 'activa' && !_editando)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'editar':
                    setState(() => _editando = true);
                    break;
                  case 'sortear':
                    _realizarSorteo();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Text('Editar información básica'),
                ),
                const PopupMenuItem(
                  value: 'sortear',
                  child: Text('Realizar sorteo'),
                ),
              ],
            ),
        ],
      ),
      body: _cargando
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
                    onPressed: _cargarDetalle,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _rifa == null
          ? const Center(child: Text('Rifa no encontrada'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen
                  _buildImagenSection(),
                  const SizedBox(height: 16),

                  // Estado
                  _buildEstadoChip(),
                  const SizedBox(height: 16),

                  // Información básica
                  if (_editando) ...[
                    _buildFormularioEdicion(),
                  ] else ...[
                    _buildInformacionBasica(),
                  ],

                  const SizedBox(height: 24),

                  // Premios
                  _buildPremios(),
                  const SizedBox(height: 24),

                  // Estadísticas
                  _buildEstadisticas(),
                  const SizedBox(height: 24),

                  // Participantes
                  _buildParticipantes(),
                ],
              ),
            ),
    );
  }

  Widget _buildImagenSection() {
    final imagen = _rifa!['imagen'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _nuevaImagen != null
              ? Image.file(
                  _nuevaImagen!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : imagen != null && imagen.toString().isNotEmpty
              ? Image.network(
                  imagen.toString().startsWith('http')
                      ? imagen.toString()
                      : '${ApiConfig.baseUrl}$imagen',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
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
                )
              : Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.image, size: 48)),
                ),
        ),
        if (_editando) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Cambiar imagen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardColors.azul,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEstadoChip() {
    final estado = _rifa!['estado'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _colorEstado(estado),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _nombreEstado(estado),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInformacionBasica() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _rifa!['titulo'] ?? 'Sin título',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          _rifa!['descripcion'] ?? 'Sin descripción',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          Icons.checklist,
          'Pedidos mínimos',
          '${_rifa!['pedidos_minimos'] ?? 3}',
        ),
        _buildInfoRow(
          Icons.calendar_today,
          'Fecha inicio',
          _formatFecha(_rifa!['fecha_inicio']),
        ),
        _buildInfoRow(
          Icons.event,
          'Fecha fin',
          _formatFecha(_rifa!['fecha_fin']),
        ),
      ],
    );
  }

  Widget _buildFormularioEdicion() {
    return Column(
      children: [
        TextField(
          controller: _tituloCtrl,
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descripcionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pedidosMinCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Pedidos mínimos',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.checklist),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _editando = false;
                    _nuevaImagen = null;
                  });
                  _cargarDetalle();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardColors.verde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DashboardColors.morado),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPremios() {
    final premios = (_rifa!['premios'] as List<dynamic>?) ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Premios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DashboardColors.morado.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${premios.length} premio${premios.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DashboardColors.morado,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (premios.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay premios configurados.\nConfigúralos desde el admin de Django.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...premios.map((premio) {
                final ganador = premio['ganador'];
                final posicion = premio['posicion'];
                final descripcion = premio['descripcion'] ?? 'Sin descripción';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: ganador != null ? Colors.amber[50] : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ganador != null
                          ? Colors.amber
                          : DashboardColors.morado,
                      child: ganador != null
                          ? const Icon(Icons.emoji_events, color: Colors.white)
                          : Text(
                              posicion.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    title: Text(_getNombrePosicion(posicion)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(descripcion),
                        if (ganador != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ganador: ${ganador['first_name']} ${ganador['last_name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    final totalParticipantes = _rifa!['total_participantes'] ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadistica(
                  Icons.people,
                  'Participantes',
                  totalParticipantes.toString(),
                  DashboardColors.azul,
                ),
                _buildEstadistica(
                  Icons.checklist,
                  'Pedidos mínimos',
                  _rifa!['pedidos_minimos'].toString(),
                  DashboardColors.verde,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadistica(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildParticipantes() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participantes (${_participantes.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_participantes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay participantes aún',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _participantes.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final participante = _participantes[index];
                  final usuario = participante['usuario'];
                  final pedidos = participante['pedidos_completados'] ?? 0;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: DashboardColors.azul,
                      child: Text(
                        '${usuario['first_name'][0]}${usuario['last_name'][0]}'
                            .toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      '${usuario['first_name']} ${usuario['last_name']}',
                    ),
                    subtitle: Text(usuario['email']),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DashboardColors.verde.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pedidos pedidos',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: DashboardColors.verde,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }
}
