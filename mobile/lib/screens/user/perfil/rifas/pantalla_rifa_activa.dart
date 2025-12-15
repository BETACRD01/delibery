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
    final progreso = (pedidosMinimos > 0)
        ? (pedidosCompletados / pedidosMinimos).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Rifa del mes',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      if (diasRestantes.isNotEmpty)
                        _buildChip(Icons.timelapse, '$diasRestantes días', small: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (premio.isNotEmpty)
                    Text(
                      premio,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (valor.isNotEmpty) _buildChip(Icons.card_giftcard, 'Premio: $valor'),
                      if (fechaSorteo.isNotEmpty) _buildChip(Icons.event, 'Sorteo: $fechaSorteo'),
                      _buildChip(Icons.people, 'Participantes: $totalParticipantes'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu elegibilidad',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          elegible ? Icons.verified_rounded : Icons.info_outline,
                          color: elegible ? JPColors.success : JPColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            elegible
                                ? '¡Ya estás dentro!'
                                : 'Completa los pedidos para participar.',
                            style: TextStyle(
                              color: elegible ? JPColors.success : JPColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '$pedidosCompletados / $pedidosMinimos pedidos',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${(progreso * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progreso,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8EEF5),
                        valueColor: const AlwaysStoppedAnimation<Color>(JPColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child:const  Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cómo participar',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    _Paso(texto: 'Realiza tus pedidos habituales hasta cumplir el mínimo.'),
                    SizedBox(height: 6),
                    _Paso(texto: 'Una vez cumplido, quedas inscrito automáticamente.'),
                    SizedBox(height: 6),
                    _Paso(texto: 'Revisa esta sección para ver fecha de sorteo y participantes.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: small ? 14 : 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white, fontSize: small ? 11 : 12)),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  final String texto;
  const _Paso({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle, size: 16, color: JPColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 13.5,
              color: JPColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
