import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../apis/admin/rifas_admin_api.dart';
import '../../../config/api_config.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/app_colors_primary.dart';
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
        _mostrarMensajeExito('Rifa actualizada correctamente');
        setState(() {
          _editando = false;
          _nuevaImagen = null;
        });
        await _cargarDetalle();
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al actualizar rifa');
      }
    }
  }

  Future<void> _eliminarRifa() async {
    if (_rifa == null) return;

    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eliminar rifa'),
        content: const Text(
          '¿Seguro que deseas eliminar esta rifa? Esta acción no se puede deshacer.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _api.eliminarRifa(widget.rifaId);
      if (mounted) {
        _mostrarMensajeExito('Rifa eliminada');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al eliminar rifa: ${e.toString()}');
      }
    }
  }

  Future<void> _realizarSorteo() async {
    final requiereAdvertencia = _requiereAdvertenciaSorteo();
    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          requiereAdvertencia ? 'Sorteo anticipado' : 'Realizar sorteo',
        ),
        content: Text(
          requiereAdvertencia
              ? 'La rifa aún no termina. Si sorteas ahora, podrías dejar usuarios sin participar.\n\n¿Deseas forzar el sorteo?'
              : '¿Estás seguro de realizar el sorteo ahora? Esta acción no se puede deshacer.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              requiereAdvertencia ? 'Forzar sorteo' : 'Realizar sorteo',
            ),
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
        final ganadores =
            premiosGanados?.where((p) => p['ganador'] != null).toList() ?? [];

        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('¡Sorteo realizado!'),
            content: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
                if (ganadores.isEmpty)
                  const Text('No hubo participantes elegibles')
                else
                  ...ganadores.map((premio) {
                    final ganador = premio['ganador'];
                    final posicion = premio['posicion'];
                    final telefono = (ganador['celular'] ?? '').toString();
                    final email = (ganador['email'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNombrePosicion(posicion),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${ganador['first_name']} ${ganador['last_name']}',
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Simple text buttons or icons for contact
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (telefono.isNotEmpty)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Icon(
                                    CupertinoIcons.chat_bubble_text,
                                  ),
                                  onPressed: () => _abrirWhatsApp(telefono),
                                ),
                              if (email.isNotEmpty)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Icon(CupertinoIcons.mail),
                                  onPressed: () => _abrirCorreo(email),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        await _cargarDetalle();
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al realizar sorteo: ${e.toString()}');
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
      _mostrarError('Número de celular inválido');
      return;
    }

    final uri = Uri.parse('https://wa.me/$numero');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _mostrarError('No se pudo abrir WhatsApp');
    }
  }

  Future<void> _abrirCorreo(String email) async {
    final correo = email.trim();
    if (correo.isEmpty) {
      _mostrarError('Correo inválido');
      return;
    }

    final uri = Uri.parse('mailto:$correo');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _mostrarError('No se pudo abrir el correo');
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
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
                      onPressed: email.isEmpty
                          ? null
                          : () => _abrirCorreo(email),
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

  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColorsPrimary.main,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
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

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';
    try {
      final dt = DateTime.parse(fecha.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return fecha.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final primaryColor = AppColorsPrimary.main;

    if (_cargando) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: DashboardColors.rojo,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                onPressed: _cargarDetalle,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rifa == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: Text('Rifa no encontrada')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Detalle de Rifa'),
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
          if (_rifa != null && _rifa!['estado'] == 'activa' && !_editando)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: primaryColor),
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
                const PopupMenuItem(
                  value: 'editar',
                  child: Text('Editar información'),
                ),
                const PopupMenuItem(
                  value: 'sortear',
                  child: Text('Realizar sorteo'),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          if (_rifa != null &&
              (_rifa!['estado'] == 'finalizada' ||
                  _rifa!['estado'] == 'cancelada') &&
              !_editando)
            IconButton(
              onPressed: _eliminarRifa,
              icon: const Icon(CupertinoIcons.trash, color: Colors.red),
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildHeroSection(isDark, primaryColor),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoSection(isDark),
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
      ),
    );
  }

  Widget _buildHeroSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagenSection(primaryColor),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: _buildEstadoChip()),
      ],
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return _editando
        ? _buildFormularioEdicion(isDark)
        : _buildInformacionBasica(isDark);
  }

  Widget _buildFormularioEdicion(bool isDark) {
    return _buildCardSection(
      isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CupertinoTextField(
              controller: _tituloCtrl,
              placeholder: 'Título',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.title,
                  size: 20,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _descripcionCtrl,
              placeholder: 'Descripción',
              maxLines: 3,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.notes,
                  size: 20,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _pedidosMinCtrl,
              placeholder: 'Pedidos mínimos',
              keyboardType: TextInputType.number,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.checklist,
                  size: 20,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    color: CupertinoColors.systemGrey5,
                    onPressed: () {
                      setState(() {
                        _editando = false;
                        _nuevaImagen = null;
                      });
                      _cargarDetalle();
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 0),
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

  Widget _buildCardSection(bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildImagenSection(Color primaryColor) {
    final heroImage =
        _resolveImageUrl(_rifa!['imagen_url']) ??
        _resolveImageUrl(_rifa!['imagen']) ??
        _resolveImageUrl(_rifa!['imagen_principal']) ??
        _resolveImageUrl(_rifa!['imagen_portada']);
    Widget imageChild;

    if (_nuevaImagen != null) {
      imageChild = Image.file(
        _nuevaImagen!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (heroImage != null) {
      imageChild = Image.network(
        heroImage.startsWith('http')
            ? heroImage
            : '${ApiConfig.baseUrl}$heroImage',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 40)),
      );
    } else {
      imageChild = const Center(
        child: Icon(Icons.image, size: 48, color: CupertinoColors.systemGrey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        decoration: const BoxDecoration(color: CupertinoColors.systemGrey5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageChild,
            if (_editando)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: CupertinoButton.filled(
                    onPressed: _pickImage,
                    child: const Text('Cambiar Foto'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _resolveImageUrl(dynamic url) {
    if (url == null || url.toString().isEmpty) return null;
    return url.toString();
  }

  Widget _buildEstadoChip() {
    final estado = _rifa!['estado'] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _colorEstado(estado),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _nombreEstado(estado),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInformacionBasica(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    return _buildCardSection(
      isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _rifa!['titulo'] ?? 'Sin título',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _rifa!['descripcion'] ?? 'Sin descripción',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.checklist,
              'Pedidos mínimos',
              '${_rifa!['pedidos_minimos'] ?? 3}',
              isDark,
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha inicio',
              _formatFecha(_rifa!['fecha_inicio']),
              isDark,
            ),
            _buildInfoRow(
              Icons.event,
              'Fecha fin',
              _formatFecha(_rifa!['fecha_fin']),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColorsPrimary.main),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremios(BuildContext context) {
    // Note: Assuming API returns 'premios' list in rifa details or we have to use local state if not.
    // Based on `PantallaCrearRifa`, prizes are part of the raffle data.
    // If detail API doesn't return prizes formatted as expected, we might need to adjust.
    // For now, let's assume `_rifa!['premios']` exists.

    final premios = _rifa!['premios'] as List<dynamic>? ?? [];
    if (premios.isEmpty) return const SizedBox.shrink();

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PREMIOS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...premios.map((p) => _buildPremioCard(p, isDark)),
      ],
    );
  }

  Widget _buildPremioCard(dynamic premio, bool isDark) {
    final descripcion = premio['descripcion'] ?? 'Sin descripción';
    final posicion = premio['posicion'] ?? 0;
    final imagenUrl = _resolveImageUrl(
      premio['imagen'] ?? premio['imagen_url'],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColorsPrimary.main.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$posicion°',
                style: TextStyle(
                  color: AppColorsPrimary.main,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (imagenUrl != null) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imagenUrl.startsWith('http')
                            ? imagenUrl
                            : '${ApiConfig.baseUrl}$imagenUrl',
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const SizedBox(),
                      ),
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

  Widget _buildEstadisticas(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    // Mock stats or use real values if available in _rifa
    final totalPedidos = _rifa!['total_pedidos'] ?? 0;
    // final totalParticipantes = _rifa!['total_participantes'] ?? 0; // If available

    if (totalPedidos == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ESTADÍSTICAS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        _buildCardSection(
          isDark,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Pedidos', totalPedidos.toString(), isDark),
                // _buildStatItem('Participantes', totalParticipantes.toString(), isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColorsPrimary.main,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantes(BuildContext context) {
    if (_participantes.isEmpty) return const SizedBox.shrink();

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PARTICIPANTES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        _buildCardSection(
          isDark,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(0),
            itemCount: _participantes.length > 5
                ? 5
                : _participantes.length, // Show max 5
            separatorBuilder: (c, i) => Divider(
              height: 1,
              indent: 16,
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final p = _participantes[index];
              final user = p['usuario'] ?? {};
              return ListTile(
                title: Text('${user['first_name']} ${user['last_name']}'),
                subtitle: Text('Pedidos: ${p['cantidad_pedidos'] ?? 1}'),
                trailing: Text(
                  _formatFecha(p['fecha_registro']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => _mostrarContactoGanador(p['usuario'] ?? {}),
              );
            },
          ),
        ),
        if (_participantes.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                '+ ${_participantes.length - 5} más',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}
