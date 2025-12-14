
// lib/screens/admin/dashboard/widgets/detalle_solicitud_modal.dart
import 'package:flutter/material.dart';
import '../../../../models/solicitud_cambio_rol.dart';
import '../constants/dashboard_colors.dart';

class DetalleSolicitudModal {
  static Future<void> mostrar({
    required BuildContext context,
    required SolicitudCambioRol solicitud,
    required Future<void> Function() onAceptar,
    required Future<void> Function(String motivo) onRechazar,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalleSolicitudContent(
        solicitud: solicitud,
        onAceptar: onAceptar,
        onRechazar: onRechazar,
      ),
    );
  }
}

class _DetalleSolicitudContent extends StatelessWidget {
  final SolicitudCambioRol solicitud;
  final Future<void> Function() onAceptar;
  final Future<void> Function(String motivo) onRechazar;

  const _DetalleSolicitudContent({
    required this.solicitud,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(),
          Expanded(
            child: _buildContenido(),
          ),
          if (solicitud.estaPendiente) _buildBotonesAccion(context),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: solicitud.esProveedor
                ? DashboardColors.verde
                : DashboardColors.azul,
            child: Icon(
              solicitud.iconoRol,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud de ${solicitud.rolTexto}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  solicitud.usuarioEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DashboardColors.gris,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetalleItem('Usuario', solicitud.usuarioNombre ?? 'Sin nombre'),
          _buildDetalleItem('Email', solicitud.usuarioEmail),
          _buildDetalleItem('Rol Solicitado', solicitud.rolTexto),
          _buildDetalleItem('Fecha', solicitud.fechaCreacionFormateada),
          _buildDetalleItem('Estado', solicitud.estadoTexto),
          const SizedBox(height: 16),
          const Text(
            'Motivo:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: DashboardColors.gris,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            solicitud.motivo,
            style: const TextStyle(fontSize: 14),
          ),
          if (solicitud.esProveedor) _buildDatosProveedor(),
          if (solicitud.esRepartidor) _buildDatosRepartidor(),
        ],
      ),
    );
  }

  Widget _buildDatosProveedor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Datos del Negocio:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (solicitud.nombreComercial != null)
          _buildDetalleItem('Nombre Comercial', solicitud.nombreComercial!),
        if (solicitud.ruc != null) _buildDetalleItem('RUC', solicitud.ruc!),
        if (solicitud.tipoNegocio != null)
          _buildDetalleItem('Tipo de Negocio', solicitud.tipoNegocioTexto!),
        if (solicitud.horarioApertura != null &&
            solicitud.horarioCierre != null)
          _buildDetalleItem(
            'Horario',
            '${solicitud.horarioApertura} - ${solicitud.horarioCierre}',
          ),
      ],
    );
  }

  Widget _buildDatosRepartidor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Datos del Repartidor:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (solicitud.cedulaIdentidad != null)
          _buildDetalleItem('Cédula', solicitud.cedulaIdentidad!),
        if (solicitud.tipoVehiculo != null)
          _buildDetalleItem('Vehículo', solicitud.tipoVehiculoTexto!),
        if (solicitud.zonaCobertura != null)
          _buildDetalleItem('Zona de Cobertura', solicitud.zonaCobertura!),
      ],
    );
  }

  Widget _buildDetalleItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: DashboardColors.gris,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _mostrarDialogoRechazo(context);
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Rechazar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DashboardColors.rojo,
                side: const BorderSide(color: DashboardColors.rojo),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _mostrarDialogoAceptar(context);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Aceptar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardColors.verde,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoAceptar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Solicitud'),
        content: Text(
          '¿Estás seguro de aceptar la solicitud de ${solicitud.usuarioEmail} para ser ${solicitud.rolTexto}?',
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
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await onAceptar();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: DashboardColors.rojo,
            ),
          );
        }
      }
    }
  }

  Future<void> _mostrarDialogoRechazo(BuildContext context) async {
    final motivoController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Por qué rechazas la solicitud de ${solicitud.usuarioEmail}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
                hintText: 'Describe el motivo...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardColors.rojo,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final motivo = motivoController.text.trim();
      if (motivo.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes especificar un motivo'),
              backgroundColor: DashboardColors.rojo,
            ),
          );
        }
        return;
      }

      try {
        await onRechazar(motivo);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: DashboardColors.rojo,
            ),
          );
        }
      }
    }
  }
}