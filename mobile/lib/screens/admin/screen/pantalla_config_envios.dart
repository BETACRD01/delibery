import 'package:flutter/material.dart';

import '../../../apis/admin/envios_admin_api.dart';
import '../../../widgets/common/loading_widget.dart';
import '../dashboard/constants/dashboard_colors.dart';

class PantallaConfigEnviosAdmin extends StatefulWidget {
  const PantallaConfigEnviosAdmin({super.key});

  @override
  State<PantallaConfigEnviosAdmin> createState() =>
      _PantallaConfigEnviosAdminState();
}

class _PantallaConfigEnviosAdminState extends State<PantallaConfigEnviosAdmin> {
  final EnviosAdminApi _api = EnviosAdminApi();

  List<dynamic> _zonas = [];
  List<dynamic> _ciudades = [];
  bool _loading = true;
  String? _error;

  final _recargoCtrl = TextEditingController();
  final _horaInicioCtrl = TextEditingController();
  final _horaFinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await _api.obtenerConfiguracion();
      final zonas = await _api.listarZonas();
      final ciudades = await _api.listarCiudades();

      _recargoCtrl.text = (config['recargo_nocturno'] ?? '').toString();
      _horaInicioCtrl.text = (config['hora_inicio_nocturno'] ?? '').toString();
      _horaFinCtrl.text = (config['hora_fin_nocturno'] ?? '').toString();

      setState(() {
        _zonas = zonas;
        _ciudades = ciudades;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo cargar la configuración: $e';
        _loading = false;
      });
    }
  }

  Future<void> _guardarConfig() async {
    try {
      final payload = {
        'recargo_nocturno': double.tryParse(_recargoCtrl.text) ?? 0,
        'hora_inicio_nocturno': int.tryParse(_horaInicioCtrl.text) ?? 0,
        'hora_fin_nocturno': int.tryParse(_horaFinCtrl.text) ?? 0,
      };
      final data = await _api.actualizarConfiguracion(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
      setState(() {
        _recargoCtrl.text = (data['recargo_nocturno'] ?? '').toString();
        _horaInicioCtrl.text = (data['hora_inicio_nocturno'] ?? '').toString();
        _horaFinCtrl.text = (data['hora_fin_nocturno'] ?? '').toString();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Future<void> _editarZona(Map<String, dynamic> zona) async {
    final nombreCtrl = TextEditingController(
      text: zona['nombre_display']?.toString() ?? '',
    );
    final baseCtrl = TextEditingController(
      text: zona['tarifa_base']?.toString() ?? '',
    );
    final incluidosCtrl = TextEditingController(
      text: zona['km_incluidos']?.toString() ?? '',
    );
    final extraCtrl = TextEditingController(
      text: zona['precio_km_extra']?.toString() ?? '',
    );
    final maxCtrl = TextEditingController(
      text: zona['max_distancia_km']?.toString() ?? '',
    );
    final ordenCtrl = TextEditingController(
      text: zona['orden']?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar zona ${zona['codigo']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(nombreCtrl, 'Nombre para mostrar', isNumber: false),
              _buildField(baseCtrl, 'Tarifa base'),
              _buildField(incluidosCtrl, 'Km incluidos'),
              _buildField(extraCtrl, 'Precio km extra'),
              _buildField(maxCtrl, 'Max distancia (vacío para ilimitado)'),
              _buildField(ordenCtrl, 'Orden'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final payload = {
      'nombre_display': nombreCtrl.text,
      'tarifa_base': double.tryParse(baseCtrl.text) ?? 0,
      'km_incluidos': double.tryParse(incluidosCtrl.text) ?? 0,
      'precio_km_extra': double.tryParse(extraCtrl.text) ?? 0,
      'max_distancia_km': maxCtrl.text.isEmpty
          ? null
          : double.tryParse(maxCtrl.text),
      'orden': int.tryParse(ordenCtrl.text) ?? 0,
    };

    await _api.actualizarZona(zona['id'] as int, payload);
    await _cargar();
  }

  Future<void> _editarCiudad(Map<String, dynamic> ciudad) async {
    final nombreCtrl = TextEditingController(
      text: ciudad['nombre']?.toString() ?? '',
    );
    final latCtrl = TextEditingController(
      text: ciudad['lat']?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: ciudad['lng']?.toString() ?? '',
    );
    final radioCtrl = TextEditingController(
      text: ciudad['radio_max_cobertura_km']?.toString() ?? '',
    );
    final activo = ValueNotifier<bool>(ciudad['activo'] == true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar ciudad ${ciudad['codigo']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(nombreCtrl, 'Nombre', isNumber: false),
              _buildField(latCtrl, 'Latitud'),
              _buildField(lngCtrl, 'Longitud'),
              _buildField(radioCtrl, 'Radio cobertura (km)'),
              ValueListenableBuilder<bool>(
                valueListenable: activo,
                builder: (_, value, _) => SwitchListTile(
                  title: const Text('Activo'),
                  value: value,
                  onChanged: (v) => activo.value = v,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final payload = {
      'nombre': nombreCtrl.text,
      'lat': double.tryParse(latCtrl.text) ?? 0,
      'lng': double.tryParse(lngCtrl.text) ?? 0,
      'radio_max_cobertura_km': double.tryParse(radioCtrl.text) ?? 0,
      'activo': activo.value,
    };

    await _api.actualizarCiudad(ciudad['id'] as int, payload);
    await _cargar();
  }

  TextField _buildField(
    TextEditingController controller,
    String label, {
    bool isNumber = true,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar envíos'),
        elevation: 0,
        backgroundColor: DashboardColors.morado,
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildConfigCard(),
                  const SizedBox(height: 12),
                  _buildZonas(),
                  const SizedBox(height: 12),
                  _buildCiudades(),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recargo nocturno',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recargoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Valor en USD'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _horaInicioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hora inicio (0-23)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _horaFinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hora fin (0-23)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _guardarConfig,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zonas tarifarias',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._zonas.map(
              (z) => ListTile(
                title: Text('${z['codigo']} • ${z['nombre_display']}'),
                subtitle: Text(
                  'Base ${z['tarifa_base']} | Incluye ${z['km_incluidos']} km | Extra ${z['precio_km_extra']}/km '
                  '| Máx ${z['max_distancia_km'] ?? '∞'} km | Orden ${z['orden']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editarZona(Map<String, dynamic>.from(z)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCiudades() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hubs / Ciudades',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._ciudades.map(
              (c) => ListTile(
                title: Text('${c['codigo']} • ${c['nombre']}'),
                subtitle: Text(
                  'Lat ${c['lat']}, Lng ${c['lng']} | Radio ${c['radio_max_cobertura_km']} km | '
                  'Activo: ${c['activo'] == true ? 'Sí' : 'No'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editarCiudad(Map<String, dynamic>.from(c)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
