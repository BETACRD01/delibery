// lib/screens/auth/pantalla_registro.dart

import 'package:flutter/cupertino.dart';

import '../../theme/app_colors_primary.dart';
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: JPCupertinoColors.surface(
          context,
        ).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, color: AppColorsPrimary.main, size: 28),
              const SizedBox(width: 4),
              Text(
                'Atrás',
                style: TextStyle(color: AppColorsPrimary.main, fontSize: 17),
              ),
            ],
          ),
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 17,
          color: JPCupertinoColors.label(context),
          fontFamily: '.SF Pro Text',
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),

                      const RegistroUsuarioForm(),

                      const SizedBox(height: 28),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 90,
          width: 90,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorsPrimary.main.withValues(alpha: 0.12),
                AppColorsPrimary.main.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            'assets/icon/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              CupertinoIcons.person_add,
              size: 44,
              color: AppColorsPrimary.main,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: JPCupertinoColors.label(context),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Completa tus datos para unirte a JP Express',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: JPCupertinoColors.secondaryLabel(context),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(
            color: JPCupertinoColors.secondaryLabel(context),
            fontSize: 15,
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Iniciar Sesión',
            style: TextStyle(
              color: AppColorsPrimary.main,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
