// lib/screens/user/perfil/solicitudes_rol/pantalla_solicitar_rol.dart

import 'package:flutter/cupertino.dart';
import 'widgets/formulario_proveedor.dart';
import 'widgets/formulario_repartidor.dart';
import 'pantalla_mis_solicitudes.dart';

/// 🎯 PANTALLA PARA SOLICITAR CAMBIO DE ROL
/// Permite elegir entre Proveedor o Repartidor y llenar el formulario
class PantallaSolicitarRol extends StatefulWidget {
  final String? rolInicial; // 'PROVEEDOR' o 'REPARTIDOR'

  const PantallaSolicitarRol({super.key, this.rolInicial});

  @override
  State<PantallaSolicitarRol> createState() => _PantallaSolicitarRolState();
}

class _PantallaSolicitarRolState extends State<PantallaSolicitarRol> {
  // ══════════════════════════════════════════════════════════════════════════════
  // 📊 ESTADO
  // ══════════════════════════════════════════════════════════════════════════════

  String? _rolSeleccionado;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ══════════════════════════════════════════════════════════════════════════════
  // 🔄 LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _rolSeleccionado = widget.rolInicial;

    // Si viene con rol inicial, avanzar automáticamente
    if (widget.rolInicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _avanzarAPagina(1);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: _buildNavigationBar(),
      child: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: [_buildPaginaSeleccion(), _buildPaginaFormulario()],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 📱 NAVIGATION BAR - ESTILO iOS
  // ══════════════════════════════════════════════════════════════════════════════

  ObstructingPreferredSizeWidget _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: CupertinoColors.systemBackground
          .resolveFrom(context)
          .withValues(alpha: 0.9),
      border: Border(
        bottom: BorderSide(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      leading: CupertinoNavigationBarBackButton(
        onPressed: () {
          if (_currentPage == 1) {
            _avanzarAPagina(0);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      middle: Text(
        _currentPage == 0 ? 'Selecciona tu rol' : 'Completa tu solicitud',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 📄 PÁGINA 1: SELECCIÓN DE ROL - ESTILO iOS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPaginaSeleccion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Título grande estilo iOS
          const Text(
            '¿Qué rol deseas?',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige el rol que mejor se adapte a lo que quieres hacer',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 16),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _irAMisSolicitudes,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_search,
                    color: CupertinoColors.systemBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ver estado de mis solicitudes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: CupertinoColors.systemBlue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Tarjeta PROVEEDOR - iOS Style
          _buildTarjetaRolIOS(
            icon: CupertinoIcons.building_2_fill,
            titulo: 'Proveedor',
            descripcion: 'Ofrece tus productos y servicios a la comunidad',
            color: CupertinoColors.systemBlue,
            seleccionado: _rolSeleccionado == 'PROVEEDOR',
            onTap: () => setState(() => _rolSeleccionado = 'PROVEEDOR'),
          ),

          const SizedBox(height: 16),

          // Tarjeta REPARTIDOR - iOS Style
          _buildTarjetaRolIOS(
            icon: CupertinoIcons.car_fill,
            titulo: 'Repartidor',
            descripcion: 'Entrega pedidos y gana dinero con cada delivery',
            color: CupertinoColors.systemGreen,
            seleccionado: _rolSeleccionado == 'REPARTIDOR',
            onTap: () => setState(() => _rolSeleccionado = 'REPARTIDOR'),
          ),

          const SizedBox(height: 32),

          // Botón continuar - Estilo iOS
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _rolSeleccionado != null
                  ? const LinearGradient(
                      colors: [
                        CupertinoColors.activeBlue,
                        CupertinoColors.systemBlue,
                      ],
                    )
                  : null,
              color: _rolSeleccionado == null
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : null,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _rolSeleccionado != null
                  ? () => _avanzarAPagina(1)
                  : null,
              child: Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _rolSeleccionado != null
                      ? CupertinoColors.white
                      : CupertinoColors.systemGrey,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🎨 TARJETA DE ROL - ESTILO iOS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildTarjetaRolIOS({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Color color,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado
                ? color
                : CupertinoColors.separator.resolveFrom(context),
            width: seleccionado ? 2.5 : 1,
          ),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icono circular
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark o chevron
            Icon(
              seleccionado
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.chevron_right,
              color: seleccionado
                  ? color
                  : CupertinoColors.systemGrey3.resolveFrom(context),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 📄 PÁGINA 2: FORMULARIO
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPaginaFormulario() {
    if (_rolSeleccionado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona un rol primero',
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      );
    }

    return _rolSeleccionado == 'PROVEEDOR'
        ? FormularioProveedor(
            onSubmitSuccess: _handleSubmitSuccess,
            onBack: () => _avanzarAPagina(0),
          )
        : FormularioRepartidor(
            onSubmitSuccess: _handleSubmitSuccess,
            onBack: () => _avanzarAPagina(0),
          );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🎬 ACCIONES
  // ══════════════════════════════════════════════════════════════════════════════

  void _avanzarAPagina(int pagina) {
    _pageController.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleSubmitSuccess() {
    Navigator.pop(context, true);
  }

  void _irAMisSolicitudes() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => const PantallaMisSolicitudes(),
      ),
    );
  }
}
