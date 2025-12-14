import 'package:flutter/material.dart';
import '../../../../theme/jp_theme.dart';
import '../../../../services/usuarios_service.dart';
import '../../../../apis/helpers/api_exception.dart';

class PantallaRifaActiva extends StatefulWidget {
  const PantallaRifaActiva({super.key});

  @override
  State<PantallaRifaActiva> createState() => _PantallaRifaActivaState();
}

class _PantallaRifaActivaState extends State<PantallaRifaActiva> {
  final _usuarioService = UsuarioService();
  Map<String, dynamic>? _rifa;
  bool _loading = true;
  String? _error;

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
      final data = await _usuarioService.obtenerRifaActiva(forzarRecarga: true);
      _rifa = (data?['rifa'] ?? data?['rifa_activa'] ?? data) as Map<String, dynamic>?;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'No se pudo cargar la rifa activa';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rifa del mes'),
        backgroundColor: Colors.white,
        foregroundColor: JPColors.textPrimary,
        elevation: 1,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: JPColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_rifa == null) {
      return const Center(child: Text('No hay rifa activa en este momento'));
    }

    final titulo = _rifa!['titulo'] ?? 'Rifa';
    final premio = _rifa!['premio'] ?? '';
    final valor = _rifa!['valor_premio']?.toString() ?? '';
    final fechaSorteo = _rifa!['fecha_sorteo']?.toString() ?? '';
    final diasRestantes = _rifa!['dias_restantes']?.toString() ?? '';
    final totalParticipantes = _rifa!['total_participantes']?.toString() ?? '';
    final elegibilidad = _rifa!['mi_elegibilidad'] as Map<String, dynamic>?;
    final elegible = elegibilidad?['elegible'] == true;
    final pedidosCompletados = elegibilidad?['pedidos_completados'] ?? 0;
    final pedidosMinimos = _rifa!['pedidos_minimos'] ?? elegibilidad?['pedidos_minimos'] ?? 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  premio,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(Icons.card_giftcard, 'Premio: $valor'),
                    _buildChip(Icons.calendar_today, 'Sorteo: $fechaSorteo'),
                    _buildChip(Icons.timelapse, 'Días: $diasRestantes'),
                    _buildChip(Icons.people, 'Participantes: $totalParticipantes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu elegibilidad',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        elegible ? Icons.check_circle : Icons.info_outline,
                        color: elegible ? JPColors.success : JPColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          elegible
                              ? '¡Ya estás participando!'
                              : 'Te faltan pedidos para participar.',
                          style: TextStyle(
                            color: elegible ? JPColors.success : JPColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Pedidos completados: $pedidosCompletados'),
                  Text('Pedidos mínimos requeridos: $pedidosMinimos'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
