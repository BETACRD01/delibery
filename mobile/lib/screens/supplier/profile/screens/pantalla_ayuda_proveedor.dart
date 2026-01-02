// lib/screens/supplier/screens/pantalla_ayuda_proveedor.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/primary_colors.dart';

/// Pantalla de ayuda y soporte del proveedor - Estilo iOS nativo
class PantallaAyudaProveedor extends StatelessWidget {
  const PantallaAyudaProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Ayuda y Soporte'),
        backgroundColor: CupertinoColors.systemBackground
            .resolveFrom(context)
            .withValues(alpha: 0.9),
        border: null,
      ),
      child: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.label,
            decoration: TextDecoration.none,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header de ayuda
              _buildHeaderAyuda(context),
              const SizedBox(height: 24),

              // Contacto rápido
              _buildSectionHeader(context, 'CONTACTO RÁPIDO'),
              _buildContactoCard(context),
              const SizedBox(height: 24),

              // Preguntas frecuentes
              _buildSectionHeader(context, 'PREGUNTAS FRECUENTES'),
              _buildFAQCard(context),
              const SizedBox(height: 24),

              // Guías
              _buildSectionHeader(context, 'GUÍAS Y TUTORIALES'),
              _buildGuiasCard(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAyuda(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsPrimary.main,
            AppColorsPrimary.main.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿En qué podemos ayudarte?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estamos aquí para resolver tus dudas',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey.resolveFrom(context),
          letterSpacing: -0.08,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  Widget _buildContactoCard(BuildContext context) {
    return _buildSettingsCard(context, [
      _buildContactTile(
        context,
        icon: CupertinoIcons.chat_bubble_text_fill,
        iconBgColor: CupertinoColors.activeGreen,
        title: 'Chat en vivo',
        subtitle: 'Respuesta inmediata',
        onTap: () => _abrirChat(context),
      ),
      _buildDivider(context),
      _buildContactTile(
        context,
        icon: CupertinoIcons.mail_solid,
        iconBgColor: const Color(0xFF007AFF),
        title: 'Correo electrónico',
        subtitle: 'soporte@jpexpress.com',
        onTap: () => _enviarCorreo(),
      ),
      _buildDivider(context),
      _buildContactTile(
        context,
        icon: CupertinoIcons.phone_fill,
        iconBgColor: const Color(0xFFFF9500),
        title: 'Teléfono',
        subtitle: '+593 99 123 4567',
        onTap: () => _llamar(),
      ),
      _buildDivider(context),
      _buildContactTile(
        context,
        icon: CupertinoIcons.bubble_left_bubble_right_fill,
        iconBgColor: const Color(0xFF25D366),
        title: 'WhatsApp',
        subtitle: 'Escríbenos directamente',
        onTap: () => _abrirWhatsApp(),
      ),
    ]);
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: CupertinoColors.systemGrey3.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context) {
    final faqs = [
      _FAQ(
        pregunta: '¿Cómo agrego un nuevo producto?',
        respuesta:
            'Ve a la sección de Productos, luego presiona el botón "+" y completa la información del producto.',
      ),
      _FAQ(
        pregunta: '¿Cómo verifico mi cuenta?',
        respuesta:
            'Completa tu perfil con toda la información requerida incluyendo RUC y documentos.',
      ),
      _FAQ(
        pregunta: '¿Cómo gestiono los pedidos?',
        respuesta:
            'En la sección de Pedidos puedes ver, aceptar o rechazar pedidos pendientes.',
      ),
      _FAQ(
        pregunta: '¿Cómo modifico mis horarios?',
        respuesta:
            'Accede a \"Mi Perfil\" y edita los horarios de apertura y cierre.',
      ),
      _FAQ(
        pregunta: '¿Cuánto es la comisión por venta?',
        respuesta:
            'La comisión varía según tu plan. Contacta a soporte para más detalles.',
      ),
    ];

    return _buildSettingsCard(
      context,
      faqs.asMap().entries.map((entry) {
        final faq = entry.value;
        final isLast = entry.key == faqs.length - 1;
        return Column(
          children: [
            _FAQItem(faq: faq),
            if (!isLast) _buildDivider(context),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGuiasCard(BuildContext context) {
    final guias = [
      _Guia(
        icono: CupertinoIcons.play_circle_fill,
        titulo: 'Primeros pasos',
        subtitulo: 'Aprende a usar la plataforma',
      ),
      _Guia(
        icono: CupertinoIcons.cube_box_fill,
        titulo: 'Gestión de productos',
        subtitulo: 'Cómo administrar tu catálogo',
      ),
      _Guia(
        icono: CupertinoIcons.doc_text_fill,
        titulo: 'Procesamiento de pedidos',
        subtitulo: 'Flujo completo de pedidos',
      ),
      _Guia(
        icono: CupertinoIcons.graph_square_fill,
        titulo: 'Entendiendo tus estadísticas',
        subtitulo: 'Analiza el rendimiento',
      ),
    ];

    return _buildSettingsCard(
      context,
      guias.asMap().entries.map((entry) {
        final guia = entry.value;
        final isLast = entry.key == guias.length - 1;
        return Column(
          children: [
            _buildGuideTile(context, guia),
            if (!isLast) _buildDivider(context),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGuideTile(BuildContext context, _Guia guia) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        // TODO: Abrir guía
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColorsPrimary.main,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(guia.icono, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guia.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    guia.subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: CupertinoColors.systemGrey3.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo chat de soporte...')),
    );
  }

  void _enviarCorreo() async {
    final uri = Uri.parse(
      'mailto:soporte@jpexpress.com?subject=Soporte Proveedor',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _llamar() async {
    final uri = Uri.parse('tel:+593991234567');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _abrirWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/593991234567?text=Hola, necesito ayuda con mi cuenta de proveedor',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FAQ {
  final String pregunta;
  final String respuesta;

  _FAQ({required this.pregunta, required this.respuesta});
}

class _FAQItem extends StatefulWidget {
  final _FAQ faq;

  const _FAQItem({required this.faq});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => setState(() => _expandido = !_expandido),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.pregunta,
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _expandido
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                  size: 16,
                ),
              ],
            ),
            if (_expandido) ...[
              const SizedBox(height: 10),
              Text(
                widget.faq.respuesta,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  height: 1.4,
                ),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Guia {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  _Guia({required this.icono, required this.titulo, required this.subtitulo});
}
