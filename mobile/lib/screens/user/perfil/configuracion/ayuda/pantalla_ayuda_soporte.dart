// lib/screens/user/perfil/ayuda/pantalla_ayuda_soporte.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';

/// 🎧 PANTALLA DE AYUDA Y SOPORTE
/// Diseño: Clean UI / Minimalista
class PantallaAyudaSoporte extends StatefulWidget {
  const PantallaAyudaSoporte({super.key});

  @override
  State<PantallaAyudaSoporte> createState() => _PantallaAyudaSoporteState();
}

class _PantallaAyudaSoporteState extends State<PantallaAyudaSoporte> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Canales de Atención'),
            const SizedBox(height: 16),
            _buildCanalesContacto(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Preguntas Frecuentes'),
            const SizedBox(height: 16),
            _buildFAQSection(),

            const SizedBox(height: 32),
            _buildSectionTitle('Envíanos un mensaje'),
            const SizedBox(height: 16),
            _buildFormularioContacto(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🧩 WIDGETS ESTRUCTURALES
  // ══════════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Ayuda y Soporte',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: Colors.white,
      foregroundColor: JPColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[100], height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: JPColors.info.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, size: 48, color: JPColors.info),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Cómo podemos ayudarte?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Nuestro equipo está disponible para resolver tus dudas.',
            style: TextStyle(fontSize: 14, color: JPColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: JPColors.textPrimary,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 📞 CANALES DE CONTACTO
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildCanalesContacto() {
    return Row(
      children: [
        Expanded(
          child: _buildContactCard(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            color: JPColors.success,
            onTap: () => _simularAccion('Abriendo WhatsApp...'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildContactCard(
            icon: Icons.phone_outlined,
            label: 'Llamar',
            color: JPColors.info,
            onTap: () => _simularAccion('Llamando a soporte...'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildContactCard(
            icon: Icons.email_outlined,
            label: 'Email',
            color: JPColors.secondary,
            onTap: () => _simularAccion('Abriendo correo...'),
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ❓ FAQ SECTION (PREGUNTAS FRECUENTES)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildFAQSection() {
    return Column(
      children: [
        _buildExpansionTile(
          '¿Cómo rastreo mi pedido?',
          'Puedes rastrear tu pedido en tiempo real desde la sección "Mis Pedidos" en el menú inferior.',
        ),
        const SizedBox(height: 12),
        _buildExpansionTile(
          '¿Cuáles son los métodos de pago?',
          'Aceptamos tarjetas de crédito/débito, PayPal y pago contra entrega en efectivo.',
        ),
        const SizedBox(height: 12),
        _buildExpansionTile(
          'Quiero ser proveedor',
          'Dirígete a tu perfil y selecciona la opción "¿Quieres ganar dinero extra?" para aplicar.',
        ),
      ],
    );
  }

  Widget _buildExpansionTile(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: JPColors.textPrimary,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: JPColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 📝 FORMULARIO DE CONTACTO
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildFormularioContacto() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInput(
            controller: _asuntoController,
            label: 'Asunto',
            hint: 'Ej: Problema con un pedido',
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: _mensajeController,
            label: 'Mensaje',
            hint: 'Describe tu problema detalladamente...',
            icon: Icons.message_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviarMensaje,
              style: ElevatedButton.styleFrom(
                backgroundColor: JPColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'ENVIAR MENSAJE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1 ? Icon(icon, color: JPColors.textSecondary, size: 20) : null,
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        labelStyle: const TextStyle(color: JPColors.textSecondary),
        hintStyle: const TextStyle(color: JPColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: JPColors.primary),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        if (value.length < 5) return 'Muy corto';
        return null;
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ⚙️ LÓGICA
  // ══════════════════════════════════════════════════════════════════════════════

  void _simularAccion(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: JPColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    FocusScope.of(context).unfocus();

    // Simulación de envío API
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _enviando = false;
        _asuntoController.clear();
        _mensajeController.clear();
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: JPColors.success),
              SizedBox(width: 12),
              Text('Mensaje Enviado'),
            ],
          ),
          content: const Text('Hemos recibido tu mensaje. Te contactaremos pronto.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }
}