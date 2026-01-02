// lib/widgets/contact/boton_contacto_whatsapp.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/jp_theme.dart' hide JPSnackbar;
import '../common/jp_snackbar.dart';

/// Widget reutilizable para contactar vía WhatsApp
class BotonContactoWhatsApp extends StatelessWidget {
  final String telefono;
  final String? mensaje;
  final String? nombreContacto;
  final bool mostrarNombre;
  final IconData? icono;
  final Color? color;
  final bool esBotonCompleto;
  final String? textoBoton;

  const BotonContactoWhatsApp({
    super.key,
    required this.telefono,
    this.mensaje,
    this.nombreContacto,
    this.mostrarNombre = true,
    this.icono,
    this.color,
    this.esBotonCompleto = false,
    this.textoBoton,
  });

  Future<void> _abrirWhatsApp(BuildContext context) async {
    // Limpiar el número de teléfono (quitar espacios, guiones, etc.)
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');

    // Agregar código de país si no tiene
    String numeroFinal = telefonoLimpio;
    if (!numeroFinal.startsWith('+')) {
      // Asumimos Ecuador (+593) si no tiene código de país
      if (numeroFinal.startsWith('0')) {
        numeroFinal = '+593${numeroFinal.substring(1)}';
      } else {
        numeroFinal = '+593$numeroFinal';
      }
    }

    // Construir URL de WhatsApp
    final mensajeEncoded = mensaje != null ? Uri.encodeComponent(mensaje!) : '';

    final url =
        'https://wa.me/$numeroFinal${mensajeEncoded.isNotEmpty ? '?text=$mensajeEncoded' : ''}';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          JPSnackbar.error(
            context,
            'No se puede abrir WhatsApp. Verifica que esté instalado.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        JPSnackbar.error(context, 'Error al abrir WhatsApp: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (esBotonCompleto) {
      return _buildBotonCompleto(context);
    }
    return _buildBotonIcono(context);
  }

  Widget _buildBotonCompleto(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _abrirWhatsApp(context),
      icon: Icon(icono ?? FontAwesomeIcons.whatsapp, color: Colors.white),
      label: Text(
        textoBoton ?? 'Contactar por WhatsApp',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF25D366), // Color de WhatsApp
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBotonIcono(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrirWhatsApp(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono ?? FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 20,
                ),
                if (mostrarNombre && nombreContacto != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    nombreContacto!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar opciones de contacto (WhatsApp + Llamada)
class OpcionesContacto extends StatelessWidget {
  final String telefono;
  final String? nombreContacto;
  final String? mensajeWhatsApp;

  const OpcionesContacto({
    super.key,
    required this.telefono,
    this.nombreContacto,
    this.mensajeWhatsApp,
  });

  Future<void> _realizarLlamada(BuildContext context) async {
    // Limpiar el número de teléfono
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');

    final url = 'tel:$telefonoLimpio';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          JPSnackbar.error(context, 'No se puede realizar la llamada');
        }
      }
    } catch (e) {
      if (context.mounted) {
        JPSnackbar.error(context, 'Error al realizar llamada: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JPColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.contact_phone,
                    color: JPColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (nombreContacto != null) ...[
                        Text(
                          nombreContacto!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: JPColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        telefono,
                        style: const TextStyle(
                          fontSize: 14,
                          color: JPColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _realizarLlamada(context),
                    icon: const Icon(FontAwesomeIcons.phone, size: 18),
                    label: const Text('Llamar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JPColors.primary,
                      side: const BorderSide(color: JPColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BotonContactoWhatsApp(
                    telefono: telefono,
                    mensaje: mensajeWhatsApp,
                    esBotonCompleto: true,
                    textoBoton: 'WhatsApp',
                    icono: FontAwesomeIcons.whatsapp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
