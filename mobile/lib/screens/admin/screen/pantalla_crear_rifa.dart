import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../apis/admin/rifas_admin_api.dart';
import '../../../apis/helpers/api_exception.dart';
import '../dashboard/constants/dashboard_colors.dart';

enum _AccionConflictoRifa { cancelar, finalizar, descartar }

class PantallaCrearRifa extends StatefulWidget {
  const PantallaCrearRifa({super.key});

  @override
  State<PantallaCrearRifa> createState() => _PantallaCrearRifaState();
}

class _PantallaCrearRifaState extends State<PantallaCrearRifa> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _pedidosMinCtrl = TextEditingController(text: '3');

  // Premios (1-3)
  final List<Map<String, dynamic>> _premios = [];

  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  File? _imagen;
  bool _enviando = false;
  String? _error;

  final _api = RifasAdminApi();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _inicializarFechas();
  }

  void _inicializarFechas() {
    final ahora = DateTime.now();
    _fechaInicio = DateTime(ahora.year, ahora.month, 1);
    _fechaFin = _finDeDia(DateTime(ahora.year, ahora.month + 1, 0));
  }

  DateTime _finDeDia(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _pedidosMinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imagen = await _seleccionarImagenGaleria();
    if (imagen != null && mounted) {
      setState(() => _imagen = imagen);
    }
  }

  Future<File?> _seleccionarImagenGaleria() async {
    final permiso = await _solicitarPermisoGaleria();
    if (!permiso) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de galeria denegado')),
        );
      }
      return null;
    }

    try {
      final picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return null;
      return File(picked.path);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mensajeErrorImagen(e))),
        );
      }
      return null;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la galeria')),
        );
      }
      return null;
    }
  }

  Future<bool> _solicitarPermisoGaleria() async {
    if (Platform.isAndroid) {
      final permisoFotos = await Permission.photos.request();
      if (permisoFotos.isGranted) return true;
      final permisoStorage = await Permission.storage.request();
      return permisoStorage.isGranted;
    }
    final permisoFotos = await Permission.photos.request();
    return permisoFotos.isGranted;
  }

  String _mensajeErrorImagen(PlatformException e) {
    switch (e.code) {
      case 'photo_access_denied':
      case 'access_denied':
        return 'Permiso denegado para acceder a tus fotos';
      case 'already_active':
        return 'Espera a que termine la seleccion de imagen';
      default:
        return 'Error seleccionando imagen: ${e.message ?? e.code}';
    }
  }

  Future<void> _seleccionarFecha({required DateTime initial, required ValueChanged<DateTime> onSelected}) async {
    final ahora = DateTime.now();
    final primerDiaMes = DateTime(ahora.year, ahora.month, 1);
    final fecha = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(primerDiaMes) ? primerDiaMes : initial,
      firstDate: primerDiaMes,
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (fecha != null) onSelected(fecha);
  }

  void _agregarPremio() {
    if (_premios.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máximo 3 premios')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final descripcionCtrl = TextEditingController();
        File? imagenPremio;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${_getNombrePosicion(_premios.length + 1)} Lugar'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descripcionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción del premio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final imagen = await _seleccionarImagenGaleria();
                        if (imagen == null) return;
                        if (!context.mounted) return;
                        setDialogState(() => imagenPremio = imagen);
                      },
                      icon: const Icon(Icons.image),
                      label: Text(imagenPremio == null ? 'Agregar imagen' : 'Imagen seleccionada'),
                    ),
                    if (imagenPremio != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(imagenPremio!, height: 100, fit: BoxFit.cover),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (descripcionCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Ingresa la descripción')));
                      return;
                    }
                    setState(() {
                      _premios.add({
                        'posicion': _premios.length + 1,
                        'descripcion': descripcionCtrl.text.trim(),
                        'imagen': imagenPremio,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
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

  void _normalizarPremios() {
    for (int i = 0; i < _premios.length; i++) {
      _premios[i]['posicion'] = i + 1;
    }
  }

  Future<void> _crear({bool reintento = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_premios.isEmpty) {
      setState(() => _error = 'Debes agregar al menos 1 premio');
      return;
    }
    final pedidosMin = int.tryParse(_pedidosMinCtrl.text.trim());
    if (pedidosMin == null || pedidosMin < 1) {
      setState(() => _error = 'Pedidos mínimos inválido');
      return;
    }
    if (!_fechaFin.isAfter(_fechaInicio)) {
      setState(() => _error = 'La fecha de fin debe ser posterior a la fecha de inicio');
      return;
    }
    _normalizarPremios();

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _api.crearRifa(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        pedidosMinimos: pedidosMin,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        imagen: _imagen,
        premios: _premios,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rifa creada correctamente'), backgroundColor: DashboardColors.verde),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (!reintento && _esConflictoRifaActiva(e)) {
        if (mounted) {
          setState(() => _enviando = false);
        }
        final handled = await _manejarConflictoRifaActiva(e);
        if (handled) return;
      }
      setState(() => _error = e.getUserFriendlyMessage());
    } catch (e) {
      setState(() => _error = 'No se pudo crear la rifa: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  bool _esConflictoRifaActiva(ApiException e) {
    final error = e.getFieldError('fecha_inicio') ?? '';
    return e.isValidationError && error.contains('Ya existe una rifa activa');
  }

  Future<bool> _manejarConflictoRifaActiva(ApiException e) async {
    if (!mounted) return false;
    final mensaje = e.getFieldError('fecha_inicio') ??
        'Ya existe una rifa activa para este mes. Debes finalizarla o cancelarla antes de crear una nueva.';
    final rifaActiva = await _buscarRifaActivaDelMes();
    if (!mounted) return false;

    final tituloActiva = rifaActiva?['titulo'] as String?;
    final idActiva = rifaActiva?['id']?.toString();

    final accion = await _mostrarDialogoConflicto(
      mensaje: mensaje,
      tituloActiva: tituloActiva,
    );

    if (accion == null) {
      return true;
    }

    if (accion == _AccionConflictoRifa.descartar) {
      if (mounted) {
        Navigator.pop(context, false);
      }
      return true;
    }

    if (idActiva == null) {
      if (mounted) {
        setState(() => _error = 'No se encontró la rifa activa para cancelar.');
      }
      return true;
    }

    if (mounted) {
      setState(() => _enviando = true);
    }

    try {
      if (accion == _AccionConflictoRifa.finalizar) {
        await _api.finalizarRifa(idActiva);
      } else {
        await _api.cancelarRifa(idActiva);
      }
    } on ApiException catch (apiError) {
      if (mounted) {
        setState(() => _error = apiError.getUserFriendlyMessage());
      }
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo actualizar la rifa activa.');
      }
      return true;
    }

    await _crear(reintento: true);
    return true;
  }

  Future<Map<String, dynamic>?> _buscarRifaActivaDelMes() async {
    try {
      final response = await _api.listarRifas(
        estado: 'activa',
        mes: _fechaInicio.month,
        anio: _fechaInicio.year,
        pagina: 1,
      );
      final results = response['results'];
      if (results is List && results.isNotEmpty) {
        final first = results.first;
        if (first is Map<String, dynamic>) {
          return first;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<_AccionConflictoRifa?> _mostrarDialogoConflicto({
    required String mensaje,
    String? tituloActiva,
  }) async {
    if (Platform.isIOS) {
      return showCupertinoDialog<_AccionConflictoRifa>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Rifa activa encontrada'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              Text(mensaje),
              if (tituloActiva != null) ...[
                const SizedBox(height: 8),
                Text('Activa: $tituloActiva'),
              ],
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, _AccionConflictoRifa.cancelar),
              child: const Text('Cancelar rifa activa'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, _AccionConflictoRifa.finalizar),
              child: const Text('Finalizar rifa activa'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, _AccionConflictoRifa.descartar),
              child: const Text('Descartar cambios'),
            ),
          ],
        ),
      );
    }

    return showDialog<_AccionConflictoRifa>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rifa activa encontrada'),
        content: Text(
          tituloActiva == null ? mensaje : '$mensaje\n\nActiva: $tituloActiva',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _AccionConflictoRifa.descartar),
            child: const Text('Descartar cambios'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _AccionConflictoRifa.finalizar),
            child: const Text('Finalizar rifa activa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _AccionConflictoRifa.cancelar),
            child: const Text('Cancelar rifa activa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Crear rifa', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF2F2F7),
        foregroundColor: const Color.fromARGB(255, 84, 169, 222),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Datos de la rifa'),
              _buildCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pedidosMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pedidos mínimos para participar',
                        prefixIcon: Icon(Icons.checklist),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Fechas'),
              _buildCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha inicio'),
                      subtitle: Text(_fechaInicio.toLocal().toString().split(' ').first),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () =>
                          _seleccionarFecha(
                            initial: _fechaInicio,
                            onSelected: (f) =>
                                setState(() => _fechaInicio = f),
                          ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha fin'),
                      subtitle: Text(_fechaFin.toLocal().toString().split(' ').first),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () =>
                          _seleccionarFecha(
                            initial: _fechaFin,
                            onSelected: (f) =>
                                setState(() => _fechaFin = _finDeDia(f)),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Imagen principal'),
              _buildCard(
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Seleccionar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.azul,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _imagen == null
                          ? const Text('Sin imagen seleccionada', style: TextStyle(color: Colors.grey))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_imagen!, height: 72, fit: BoxFit.cover),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Premios'),
                  ElevatedButton.icon(
                    onPressed: _premios.length < 3 ? _agregarPremio : null,
                    icon: const Icon(Icons.add),
                    label: Text('Agregar (${_premios.length}/3)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 71, 190, 223),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_premios.isEmpty)
                _buildCard(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No hay premios agregados', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                )
              else
                ..._premios.asMap().entries.map((entry) {
                  final index = entry.key;
                  final premio = entry.value;
                  return _buildPremioCard(premio, index);
                }),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: DashboardColors.rojo)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : _crear,
                  icon: _enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_enviando ? 'Creando...' : 'Crear rifa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 154, 238),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  Widget _buildPremioCard(Map<String, dynamic> premio, int index) {
    final imagen = premio['imagen'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 52, 170, 206).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _getNombrePosicion(premio['posicion']),
              style: const TextStyle(color: Color.fromARGB(255, 42, 161, 229), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(premio['descripcion'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (imagen != null && imagen is File)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(imagen, height: 60, fit: BoxFit.cover),
                  )
                else
                  const Text('Sin imagen', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: DashboardColors.rojo),
            onPressed: () => setState(() {
              _premios.removeAt(index);
              _normalizarPremios();
            }),
          ),
        ],
      ),
    );
  }
}
