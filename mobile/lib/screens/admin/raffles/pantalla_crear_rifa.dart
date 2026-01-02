import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../apis/admin/rifas_admin_api.dart';
import '../../../apis/helpers/api_exception.dart';
import '../../../providers/core/theme_provider.dart';
import '../../../theme/app_colors_primary.dart';
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
        _mostrarError('Permiso de galería denegado');
      }
      return null;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return null;
      return File(picked.path);
    } on PlatformException catch (e) {
      if (mounted) {
        _mostrarError(_mensajeErrorImagen(e));
      }
      return null;
    } catch (_) {
      if (mounted) {
        _mostrarError('No se pudo abrir la galería');
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

  Future<void> _seleccionarFecha({
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final ahora = DateTime.now();
    final primerDiaMes = DateTime(ahora.year, ahora.month, 1);

    // iOS styled date picker
    if (Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: const Color.fromARGB(255, 255, 255, 255),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  initialDateTime: initial.isBefore(primerDiaMes)
                      ? primerDiaMes
                      : initial,
                  minimumDate: primerDiaMes,
                  maximumDate: ahora.add(const Duration(days: 365)),
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (val) {
                    onSelected(val);
                  },
                ),
              ),
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    } else {
      final fecha = await showDatePicker(
        context: context,
        initialDate: initial.isBefore(primerDiaMes) ? primerDiaMes : initial,
        firstDate: primerDiaMes,
        lastDate: ahora.add(const Duration(days: 365)),
      );
      if (fecha != null) onSelected(fecha);
    }
  }

  void _agregarPremio() {
    if (_premios.length >= 3) {
      _mostrarError('Máximo 3 premios');
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) {
        final descripcionCtrl = TextEditingController();
        File? imagenPremio;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: Text('${_getNombrePosicion(_premios.length + 1)} Lugar'),
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: descripcionCtrl,
                    placeholder: 'Descripción del premio',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final imagen = await _seleccionarImagenGaleria();
                      if (imagen == null) return;
                      if (!context.mounted) return;
                      setDialogState(() => imagenPremio = imagen);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.photo),
                        const SizedBox(width: 8),
                        Text(
                          imagenPremio == null
                              ? 'Agregar imagen'
                              : 'Cambiar imagen',
                        ),
                      ],
                    ),
                  ),
                  if (imagenPremio != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        imagenPremio!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Agregar'),
                  onPressed: () {
                    if (descripcionCtrl.text.trim().isEmpty) {
                      // Show valid alert in dialog context not supported easily for snackbar
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
      setState(
        () =>
            _error = 'La fecha de fin debe ser posterior a la fecha de inicio',
      );
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
        _mostrarExito('Rifa creada correctamente');
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
    final mensaje =
        e.getFieldError('fecha_inicio') ??
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
              Text(
                'Activa: $tituloActiva',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () =>
                Navigator.pop(context, _AccionConflictoRifa.cancelar),
            child: const Text('Cancelar rifa activa'),
          ),
          CupertinoDialogAction(
            onPressed: () =>
                Navigator.pop(context, _AccionConflictoRifa.finalizar),
            child: const Text('Finalizar rifa activa'),
          ),
          CupertinoDialogAction(
            onPressed: () =>
                Navigator.pop(context, _AccionConflictoRifa.descartar),
            child: const Text('Descartar cambios'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: DashboardColors.rojo),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: DashboardColors.verde),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final primaryColor = AppColorsPrimary.main;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Crear Rifa'),
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
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Datos de la rifa', isDark),
              _buildCard(
                isDark,
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _tituloCtrl,
                      placeholder: 'Título',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.title,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
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
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
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
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Fechas', isDark),
              _buildCard(
                isDark,
                child: Column(
                  children: [
                    _buildDateRow(
                      'Fecha Inicio',
                      _fechaInicio,
                      (d) => setState(() => _fechaInicio = d),
                      isDark,
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    _buildDateRow(
                      'Fecha Fin',
                      _fechaFin,
                      (d) => setState(() => _fechaFin = _finDeDia(d)),
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Imagen Principal', isDark),
              _buildCard(
                isDark,
                child: Row(
                  children: [
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: _pickImage,
                      child: const Text('Seleccionar'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _imagen == null
                          ? Text(
                              'Sin imagen',
                              style: TextStyle(color: Colors.grey[500]),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imagen!,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Premios', isDark),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _premios.length < 3 ? _agregarPremio : null,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.add_circled, size: 20),
                        const SizedBox(width: 4),
                        Text('Agregar (${_premios.length}/3)'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_premios.isEmpty)
                _buildCard(
                  isDark,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No hay premios agregados',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                )
              else
                ..._premios.asMap().entries.map((entry) {
                  final index = entry.key;
                  final premio = entry.value;
                  return _buildPremioCard(premio, index, isDark);
                }),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(
                  _error!,
                  style: const TextStyle(color: DashboardColors.rojo),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _enviando ? null : _crear,
                  child: _enviando
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text('Crear Rifa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildDateRow(
    String label,
    DateTime date,
    ValueChanged<DateTime> onSelect,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _seleccionarFecha(initial: date, onSelected: onSelect),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(
                color: CupertinoColors.activeBlue,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremioCard(Map<String, dynamic> premio, int index, bool isDark) {
    final imagen = premio['imagen'];
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
                _getNombrePosicion(
                  premio['posicion'],
                ).replaceAll('er', '').replaceAll('do', ''),
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
                    premio['descripcion'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (imagen != null && imagen is File) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(imagen, height: 40, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.trash,
                color: DashboardColors.rojo,
                size: 20,
              ),
              onPressed: () => setState(() {
                _premios.removeAt(index);
                _normalizarPremios();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
