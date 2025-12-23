// lib/widgets/role/role_selector_modal.dart
// Widget unificado para selector de roles iOS-style
// Reemplaza los selectores duplicados en drawers y pantallas

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material, MaterialType;
import 'package:provider/provider.dart';
import '../../services/role_manager.dart';
import '../../switch/roles.dart';
import '../../theme/jp_theme.dart';

/// Muestra un modal iOS-style para seleccionar roles
/// Integra con RoleManager para mostrar estados y cambiar roles
void showRoleSelectorModal(BuildContext context) {
  final roleManager = context.read<RoleManager>();

  showCupertinoModalPopup<void>(
    context: context,
    builder: (modalContext) => _RoleSelectorModal(roleManager: roleManager),
  );
}

class _RoleSelectorModal extends StatefulWidget {
  final RoleManager roleManager;

  const _RoleSelectorModal({required this.roleManager});

  @override
  State<_RoleSelectorModal> createState() => _RoleSelectorModalState();
}

class _RoleSelectorModalState extends State<_RoleSelectorModal> {
  bool _isChanging = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: AnimatedBuilder(
                  animation: widget.roleManager,
                  builder: (context, _) {
                    if (widget.roleManager.isLoading) {
                      return _buildLoadingState();
                    }

                    if (widget.roleManager.error != null && !_isChanging) {
                      return _buildErrorState(widget.roleManager.error!);
                    }

                    return _buildRolesList();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: JPCupertinoColors.separator(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: JPCupertinoColors.tertiaryLabel(context),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cambiar Rol',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: JPCupertinoColors.label(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona el rol que deseas activar',
            style: TextStyle(
              fontSize: 14,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemRed(
                  context,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: JPCupertinoColors.systemRed(context),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        color: JPCupertinoColors.systemRed(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          const SizedBox(height: 16),
          Text(
            'Cargando roles disponibles...',
            style: TextStyle(
              fontSize: 14,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: JPCupertinoColors.systemRed(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar roles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.label(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: JPCupertinoColors.secondaryLabel(context),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => widget.roleManager.refresh(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesList() {
    final allRoles = widget.roleManager.allRoles;
    final activeRole = widget.roleManager.activeRole;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allRoles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final roleInfo = allRoles[index];
        return _buildRoleTile(roleInfo, roleInfo.role == activeRole);
      },
    );
  }

  Widget _buildRoleTile(RoleInfo roleInfo, bool isActive) {
    return GestureDetector(
      onTap: _isChanging ? null : () => _handleRoleChange(roleInfo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? JPCupertinoColors.systemBlue(context).withValues(alpha: 0.12)
              : JPCupertinoColors.systemGrey6(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? JPCupertinoColors.systemBlue(context).withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getRoleColor(roleInfo.role).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getRoleIcon(roleInfo.role),
                color: _getRoleColor(roleInfo.role),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleInfo.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.roleManager.getStatusMessage(roleInfo.role),
                    style: TextStyle(
                      fontSize: 13,
                      color: _getStatusColor(roleInfo.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            _buildStatusIndicator(roleInfo.status, isActive),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(RoleStatus status, bool isActive) {
    if (_isChanging && isActive) {
      return const CupertinoActivityIndicator();
    }

    switch (status) {
      case RoleStatus.active:
        return Icon(
          CupertinoIcons.checkmark_circle_fill,
          color: JPCupertinoColors.systemBlue(context),
          size: 24,
        );
      case RoleStatus.approved:
        return Icon(
          CupertinoIcons.checkmark_circle,
          color: JPCupertinoColors.systemGreen(context),
          size: 24,
        );
      case RoleStatus.pending:
        return Icon(
          CupertinoIcons.clock_fill,
          color: JPCupertinoColors.systemOrange(context),
          size: 24,
        );
      case RoleStatus.rejected:
        return Icon(
          CupertinoIcons.xmark_circle_fill,
          color: JPCupertinoColors.systemRed(context),
          size: 24,
        );
      case RoleStatus.notRequested:
        return Icon(
          CupertinoIcons.arrow_right_circle,
          color: JPCupertinoColors.tertiaryLabel(context),
          size: 24,
        );
    }
  }

  Color _getStatusColor(RoleStatus status) {
    switch (status) {
      case RoleStatus.active:
        return JPCupertinoColors.systemBlue(context);
      case RoleStatus.approved:
        return JPCupertinoColors.systemGreen(context);
      case RoleStatus.pending:
        return JPCupertinoColors.systemOrange(context);
      case RoleStatus.rejected:
        return JPCupertinoColors.systemRed(context);
      case RoleStatus.notRequested:
        return JPCupertinoColors.secondaryLabel(context);
    }
  }

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.user:
        return JPCupertinoColors.systemBlue(context);
      case AppRole.provider:
        return JPCupertinoColors.systemPurple(context);
      case AppRole.courier:
        return JPCupertinoColors.systemOrange(context);
    }
  }

  IconData _getRoleIcon(AppRole role) {
    switch (role) {
      case AppRole.user:
        return CupertinoIcons.person_fill;
      case AppRole.provider:
        return CupertinoIcons.building_2_fill;
      case AppRole.courier:
        return CupertinoIcons.cube_box_fill;
    }
  }

  Future<void> _handleRoleChange(RoleInfo roleInfo) async {
    // Validar que se puede cambiar
    if (!roleInfo.canActivate) {
      setState(() {
        _error = roleInfo.isPending
            ? 'Tu solicitud está en revisión'
            : roleInfo.isRejected
            ? 'Solicitud rechazada: ${roleInfo.rejectionReason ?? "Contacta soporte"}'
            : 'Este rol no está disponible';
      });
      return;
    }

    // Si ya está activo, no hacer nada
    if (roleInfo.isActive) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isChanging = true;
      _error = null;
    });

    try {
      final success = await widget.roleManager.switchRole(roleInfo.role);

      if (!mounted) return;

      if (success) {
        // Cerrar modal
        Navigator.pop(context);

        // Navegar según el rol
        _navigateToRoleScreen(roleInfo.role);
      } else {
        setState(() {
          _error = widget.roleManager.error ?? 'Error al cambiar de rol';
          _isChanging = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error inesperado: $e';
        _isChanging = false;
      });
    }
  }

  void _navigateToRoleScreen(AppRole role) {
    // Importar RoleRouter para la navegación
    // Por ahora simplemente pop y el router principal debería manejar
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
