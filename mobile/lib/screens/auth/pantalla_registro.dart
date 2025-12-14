// lib/screens/auth/pantalla_registro.dart

import 'package:flutter/material.dart';
import '../../theme/jp_theme.dart';
import './registro/registro_usuario_form.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animación de entrada suave para dar sensación premium
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // Desplazamiento sutil desde abajo
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    
                    // Formulario directo (Sin selectores de rol)
                    const RegistroUsuarioForm(),
                    
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: JPColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Volver',
      ),
    );
  }

  // ==================== HEADER (LOGO Y TÍTULO) ====================
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            // Sombra sutil idéntica al Login
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icon/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.person_add_alt_1_outlined,
              size: 40,
              color: JPColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Crear una cuenta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: JPColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Completa tus datos para unirte a JP Express',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: JPColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(color: JPColors.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Iniciar sesión',
            style: TextStyle(
              color: JPColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}