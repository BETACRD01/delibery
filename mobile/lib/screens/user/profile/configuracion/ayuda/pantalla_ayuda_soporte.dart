// lib/screens/user/perfil/ayuda/pantalla_ayuda_soporte.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

import '../../../../../theme/primary_colors.dart';

class PantallaAyudaSoporte extends StatefulWidget {
  const PantallaAyudaSoporte({super.key});

  @override
  State<PantallaAyudaSoporte> createState() => _PantallaAyudaSoporteState();
}

class _PantallaAyudaSoporteState extends State<PantallaAyudaSoporte>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _enviando = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildCanalesContacto(),
                  const SizedBox(height: 28),
                  _buildFAQSection(),
                  const SizedBox(height: 28),
                  _buildFormularioContacto(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Ayuda y Soporte',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: CupertinoColors.label.resolveFrom(context),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground
                  .resolveFrom(context)
                  .withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: CupertinoColors.label.resolveFrom(context),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColorsPrimary.main.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_rounded,
              size: 40,
              color: AppColorsPrimary.main,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '¿Cómo podemos ayudarte?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: CupertinoColors.label.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Estamos aquí para resolver tus dudas',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCanalesContacto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'CANALES DE ATENCIÓN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildContactCard(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                color: CupertinoColors.systemGreen.resolveFrom(context),
                onTap: () => _simularAccion('Abriendo WhatsApp...'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactCard(
                icon: Icons.phone_outlined,
                label: 'Llamar',
                color: AppColorsPrimary.main,
                onTap: () => _simularAccion('Llamando a soporte...'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactCard(
                icon: Icons.email_outlined,
                label: 'Email',
                color: AppColorsPrimary.secondary,
                onTap: () => _simularAccion('Abriendo correo...'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PREGUNTAS FRECUENTES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFAQItem(
                '¿Cómo rastreo mi pedido?',
                'Puedes rastrear tu pedido en tiempo real desde la sección "Mis Pedidos" en el menú inferior.',
                isFirst: true,
              ),
              _buildDivider(),
              _buildFAQItem(
                '¿Cuáles son los métodos de pago?',
                'Aceptamos tarjetas de crédito/débito, PayPal y pago contra entrega en efectivo.',
              ),
              _buildDivider(),
              _buildFAQItem(
                'Quiero ser proveedor',
                'Dirígete a tu perfil y selecciona la opción "¿Quieres ganar dinero extra?" para aplicar.',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(
    String question,
    String answer, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: CupertinoColors.systemGrey5.resolveFrom(context),
        highlightColor: CupertinoColors.systemGrey5.resolveFrom(context),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
            letterSpacing: -0.3,
          ),
        ),
        iconColor: AppColorsPrimary.main,
        collapsedIconColor: CupertinoColors.secondaryLabel.resolveFrom(context),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  Widget _buildFormularioContacto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ENVÍANOS UN MENSAJE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildIOSTextField(
                    controller: _asuntoController,
                    label: 'ASUNTO',
                    placeholder: 'Ej: Problema con un pedido',
                  ),
                  const SizedBox(height: 16),
                  _buildIOSTextField(
                    controller: _mensajeController,
                    label: 'MENSAJE',
                    placeholder: 'Describe tu problema detalladamente...',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIOSTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.label.resolveFrom(context),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: CupertinoColors.tertiarySystemGroupedBackground
                .resolveFrom(context),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorsPrimary.main, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CupertinoColors.systemRed.resolveFrom(context),
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CupertinoColors.systemRed.resolveFrom(context),
                width: 2,
              ),
            ),
            errorStyle: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemRed.resolveFrom(context),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Campo obligatorio';
            if (value.length < 5) return 'Demasiado corto';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _enviando
            ? []
            : [
                BoxShadow(
                  color: AppColorsPrimary.main.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _enviando ? null : _enviarMensaje,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsPrimary.main,
            disabledBackgroundColor: CupertinoColors.systemGrey4.resolveFrom(
              context,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _enviando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CupertinoActivityIndicator(radius: 14),
                )
              : const Text(
                  'Enviar Mensaje',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }

  void _simularAccion(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColorsPrimary.main,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    FocusScope.of(context).unfocus();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _enviando = false;
        _asuntoController.clear();
        _mensajeController.clear();
      });

      await showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: CupertinoColors.systemGreen.resolveFrom(context),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Mensaje Enviado'),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Hemos recibido tu mensaje. Te contactaremos pronto.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: AppColorsPrimary.main,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
