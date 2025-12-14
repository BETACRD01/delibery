// lib/screens/user/perfil/solicitudes_rol/pantalla_mis_solicitudes.dart

import 'package:flutter/material.dart';
import '../../../../theme/jp_theme.dart';
import '../../../../services/solicitudes_service.dart';
import '../../../../models/solicitud_cambio_rol.dart';
import 'pantalla_solicitar_rol.dart';

/// 📋 PANTALLA DE MIS SOLICITUDES (OPTIMIZADA)
class PantallaMisSolicitudes extends StatefulWidget {
  const PantallaMisSolicitudes({super.key});

  @override
  State<PantallaMisSolicitudes> createState() => _PantallaMisSolicitudesState();
}

class _PantallaMisSolicitudesState extends State<PantallaMisSolicitudes> {
  final _solicitudesService = SolicitudesService();
  
  List<SolicitudCambioRol> _solicitudes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await _solicitudesService.obtenerMisSolicitudes();
      
      // Lógica de lectura flexible (results o directo)
      List<dynamic>? listaJson;
      if (response.containsKey('results')) {
        listaJson = response['results'] as List<dynamic>;
      } else if (response is List) {
        listaJson = response as List<dynamic>;
      } else if (response.containsKey('solicitudes')) {
        listaJson = response['solicitudes'] as List<dynamic>;
      }

      if (mounted) {
        setState(() {
          _solicitudes = listaJson?.map((json) => SolicitudCambioRol.fromJson(json)).toList() ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar las solicitudes';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        title: const Text('Mis Solicitudes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: JPColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearSolicitud,
        backgroundColor: JPColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Solicitud', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: JPColors.error),
            const SizedBox(height: 16),
            Text(_error!),
            TextButton(onPressed: _cargarSolicitudes, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Aún no tienes solicitudes', style: TextStyle(color: JPColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitudes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _SolicitudCard(solicitud: _solicitudes[index]),
      ),
    );
  }

  void _crearSolicitud() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PantallaSolicitarRol()),
    );
    if (resultado == true) _cargarSolicitudes();
  }
}

/// 🎴 TARJETA DE SOLICITUD (COMPONENTE PRIVADO OPTIMIZADO)
class _SolicitudCard extends StatelessWidget {
  final SolicitudCambioRol solicitud;

  const _SolicitudCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Icono + Rol + Estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JPColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(solicitud.iconoRol, size: 20, color: JPColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.rolTexto,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        solicitud.fechaCreacionFormateada,
                        style: const TextStyle(fontSize: 12, color: JPColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _EstadoBadge(solicitud: solicitud),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Datos Resumen
            _DatoFila(
              icon: Icons.info_outline,
              label: solicitud.esProveedor ? 'Negocio' : 'Vehículo',
              value: solicitud.esProveedor 
                  ? (solicitud.nombreComercial ?? 'N/A') 
                  : (solicitud.tipoVehiculoTexto ?? 'N/A'),
            ),

            // Respuesta del Admin (Solo si existe)
            if (solicitud.motivoRespuesta != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: solicitud.colorEstado.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: solicitud.colorEstado.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Respuesta Administrador:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: solicitud.colorEstado,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      solicitud.motivoRespuesta!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final SolicitudCambioRol solicitud;

  const _EstadoBadge({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: solicitud.colorEstado.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        solicitud.estadoTexto,
        style: TextStyle(
          color: solicitud.colorEstado,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DatoFila extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DatoFila({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: JPColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: JPColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}