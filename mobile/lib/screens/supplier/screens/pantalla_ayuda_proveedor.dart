// lib/screens/supplier/screens/pantalla_ayuda_proveedor.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de ayuda y soporte del proveedor
class PantallaAyudaProveedor extends StatelessWidget {
  const PantallaAyudaProveedor({super.key});

  static const Color _primario = Color(0xFF1E88E5);
  static const Color _exito = Color(0xFF10B981);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ayuda y Soporte', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _primario,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header de ayuda
          _buildHeaderAyuda(),
          const SizedBox(height: 24),

          // Contacto rápido
          _buildSeccion('Contacto rápido'),
          const SizedBox(height: 10),
          _buildContactoCard(context),
          const SizedBox(height: 24),

          // Preguntas frecuentes
          _buildSeccion('Preguntas frecuentes'),
          const SizedBox(height: 10),
          _buildFAQCard(),
          const SizedBox(height: 24),

          // Guías
          _buildSeccion('Guías y tutoriales'),
          const SizedBox(height: 10),
          _buildGuiasCard(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderAyuda() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primario,_primario.withValues(alpha: 0.8),],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, color: Colors.white, size: 48),
          const SizedBox(height: 12),
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
           style: TextStyle(color: Colors.white.withValues(alpha: 0.9),fontSize: 14,),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo) {
    return Text(
      titulo.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _textoSecundario,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildContactoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildContactoItem(
            icono: Icons.chat_outlined,
            titulo: 'Chat en vivo',
            subtitulo: 'Respuesta inmediata',
            color: _exito,
            onTap: () => _abrirChat(context),
          ),
          const Divider(height: 1),
          _buildContactoItem(
            icono: Icons.email_outlined,
            titulo: 'Correo electrónico',
            subtitulo: 'soporte@jpexpress.com',
            color: _primario,
            onTap: () => _enviarCorreo(),
          ),
          const Divider(height: 1),
          _buildContactoItem(
            icono: Icons.phone_outlined,
            titulo: 'Teléfono',
            subtitulo: '+593 99 123 4567',
            color: Colors.orange,
            onTap: () => _llamar(),
          ),
          const Divider(height: 1),
          _buildContactoItem(
            icono: Icons.message_outlined,
            titulo: 'WhatsApp',
            subtitulo: 'Escríbenos directamente',
            color: const Color(0xFF25D366),
            onTap: () => _abrirWhatsApp(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactoItem({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: const TextStyle(fontSize: 12, color: _textoSecundario)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard() {
    final faqs = [
      _FAQ(
        pregunta: '¿Cómo agrego un nuevo producto?',
        respuesta: 'Ve a la sección de Productos en el menú lateral, luego presiona el botón "Agregar" '
            'y completa la información del producto incluyendo nombre, precio, descripción e imagen.',
      ),
      _FAQ(
        pregunta: '¿Cómo verifico mi cuenta?',
        respuesta: 'Para verificar tu cuenta, debes completar tu perfil con toda la información '
            'requerida incluyendo RUC y documentos. Un administrador revisará tu solicitud.',
      ),
      _FAQ(
        pregunta: '¿Cómo gestiono los pedidos?',
        respuesta: 'En la sección de Pedidos puedes ver todos los pedidos pendientes. '
            'Puedes aceptar o rechazar pedidos y marcarlos como listos cuando estén preparados.',
      ),
      _FAQ(
        pregunta: '¿Cómo modifico mis horarios de atención?',
        respuesta: 'Accede a "Mi Perfil" desde el menú lateral. Ahí podrás editar '
            'los horarios de apertura y cierre de tu negocio.',
      ),
      _FAQ(
        pregunta: '¿Cuánto es la comisión por venta?',
        respuesta: 'La comisión varía según el tipo de proveedor y el plan contratado. '
            'Puedes ver los detalles en la sección de Configuración o contactando a soporte.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: faqs.asMap().entries.map((entry) {
          final faq = entry.value;
          final isLast = entry.key == faqs.length - 1;
          return Column(
            children: [
              _FAQItem(faq: faq),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGuiasCard(BuildContext context) {
    final guias = [
      _Guia(
        icono: Icons.play_circle_outline,
        titulo: 'Primeros pasos',
        subtitulo: 'Aprende a usar la plataforma',
      ),
      _Guia(
        icono: Icons.inventory_2_outlined,
        titulo: 'Gestión de productos',
        subtitulo: 'Cómo administrar tu catálogo',
      ),
      _Guia(
        icono: Icons.receipt_long_outlined,
        titulo: 'Procesamiento de pedidos',
        subtitulo: 'Flujo completo de pedidos',
      ),
      _Guia(
        icono: Icons.bar_chart_outlined,
        titulo: 'Entendiendo tus estadísticas',
        subtitulo: 'Analiza el rendimiento de tu negocio',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: guias.asMap().entries.map((entry) {
          final guia = entry.value;
          final isLast = entry.key == guias.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  // TODO: Abrir guía
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Abriendo: ${guia.titulo}')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                         color: _primario.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(guia.icono, color: _primario, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(guia.titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(guia.subtitulo, style: const TextStyle(fontSize: 12, color: _textoSecundario)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _abrirChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo chat de soporte...')),
    );
    // TODO: Implementar chat
  }

  void _enviarCorreo() async {
    final uri = Uri.parse('mailto:soporte@jpexpress.com?subject=Soporte Proveedor');
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
    final uri = Uri.parse('https://wa.me/593991234567?text=Hola, necesito ayuda con mi cuenta de proveedor');
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
    return InkWell(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.pregunta,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(
                  _expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            if (_expandido) ...[
              const SizedBox(height: 10),
              Text(
                widget.faq.respuesta,
                style: const TextStyle(fontSize: 13, color:  Color(0xFF6B7280), height: 1.4),
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