// lib/screens/admin/dashboard/widgets/detalle_solicitud_modal.dart
import 'package:flutter/material.dart';
import '../../../../models/auth/solicitud_cambio_rol.dart';
import '../constants/dashboard_colors.dart';

class DetalleSolicitudModal {
  static Future<void> mostrar({
    required BuildContext context,
    required SolicitudCambioRol solicitud,
    required Future<void> Function(String? motivo) onAceptar,
    required Future<void> Function(String motivo) onRechazar,
    Future<void> Function(String motivo)? onRevertir,
    Future<void> Function()? onEliminar,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalleSolicitudContent(
        solicitud: solicitud,
        onAceptar: onAceptar,
        onRechazar: onRechazar,
        onRevertir: onRevertir,
        onEliminar: onEliminar,
      ),
    );
  }
}

class _DetalleSolicitudContent extends StatefulWidget {
  final SolicitudCambioRol solicitud;
  final Future<void> Function(String? motivo) onAceptar;
  final Future<void> Function(String motivo) onRechazar;
  final Future<void> Function(String motivo)? onRevertir;
  final Future<void> Function()? onEliminar;

  const _DetalleSolicitudContent({
    required this.solicitud,
    required this.onAceptar,
    required this.onRechazar,
    this.onRevertir,
    this.onEliminar,
  });

  @override
  State<_DetalleSolicitudContent> createState() =>
      _DetalleSolicitudContentState();
}

