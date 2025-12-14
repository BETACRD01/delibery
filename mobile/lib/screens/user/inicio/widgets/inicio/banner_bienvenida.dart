// lib/screens/user/inicio/widgets/banner_bienvenida.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart'; 

class BannerBienvenida extends StatelessWidget {
  final String nombreUsuario;
  final VoidCallback? onVerMenu; // Lo mantenemos por si acaso, pero no lo usamos visualmente si no quieres

  const BannerBienvenida({
    super.key,
    this.nombreUsuario = 'Usuario',
    this.onVerMenu,
  });

  @override
  Widget build(BuildContext context) {
    // 🧠 LÓGICA DE NOMBRE Y SALUDO
    String primerNombre = 'Usuario';
    if (nombreUsuario.trim().isNotEmpty) {
      final partes = nombreUsuario.trim().split(' ');
      if (partes.isNotEmpty) primerNombre = partes.first;
    }

    // Saludo según la hora
    final hora = DateTime.now().hour;
    String saludoDia;
    IconData iconoSaludo;
    
    if (hora < 12) {
      saludoDia = 'Buenos días';
      iconoSaludo = Icons.wb_sunny_rounded;
    } else if (hora < 18) {
      saludoDia = 'Buenas tardes';
      iconoSaludo = Icons.wb_twilight_rounded;
    } else {
      saludoDia = 'Buenas noches';
      iconoSaludo = Icons.nights_stay_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity, // Ocupar todo el ancho
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Bordes modernos
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              JPColors.primary,
              JPColors.primary.withValues(alpha: 0.85), 
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: JPColors.primary.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 🎨 DECORACIÓN DE FONDO (Sutil y elegante)
              Positioned(
                right: -20,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                right: 10,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    Icons.fastfood_rounded, // Icono temático de comida
                    size: 110,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // 📝 CONTENIDO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila del Saludo (Icono + Texto)
                    Row(
                      children: [
                        Icon(iconoSaludo, color: Colors.white.withValues(alpha: 0.9), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$saludoDia,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Nombre del Usuario
                    Text(
                      primerNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28, // Más grande para compensar la falta de avatar
                        fontWeight: FontWeight.w900, // Extra Bold
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Frase motivadora
                    Text(
                      '¿Qué se te antoja hoy?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}