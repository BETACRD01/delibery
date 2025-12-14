// lib/screens/user/perfil/solicitudes_rol/widgets/tarjeta_seleccion_rol.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../models/solicitud_cambio_rol.dart';

/// 🎴 TARJETA PARA SELECCIONAR ROL
/// Diseño: Clean UI / Minimalista
class TarjetaSeleccionRol extends StatelessWidget {
  final RolSolicitable rol;
  final bool seleccionado;
  final VoidCallback onTap;

  const TarjetaSeleccionRol({
    super.key,
    required this.rol,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Definir color según el rol
    // Proveedor: Naranja (Secondary) | Repartidor: Azul (Primary)
    final color = rol == RolSolicitable.proveedor
        ? JPColors.secondary
        : JPColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: seleccionado ? Colors.white : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: seleccionado ? color : Colors.grey.shade200,
              width: seleccionado ? 2 : 1,
            ),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono con fondo suave
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rol.icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  
                  // Título del Rol
                  Expanded(
                    child: Text(
                      rol.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: seleccionado ? color : JPColors.textPrimary,
                      ),
                    ),
                  ),

                  // Checkbox personalizado
                  _buildCheckbox(color),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),

              // Descripción
              Text(
                _getDescripcion(rol),
                style: const TextStyle(
                  fontSize: 13, 
                  color: JPColors.textSecondary,
                  height: 1.4
                ),
              ),

              const SizedBox(height: 16),

              // Lista de Beneficios
              _buildBeneficios(rol, color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: seleccionado ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: seleccionado ? color : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: seleccionado
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }

  String _getDescripcion(RolSolicitable rol) {
    return rol == RolSolicitable.proveedor
        ? 'Vende tus productos, gestiona tu inventario y llega a más clientes.'
        : 'Realiza entregas en tu zona, maneja tus horarios y gana comisiones.';
  }

  Widget _buildBeneficios(RolSolicitable rol, Color color) {
    final beneficios = rol == RolSolicitable.proveedor
        ? ['📦 Catálogo propio', '📈 Estadísticas']
        : ['🚴 Horario flexible', '💵 Gana por envío', '📍 Tu zona'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: beneficios.map((beneficio) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: seleccionado ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: seleccionado 
                  ? color.withValues(alpha: 0.2) 
                  : Colors.grey.shade200,
            ),
          ),
          child: Text(
            beneficio,
            style: TextStyle(
              color: seleccionado ? color : JPColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}