class _DetalleSolicitudContentState extends State<_DetalleSolicitudContent> {
  final _motivoController = TextEditingController();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(context),
            const Divider(),
            Expanded(child: _buildContenido()),
            if (widget.solicitud.estaPendiente) ...[
              const Divider(height: 1),
              _buildCampoRespuesta(),
              _buildBotonesAccion(),
            ] else
              _buildBotonesAccionOtros(),
          ],
        ),
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
            backgroundColor: widget.solicitud.esProveedor
                ? DashboardColors.verde
                : DashboardColors.azul,
            child: Icon(
              widget.solicitud.iconoRol,
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
                  'Solicitud de ${widget.solicitud.rolTexto}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.solicitud.usuarioEmail,
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
          _buildDetalleItem(
            'Usuario',
            widget.solicitud.usuarioNombre ?? 'Sin nombre',
          ),
          _buildDetalleItem('Email', widget.solicitud.usuarioEmail),
          _buildDetalleItem('Rol Solicitado', widget.solicitud.rolTexto),
          _buildDetalleItem('Fecha', widget.solicitud.fechaCreacionFormateada),
          _buildDetalleItem('Estado', widget.solicitud.estadoTexto),

          if (widget.solicitud.respondidoEn != null) ...[
            const SizedBox(height: 16),
            _buildDetalleItem(
              'Respuesta Admin',
              widget.solicitud.motivoRespuesta ?? 'Sin motivo',
            ),
            _buildDetalleItem(
              'Fecha Respuesta',
              widget.solicitud.fechaRespuestaFormateada ?? '-',
            ),
          ],

          const SizedBox(height: 16),
          const Text(
            'Motivo del Usuario:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: DashboardColors.gris,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.solicitud.motivo,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (widget.solicitud.esProveedor) _buildDatosProveedor(),
          if (widget.solicitud.esRepartidor) _buildDatosRepartidor(),
        ],
      ),
    );
  }

  Widget _buildDatosProveedor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Datos del Negocio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.solicitud.nombreComercial != null)
          _buildDetalleItem(
            'Nombre Comercial',
            widget.solicitud.nombreComercial!,
          ),
        if (widget.solicitud.ruc != null)
          _buildDetalleItem('RUC', widget.solicitud.ruc!),
        if (widget.solicitud.tipoNegocio != null)
          _buildDetalleItem(
            'Tipo de Negocio',
            widget.solicitud.tipoNegocioTexto!,
          ),
        if (widget.solicitud.horarioApertura != null &&
            widget.solicitud.horarioCierre != null)
          _buildDetalleItem(
            'Horario',
            '${widget.solicitud.horarioApertura} - ${widget.solicitud.horarioCierre}',
          ),
      ],
    );
  }

  Widget _buildDatosRepartidor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Datos del Repartidor',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.solicitud.cedulaIdentidad != null)
          _buildDetalleItem('Cédula', widget.solicitud.cedulaIdentidad!),
        if (widget.solicitud.tipoVehiculo != null)
          _buildDetalleItem('Vehículo', widget.solicitud.tipoVehiculoTexto!),
        if (widget.solicitud.zonaCobertura != null)
          _buildDetalleItem(
            'Zona de Cobertura',
            widget.solicitud.zonaCobertura!,
          ),
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
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: DashboardColors.gris,
              ),
            ),
          ),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildCampoRespuesta() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Respuesta del Administrador:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: DashboardColors.gris,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _motivoController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Escribe un motivo de aprobación o rechazo...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final motivo = _motivoController.text.trim();
                if (motivo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor escribe un motivo para rechazar',
                      ),
                      backgroundColor: DashboardColors.rojo,
                    ),
                  );
                  return;
                }

                // Confirmación simple
                final confirm = await _mostrarConfirmacion(
                  context,
                  'Rechazar Solicitud',
                  '¿Estás seguro de rechazar esta solicitud?',
                  esDestructivo: true,
                );

                if (!mounted) return;

                if (confirm) {
                  Navigator.pop(context); // Cerrar modal
                  await widget.onRechazar(motivo);
                }
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
                final confirm = await _mostrarConfirmacion(
                  context,
                  'Aceptar Solicitud',
                  '¿Estás seguro de aceptar esta solicitud?',
                  esDestructivo: false,
                );

                if (!mounted) return;

                if (confirm) {
                  Navigator.pop(context); // Cerrar modal
                  final motivo = _motivoController.text.trim();
                  await widget.onAceptar(motivo.isEmpty ? null : motivo);
                }
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

  Widget _buildBotonesAccionOtros() {
    // Si no hay callbacks definidos, no mostrar nada
    if (widget.onRevertir == null && widget.onEliminar == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          if (widget.onEliminar != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await _mostrarConfirmacion(
                    context,
                    'Eliminar Registro',
                    '¿Estás seguro de eliminar permanentemente este registro?',
                    esDestructivo: true,
                  );

                  if (!mounted) return;

                  if (confirm) {
                    Navigator.pop(context);
                    await widget.onEliminar!();
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DashboardColors.rojo,
                  side: const BorderSide(color: DashboardColors.rojo),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          if (widget.onEliminar != null &&
              widget.onRevertir != null &&
              widget.solicitud.fueAceptada)
            const SizedBox(width: 12),

          if (widget.onRevertir != null && widget.solicitud.fueAceptada)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _mostrarDialogoRevertir(context);
                },
                icon: const Icon(Icons.undo),
                label: const Text('Revertir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoRevertir(BuildContext context) async {
    final motivoRevertirController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revertir Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Por qué deseas revertir la solicitud de ${widget.solicitud.usuarioEmail}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoRevertirController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de reversión',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Revertir'),
          ),
        ],
      ),
    );

    if (confirmar == true && widget.onRevertir != null) {
      final motivo = motivoRevertirController.text.trim();
      if (motivo.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debes escribir un motivo')),
          );
        }
        return;
      }
      try {
        await widget.onRevertir!(motivo);
      } catch (e) {
        // Error handling en parent
      }
    }
  }

  Future<bool> _mostrarConfirmacion(
    BuildContext context,
    String titulo,
    String mensaje, {
    required bool esDestructivo,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: esDestructivo
                      ? DashboardColors.rojo
                      : DashboardColors.verde,
                ),
                child: Text(esDestructivo ? 'Rechazar' : 'Aceptar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
