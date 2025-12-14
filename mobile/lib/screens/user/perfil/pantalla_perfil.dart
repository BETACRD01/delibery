// lib/screens/user/perfil/pantalla_perfil.dart

import 'package:flutter/material.dart';
import '../../../theme/jp_theme.dart';
import '../../../controllers/user/perfil_controller.dart';
import 'editar/pantalla_editar_informacion.dart';
import 'editar/pantalla_editar_foto.dart';
import '../../solicitudes_rol/pantalla_mis_solicitudes.dart';
import '../../solicitudes_rol/pantalla_solicitar_rol.dart';
import 'configuracion/pantalla_configuracion.dart'; 
import 'rifas/pantalla_rifa_activa.dart';

/// 👤 PANTALLA DE PERFIL
class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  late final PerfilController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PerfilController();
    _cargarDatos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await _controller.cargarDatosCompletos();
  }

  Future<void> _recargarDatos() async {
    await _controller.cargarDatosCompletos(forzarRecarga: true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ⚙️ NAVEGACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  void _editarPerfil() async {
    if (_controller.perfil == null) return;
    
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEditarInformacion(perfil: _controller.perfil!),
      ),
    );
    
    if (resultado == true) _recargarDatos();
  }

  void _editarFoto() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEditarFoto(fotoActual: _controller.perfil?.fotoPerfilUrl),
      ),
    );
    if (resultado == true) _recargarDatos();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🎨 UI PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && !_controller.tieneDatos) {
            return const Center(child: JPLoading());
          }

          if (_controller.tieneError && !_controller.tieneDatos) {
            return _buildErrorState();
          }

          return RefreshIndicator(
            onRefresh: _recargarDatos,
            color: JPColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  if (_controller.errorPerfil != null || _controller.errorEstadisticas != null)
                    _buildWarningBanner(),

                  _buildHeader(), 

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildInfoPersonal(),
                        const SizedBox(height: 16),
                        _buildEstadisticas(),
                        const SizedBox(height: 16),
                        _buildRifasCard(),
                        const SizedBox(height: 24),
                        _buildCambioRol(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mi Perfil',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: Colors.white,
      foregroundColor: JPColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[200], height: 1),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configuración',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PantallaAjustes()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 👤 HEADER (LIMPIO: Sin lápiz redundante)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final perfil = _controller.perfil;
    if (perfil == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B8BD2), Color(0xFF12B6D4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A8ECF), Color(0xFF0FC2D7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: JPColors.primary.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: JPAvatar(
                        imageUrl: perfil.fotoPerfilUrl,
                        radius: 54,
                        onTap: _editarFoto,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      left: 0,
                      bottom: -4,
                      child: Center(child: _buildChangeChip()),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  perfil.usuarioNombre,
                  style: JPTextStyles.h2.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(perfil.usuarioEmail, style: JPTextStyles.bodySecondary),
                if (perfil.esClienteFrecuente) ...[
                  const SizedBox(height: 12),
                  const JPBadge(label: 'Cliente Frecuente', color: JPColors.secondary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeChip() {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _editarFoto,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child:const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, size: 16, color: JPColors.primary),
              SizedBox(width: 4),
              Text(
                'Cambiar',
                style: TextStyle(
                  color: JPColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 📋 INFORMACIÓN PERSONAL (Aquí se queda el botón "Editar")
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoPersonal() {
    final perfil = _controller.perfil;
    if (perfil == null) return const SizedBox.shrink();

    String fechaFormateada = 'Agregar fecha';
    if (perfil.fechaNacimiento != null) {
      final f = perfil.fechaNacimiento!;
      final dia = f.day.toString().padLeft(2, '0');
      final mes = f.month.toString().padLeft(2, '0');
      fechaFormateada = '$dia/$mes/${f.year}';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón Editar: Este es el principal ahora
            _buildSectionHeader('Información Personal', onEdit: _editarPerfil),
            
            const Divider(height: 28, color: Color(0xFFF0F0F0)),
            
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: perfil.telefono ?? 'Agregar teléfono',
              isPlaceholder: !perfil.tieneTelefono,
            ),
            const SizedBox(height: 18),
            _buildInfoRow(
              icon: Icons.cake_outlined,
              label: 'Nacimiento',
              value: fechaFormateada,
              isPlaceholder: perfil.fechaNacimiento == null,
            ),

            if (!_controller.perfilCompleto) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JPColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: JPColors.warning.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: JPColors.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _controller.mensajeCompletitud,
                        style: const TextStyle(color: JPColors.warning, fontSize: 13),
                      ),
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

  // ══════════════════════════════════════════════════════════════════════════
  // 📊 ESTADÍSTICAS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEstadisticas() {
    final perfil = _controller.perfil;

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Pedidos',
              '${perfil?.totalPedidos ?? 0}',
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey[200]),

          Expanded(
            child: _buildStatItem(
              'Calificación',
              perfil?.calificacion.toStringAsFixed(1) ?? '0.0',
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey[200]),

          Expanded(
            child: _buildStatItem(
              'Nivel',
              _controller.nivelCliente,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatItem(String label, String value, {Widget? badge}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: JPColors.primary),
                maxLines: 1,
              ),
            ),
            if (badge != null) ...[const SizedBox(width: 4), badge]
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: JPColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRifasCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JPColors.primary.withValues(alpha: 0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.confirmation_num_outlined, color: JPColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rifas',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: JPColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildRifaStat('Participaciones', '${_controller.rifasParticipadas}'),
                      const SizedBox(width: 16),
                      _buildRifaStat('Ganadas', '${_controller.rifasGanadas}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _verRifaActiva,
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text(
                        'Ver rifa activa',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRifaStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: JPColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: JPColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🚀 BANNER CAMBIO ROL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCambioRol() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JPColors.primary.withValues(alpha: 0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: JPColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Genera ingresos extra',
                  style: JPTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Conviértete en Proveedor o Repartidor hoy mismo.',
            style: TextStyle(
              color: JPColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _irASeleccionarRol,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JPColors.primary,
                    side: BorderSide(color: JPColors.primary.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Aplicar ahora',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _verMisSolicitudes,
                style: TextButton.styleFrom(
                  foregroundColor: JPColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                child: const Text(
                  'Ver solicitudes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🧩 WIDGETS AUXILIARES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: JPTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
        if (onEdit != null)
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text(
                'Editar',
                style: TextStyle(
                  color: JPColors.primary, 
                  fontWeight: FontWeight.w600, 
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, bool isPlaceholder = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JPColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: JPColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: JPColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isPlaceholder ? JPColors.textHint : JPColors.textPrimary,
                  fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: JPColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: JPColors.warning.withAlpha(128)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: JPColors.warning),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Alguna información no se pudo cargar.',
              style: TextStyle(color: JPColors.warning, fontSize: 13),
            ),
          ),
          InkWell(
            onTap: _recargarDatos,
            child: const Icon(Icons.refresh, color: JPColors.warning),
          )
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: JPColors.error),
          const SizedBox(height: 16),
          Text('Error al cargar perfil', style: JPTextStyles.h3.copyWith(color: JPColors.error)),
          const SizedBox(height: 8),
          Text(_controller.error ?? 'Ocurrió un problema inesperado', textAlign: TextAlign.center, style: JPTextStyles.bodySecondary),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _recargarDatos, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ⚙️ LÓGICA DE ACCIONES
  // ══════════════════════════════════════════════════════════════════════════

  void _irASeleccionarRol() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PantallaSolicitarRol()),
    );
    if (resultado == true) {
      // Acción al volver si es necesaria
    }
  }

  void _verMisSolicitudes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaMisSolicitudes()),
    );
  }

  void _verRifaActiva() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaRifaActiva()),
    );
  }
}
