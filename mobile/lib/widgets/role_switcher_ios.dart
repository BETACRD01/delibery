// lib/widgets/role_switcher_ios.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoleSwitcherIOS extends StatefulWidget {
  final Map<String, String> opciones;
  final String? rolSeleccionado;
  final bool cargando;
  final ValueChanged<String> onChanged;
  final Set<String> rolesDeshabilitados;
  final String? mensajeRolBloqueado;

  const RoleSwitcherIOS({
    super.key,
    required this.opciones,
    required this.rolSeleccionado,
    required this.onChanged,
    this.cargando = false,
    this.rolesDeshabilitados = const {},
    this.mensajeRolBloqueado,
  });

  @override
  State<RoleSwitcherIOS> createState() => _RoleSwitcherIOSState();
}

class _RoleSwitcherIOSState extends State<RoleSwitcherIOS>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragPositionFraction = 0.0;
  int _selectedIndex = 0;
  bool _isChangingRole = false; // Lock para evitar cambios múltiples

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _initializePosition();
  }

  @override
  void didUpdateWidget(RoleSwitcherIOS oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rolSeleccionado != widget.rolSeleccionado) {
      _initializePosition();
    }
  }

  void _initializePosition() {
    final keys = widget.opciones.keys.toList();
    final currentRole = widget.rolSeleccionado;

    // Guardar el índice del rol actual (para saber a dónde volver si se arrepiente)
    _selectedIndex = keys.indexOf(currentRole ?? keys.first);
    if (_selectedIndex == -1) _selectedIndex = 0;

    // El círculo siempre empieza en el CENTRO (0.5)
    _dragPositionFraction = 0.5;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _iconForRole(String rol) {
    switch (rol.toUpperCase()) {
      case 'PROVEEDOR':
        return CupertinoIcons.cube_box_fill;
      case 'REPARTIDOR':
        return CupertinoIcons.car_fill;
      default:
        return CupertinoIcons.person_fill;
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _animationController.stop();
  }

  void _onHorizontalDragUpdate(
    DragUpdateDetails details,
    double trackWidth,
  ) {
    setState(() {
      final pixelPosition = _dragPositionFraction * trackWidth;
      final newPixelPosition =
          (pixelPosition + details.delta.dx).clamp(0.0, trackWidth);
      _dragPositionFraction = newPixelPosition / trackWidth;
    });
  }

  void _onHorizontalDragEnd(
    DragEndDetails details,
    double trackWidth,
  ) {
    final keys = widget.opciones.keys.toList();
    if (keys.length < 2) return;

    // Umbral para confirmar cambio: debe estar > 60% hacia un lado
    const double threshold = 0.6;
    int? newIndex;

    if (_dragPositionFraction > threshold) {
      newIndex = 1; // Repartidor
    } else if (_dragPositionFraction < (1 - threshold)) {
      newIndex = 0; // Proveedor
    }

    // Si no llegó al umbral, volver al centro sin cambiar
    if (newIndex == null) {
      _animateToCenterPosition();
      return;
    }

    // Verificar si el rol está deshabilitado
    if (widget.rolesDeshabilitados.contains(keys[newIndex])) {
      HapticFeedback.heavyImpact();
      _animateToPosition(_selectedIndex);
      _mostrarMensajeRolBloqueado();
      return;
    }

    // Evitar cambios múltiples
    if (_isChangingRole) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _selectedIndex = newIndex!;
      _isChangingRole = true;
    });

    // Animar a la nueva posición
    _animateToPosition(newIndex);

    // Callback con el nuevo rol (solo una vez)
    if (newIndex < keys.length) {
      widget.onChanged(keys[newIndex]);
    }

    // Liberar el lock después de un delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isChangingRole = false;
        });
      }
    });
  }

  void _animateToPosition(int index) {
    final targetFraction = index == 0 ? 0.0 : 1.0;
    final startFraction = _dragPositionFraction;

    _animation = Tween<double>(
      begin: startFraction,
      end: targetFraction,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragPositionFraction = targetFraction;
        });
      }
    });

    _animation.addListener(() {
      if (mounted) {
        setState(() {
          _dragPositionFraction = _animation.value;
        });
      }
    });
  }

  void _animateToCenterPosition() {
    final startFraction = _dragPositionFraction;

    _animation = Tween<double>(
      begin: startFraction,
      end: 0.5, // Volver al centro
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragPositionFraction = 0.5;
        });
      }
    });

    _animation.addListener(() {
      if (mounted) {
        setState(() {
          _dragPositionFraction = _animation.value;
        });
      }
    });
  }

  void _onTap(int index) {
    if (_selectedIndex == index || _isChangingRole) return;

    final keys = widget.opciones.keys.toList();

    if (widget.rolesDeshabilitados.contains(keys[index])) {
      HapticFeedback.heavyImpact();
      _mostrarMensajeRolBloqueado();
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _selectedIndex = index;
      _isChangingRole = true;
    });

    _animateToPosition(index);

    if (index < keys.length) {
      widget.onChanged(keys[index]);
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isChangingRole = false;
        });
      }
    });
  }

  void _mostrarMensajeRolBloqueado() {
    final mensaje = widget.mensajeRolBloqueado ??
        'Este rol no está disponible. Solicita la aprobación desde la sección de Solicitudes.';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rol no disponible'),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (widget.opciones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No hay roles disponibles',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 14,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildDraggableSwitch(constraints.maxWidth);
      },
    );
  }

  Widget _buildDraggableSwitch(double maxWidth) {
    final keys = widget.opciones.keys.toList();
    if (keys.length < 2) {
      return _buildSimpleSwitch();
    }

    // Configuración de tamaños
    const double circleSize = 36.0;
    const double trackHeight = 56.0;
    const double sidePadding = 20.0;

    final double trackWidth = maxWidth - (sidePadding * 2) - circleSize;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(details, trackWidth),
      onHorizontalDragEnd: (details) =>
          _onHorizontalDragEnd(details, trackWidth),
      child: Container(
        height: trackHeight,
        width: maxWidth,
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Labels fijos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Proveedor (izquierda)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(0),
                    child: _buildFixedLabel(
                      keys[0],
                      widget.opciones[keys[0]]!,
                      _selectedIndex == 0,
                      Alignment.centerLeft,
                    ),
                  ),
                ),

                const SizedBox(width: circleSize),

                // Repartidor (derecha)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(1),
                    child: _buildFixedLabel(
                      keys[1],
                      widget.opciones[keys[1]]!,
                      _selectedIndex == 1,
                      Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            ),

            // Círculo deslizante
            Positioned(
              left: _dragPositionFraction * trackWidth,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CupertinoColors.systemBlue.resolveFrom(context),
                      CupertinoColors.systemBlue
                          .resolveFrom(context)
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemBlue
                          .resolveFrom(context)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    // Mostrar ícono neutral si está en el centro
                    _dragPositionFraction > 0.4 && _dragPositionFraction < 0.6
                        ? CupertinoIcons.arrow_right_arrow_left
                        : _iconForRole(keys[_selectedIndex]),
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedLabel(
    String roleKey,
    String roleLabel,
    bool isSelected,
    Alignment alignment,
  ) {
    final isDisabled = widget.rolesDeshabilitados.contains(roleKey);

    return Container(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              roleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : (isDisabled
                        ? CupertinoColors.systemGrey.resolveFrom(context)
                        : CupertinoColors.secondaryLabel.resolveFrom(context)),
              ),
            ),
          ),
          if (isDisabled) ...[
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.lock_fill,
              size: 12,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleSwitch() {
    // Widget estático para cuando solo hay un rol
    final entry = widget.opciones.entries.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoColors.systemBlue.resolveFrom(context),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue
                .resolveFrom(context)
                .withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.resolveFrom(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForRole(entry.key),
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
