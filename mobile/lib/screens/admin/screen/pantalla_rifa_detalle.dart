import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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

      if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar detalles';
        _cargando = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
          const SnackBar(content: Text('Rifa actualizada correctamente'), backgroundColor: DashboardColors.verde),
        );
        setState(() {
          _editando = false;
          _nuevaImagen = null;
        });
        await _cargarDetalle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar rifa'), backgroundColor: DashboardColors.rojo),
        );
      }
    }
  }

  Future<void> _eliminarRifa() async {
    if (_rifa == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar rifa'),
        content: const Text('¿Seguro que deseas eliminar esta rifa? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.rojo),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _api.eliminarRifa(widget.rifaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rifa eliminada'), backgroundColor: DashboardColors.verde),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar rifa: ${e.toString()}'), backgroundColor: DashboardColors.rojo),
        );
      }
    }
  }

  Future<void> _realizarSorteo() async {
    final requiereAdvertencia = _requiereAdvertenciaSorteo();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(requiereAdvertencia ? 'Sorteo anticipado' : 'Realizar sorteo'),
        content: Text(
          requiereAdvertencia
              ? 'La rifa aún no termina. Si sorteas ahora, podrías dejar usuarios sin participar.\n\n¿Deseas forzar el sorteo?'
              : '¿Estás seguro de realizar el sorteo ahora? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DashboardColors.verde),
            child: Text(requiereAdvertencia ? 'Forzar sorteo' : 'Realizar sorteo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final resultado = await _api.realizarSorteo(
        widget.rifaId,
        forzar: requiereAdvertencia,
      );

      if (mounted) {
        final premiosGanados = resultado['premios_ganados'] as List<dynamic>?;
        final ganadores = premiosGanados?.where((p) => p['ganador'] != null).toList() ?? [];

        await showDialog(
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
                      final telefono = (ganador['celular'] ?? '').toString();
                      final telefonoVisible =
                          telefono.isEmpty ? 'Sin celular' : telefono;
                      final email = (ganador['email'] ?? '').toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getNombrePosicion(posicion), style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${ganador['first_name']} ${ganador['last_name']}'),
                            Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    telefonoVisible,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: telefono.isEmpty
                                      ? null
                                      : () => _abrirWhatsApp(telefono),
                                  icon: const Icon(Icons.chat),
                                  tooltip: 'Contactar por WhatsApp',
                                ),
                                IconButton(
                                  onPressed:
                                      email.isEmpty ? null : () => _abrirCorreo(email),
                                  icon: const Icon(Icons.email),
                                  tooltip: 'Enviar correo',
                                ),
                                IconButton(
                                  onPressed: () => _mostrarContactoGanador(ganador),
                                  icon: const Icon(Icons.info_outline),
                                  tooltip: 'Ver contacto',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
          ),
        );
        await _cargarDetalle();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al realizar sorteo: ${e.toString()}'), backgroundColor: DashboardColors.rojo),
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

  Future<void> _abrirWhatsApp(String telefono) async {
    final numero = telefono.replaceAll(RegExp(r'\D'), '');
    if (numero.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de celular inválido')),
        );
      }
      return;
    }

    final uri = Uri.parse('https://wa.me/$numero');
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  Future<void> _abrirCorreo(String email) async {
    final correo = email.trim();
    if (correo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo inválido')),
        );
      }
      return;
    }

    final uri = Uri.parse('mailto:$correo');
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el correo')),
      );
    }
  }

  Future<void> _mostrarContactoGanador(Map<String, dynamic> usuario) async {
    final email = (usuario['email'] ?? '').toString().trim();
    final telefono = (usuario['celular'] ?? '').toString().trim();
    final nombre =
        '${usuario['first_name'] ?? ''} ${usuario['last_name'] ?? ''}'.trim();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre.isEmpty ? 'Ganador' : nombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (email.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.email, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(email)),
                  ],
                ),
              if (email.isNotEmpty) const SizedBox(height: 8),
              if (telefono.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(telefono)),
                  ],
                ),
              if (telefono.isEmpty && email.isEmpty)
                const Text('No hay datos de contacto'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: telefono.isEmpty
                          ? null
                          : () => _abrirWhatsApp(telefono),
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          email.isEmpty ? null : () => _abrirCorreo(email),
                      icon: const Icon(Icons.email),
                      label: const Text('Correo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool _requiereAdvertenciaSorteo() {
    if (_rifa == null) return false;
    if ((_rifa!['tipo_sorteo'] ?? '') != 'manual') return false;
    final fechaFin = _parseFecha(_rifa!['fecha_fin']?.toString());
    if (fechaFin == null) return false;
    return DateTime.now().isBefore(fechaFin);
  }

  DateTime? _parseFecha(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
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

  Widget _buildBody(BuildContext context) {
    if (_cargando) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: DashboardColors.rojo),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: _cargarDetalle,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_rifa == null) {
      return const Center(child: Text('Rifa no encontrada'));
    }

    final isIOS = Platform.isIOS;

    return CustomScrollView(
      physics: isIOS ? const BouncingScrollPhysics() : const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _buildHeroSection(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildInfoSection(context),
              const SizedBox(height: 16),
              _buildPremios(context),
              const SizedBox(height: 16),
              _buildEstadisticas(context),
              const SizedBox(height: 16),
              _buildParticipantes(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagenSection(context),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: _buildEstadoChip()),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return _editando ? _buildFormularioEdicion(context) : _buildInformacionBasica(context);
  }

  Widget _buildCardSection(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CupertinoColors.systemGrey5, width: 0.9),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: const Text('Detalle de rifa'),
        centerTitle: true,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        foregroundColor: Colors.black87,
        elevation: 0,
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
                  case 'eliminar':
                    _eliminarRifa();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar información básica')),
                const PopupMenuItem(value: 'sortear', child: Text('Realizar sorteo')),
              ],
            ),
          if (_rifa != null &&
              (_rifa!['estado'] == 'finalizada' || _rifa!['estado'] == 'cancelada') &&
              !_editando)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'eliminar') {
                  _eliminarRifa();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'eliminar', child: Text('Eliminar rifa')),
              ],
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildImagenSection(BuildContext context) {
    final heroImage = _resolveImageUrl(_rifa!['imagen_url']) ??
        _resolveImageUrl(_rifa!['imagen']) ??
        _resolveImageUrl(_rifa!['imagen_principal']) ??
        _resolveImageUrl(_rifa!['imagen_portada']);
    Widget imageChild;

    if (_nuevaImagen != null) {
      imageChild = Image.file(_nuevaImagen!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (heroImage != null) {
      imageChild = Image.network(
        heroImage.startsWith('http') ? heroImage : '${ApiConfig.baseUrl}$heroImage',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: CupertinoColors.systemGrey5);
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.image_not_supported, size: 48, color: CupertinoColors.systemGrey),
              SizedBox(height: 8),
              Text('Imagen no disponible', style: TextStyle(color: CupertinoColors.systemGrey)),
            ],
          ),
        ),
      );
    } else {
      imageChild = const Center(child: Icon(Icons.image, size: 48, color: CupertinoColors.systemGrey));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        decoration: BoxDecoration(color: CupertinoColors.systemGrey5),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: imageChild),
            Positioned(
              bottom: 0,
              height: 120,
              left: 0,
              right: 0, 
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            if (_editando)
              Positioned(
                bottom: 16,
                right: 16,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onPressed: _pickImage,
                  child: const Text('Cambiar imagen'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoChip() {
    final estado = _rifa!['estado'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: _colorEstado(estado), borderRadius: BorderRadius.circular(20)),
      child: Text(
        _nombreEstado(estado),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInformacionBasica(BuildContext context) {
    return _buildCardSection(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_rifa!['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              _rifa!['descripcion'] ?? 'Sin descripción',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.checklist, 'Pedidos mínimos', '${_rifa!['pedidos_minimos'] ?? 3}'),
            _buildInfoRow(Icons.calendar_today, 'Fecha inicio', _formatFecha(_rifa!['fecha_inicio'])),
            _buildInfoRow(Icons.event, 'Fecha fin', _formatFecha(_rifa!['fecha_fin'])),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioEdicion(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: CupertinoColors.systemGrey4),
    );

    return _buildCardSection(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tituloCtrl,
              decoration: InputDecoration(
                labelText: 'Título',
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                prefixIcon: const Icon(Icons.title),
                filled: true,
                fillColor: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                prefixIcon: const Icon(Icons.notes),
                filled: true,
                fillColor: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pedidosMinCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pedidos mínimos',
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                prefixIcon: const Icon(Icons.checklist),
                filled: true,
                fillColor: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: CupertinoColors.systemGrey5,
                    onPressed: () {
                      setState(() {
                        _editando = false;
                        _nuevaImagen = null;
                      });
                      _cargarDetalle();
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: _guardarCambios,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DashboardColors.morado),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.systemGrey),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: CupertinoColors.label)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremios(BuildContext context) {
    final premios = (_rifa!['premios'] as List<dynamic>?) ?? [];

    return _buildCardSection(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Premios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardColors.morado.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${premios.length} premio${premios.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: DashboardColors.morado),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (premios.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No hay premios configurados.\nConfigúralos desde el admin de Django.',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Column(
                children: premios.map((premio) {
                  final ganador = premio['ganador'];
                  final posicion = premio['posicion'];
                  final descripcion = premio['descripcion'] ?? 'Sin descripción';
                  final imagen = premio['imagen_url'] ?? premio['imagen'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CupertinoColors.systemGrey5, width: 0.9),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPremioThumbnail(imagen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premio ${posicion ?? 'N/A'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descripcion,
                                style: const TextStyle(color: CupertinoColors.systemGrey),
                              ),
                              if (ganador != null) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _mostrarContactoGanador(
                                    ganador as Map<String, dynamic>,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.person_alt_circle, size: 16, color: DashboardColors.verde),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${ganador['first_name']} ${ganador['last_name']}',
                                          style: const TextStyle(color: CupertinoColors.label, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const Icon(Icons.info_outline, size: 18, color: CupertinoColors.systemGrey),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (ganador != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: DashboardColors.verde.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Ganador',
                              style: TextStyle(fontWeight: FontWeight.bold, color: DashboardColors.verde),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremioThumbnail(dynamic imagen) {
    final resource = _resolveImageUrl(imagen);
    final normalizedImageUrl =
        resource != null ? (resource.startsWith('http') ? resource : '${ApiConfig.baseUrl}$resource') : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: CupertinoColors.systemGrey5,
        child: normalizedImageUrl != null
            ? Image.network(
                normalizedImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CupertinoActivityIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  CupertinoIcons.gift,
                  color: CupertinoColors.systemGrey,
                ),
              )
            : const Icon(
                CupertinoIcons.gift,
                color: CupertinoColors.systemGrey,
              ),
      ),
    );
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

  Widget _buildEstadisticas(BuildContext context) {
    final totalParticipantes = _rifa!['total_participantes'] ?? 0;

    return _buildCardSection(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estadísticas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadistica(Icons.people, 'Participantes', totalParticipantes.toString(), DashboardColors.azul),
                _buildEstadistica(
                  Icons.checklist,
                  'Pedidos mínimos',
                  (_rifa!['pedidos_minimos'] ?? 0).toString(),
                  DashboardColors.verde,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadistica(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(color: CupertinoColors.systemGrey)),
      ],
    );
  }

  Widget _buildParticipantes(BuildContext context) {
    return _buildCardSection(
      context,
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
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('No hay participantes aún', style: TextStyle(color: CupertinoColors.systemGrey)),
              )
            else
              Column(
                children: List.generate(_participantes.length, (index) {
                  final participante = _participantes[index];
                  final usuario = (participante['usuario'] as Map<String, dynamic>?) ?? {};
                  final pedidos = participante['pedidos_completados'] ?? 0;
                  final firstName = usuario['first_name'] as String? ?? '';
                  final lastName = usuario['last_name'] as String? ?? '';
                  final initials =
                      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                          .toUpperCase();

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _mostrarContactoGanador(usuario),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: DashboardColors.azul,
                              child: Text(initials, style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$firstName $lastName'.trim().isEmpty
                                        ? 'Participante sin nombre'
                                        : '$firstName $lastName',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    usuario['email'] as String? ?? '',
                                    style: const TextStyle(color: CupertinoColors.systemGrey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: DashboardColors.verde.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$pedidos pedidos',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: DashboardColors.verde),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index != _participantes.length - 1)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 0.5)),
                    ],
                  );
                }),
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
