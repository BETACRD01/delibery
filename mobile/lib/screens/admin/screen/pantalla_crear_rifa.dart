import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../apis/admin/rifas_admin_api.dart';
import '../../../apis/helpers/api_exception.dart';
import '../dashboard/constants/dashboard_colors.dart';

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
    final siguienteMes = ahora.month == 12 ? 1 : ahora.month + 1;
    final anioSiguienteMes = ahora.month == 12 ? ahora.year + 1 : ahora.year;

    _fechaInicio = DateTime(anioSiguienteMes, siguienteMes, 1);
    _fechaFin = DateTime(anioSiguienteMes, siguienteMes + 1, 0);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _pedidosMinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imagen = File(picked.path));
    }
  }

  Future<void> _seleccionarFecha({
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) onSelected(fecha);
  }

  void _agregarPremio() {
    if (_premios.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 premios')),
      );
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
                        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (picked != null) {
                          setDialogState(() => imagenPremio = File(picked.path));
                        }
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (descripcionCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa la descripción')),
                      );
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

  Future<void> _crear() async {
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
        () => _error = 'La fecha de fin debe ser posterior a la fecha de inicio',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rifa creada correctamente'),
            backgroundColor: DashboardColors.verde,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.getUserFriendlyMessage());
    } catch (e) {
      setState(() => _error = 'No se pudo crear la rifa: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Crear rifa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFF2F2F7),
        foregroundColor: DashboardColors.morado,
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
                      subtitle: Text(
                        _fechaInicio.toLocal().toString().split(' ').first,
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _seleccionarFecha(
                        initial: _fechaInicio,
                        onSelected: (f) => setState(() => _fechaInicio = f),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha fin'),
                      subtitle: Text(
                        _fechaFin.toLocal().toString().split(' ').first,
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _seleccionarFecha(
                        initial: _fechaFin,
                        onSelected: (f) => setState(() => _fechaFin = f),
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
                          ? const Text(
                              'Sin imagen seleccionada',
                              style: TextStyle(color: Colors.grey),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _imagen!,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
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
                      backgroundColor: DashboardColors.morado,
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
                      child: Text(
                        'No hay premios agregados',
                        style: TextStyle(color: Colors.grey),
                      ),
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
                Text(
                  _error!,
                  style: const TextStyle(color: DashboardColors.rojo),
                ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_enviando ? 'Creando...' : 'Crear rifa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.morado,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
              color: DashboardColors.morado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _getNombrePosicion(premio['posicion']),
              style: const TextStyle(
                color: DashboardColors.morado,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (imagen != null && imagen is File)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      imagen,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Text(
                    'Sin imagen',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
