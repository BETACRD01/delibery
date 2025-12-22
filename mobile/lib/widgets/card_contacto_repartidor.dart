// lib/widgets/card_contacto_repartidor.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/jp_theme.dart';
import 'boton_contacto_whatsapp.dart';

/// Card para mostrar información del repartidor y opciones de contacto
class CardContactoRepartidor extends StatelessWidget {
  final String nombreRepartidor;
  final String? telefonoRepartidor;
  final String? numeroPedido;
  final bool mostrarTitulo;

  const CardContactoRepartidor({
    super.key,
    required this.nombreRepartidor,
    this.telefonoRepartidor,
    this.numeroPedido,
    this.mostrarTitulo = true,
  });

  String _generarMensajeWhatsApp() {
    if (numeroPedido != null) {
      return 'Hola, soy el cliente del pedido #$numeroPedido. ';
    }
    return 'Hola, necesito información sobre mi pedido. ';
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay teléfono, no mostrar el card de contacto
    if (telefonoRepartidor == null || telefonoRepartidor!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mostrarTitulo) ...[
          const Text(
            'Contactar al repartidor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        OpcionesContacto(
          telefono: telefonoRepartidor!,
          nombreContacto: nombreRepartidor,
          mensajeWhatsApp: _generarMensajeWhatsApp(),
        ),
      ],
    );
  }
}

/// Widget simplificado para mostrar solo el botón de WhatsApp
class BotonWhatsAppRepartidor extends StatelessWidget {
  final String? telefonoRepartidor;
  final String? numeroPedido;

  const BotonWhatsAppRepartidor({
    super.key,
    this.telefonoRepartidor,
    this.numeroPedido,
  });

  String _generarMensajeWhatsApp() {
    if (numeroPedido != null) {
      return 'Hola, soy el cliente del pedido #$numeroPedido. ';
    }
    return 'Hola, necesito información sobre mi pedido. ';
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay teléfono, no mostrar nada
    if (telefonoRepartidor == null || telefonoRepartidor!.isEmpty) {
      return const SizedBox.shrink();
    }

    return BotonContactoWhatsApp(
      telefono: telefonoRepartidor!,
      mensaje: _generarMensajeWhatsApp(),
      esBotonCompleto: true,
      textoBoton: 'Contactar repartidor',
      icono: FontAwesomeIcons.whatsapp,
    );
  }
}

/// Widget para mostrar en un FloatingActionButton
class FABContactoRepartidor extends StatelessWidget {
  final String? telefonoRepartidor;
  final String? numeroPedido;

  const FABContactoRepartidor({
    super.key,
    this.telefonoRepartidor,
    this.numeroPedido,
  });

  String _generarMensajeWhatsApp() {
    if (numeroPedido != null) {
      return 'Hola, soy el cliente del pedido #$numeroPedido. ';
    }
    return 'Hola, necesito información sobre mi pedido. ';
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay teléfono, no mostrar nada
    if (telefonoRepartidor == null || telefonoRepartidor!.isEmpty) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: const Color(0xFF25D366), // Color de WhatsApp
      icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
      label: BotonContactoWhatsApp(
        telefono: telefonoRepartidor!,
        mensaje: _generarMensajeWhatsApp(),
        esBotonCompleto: true,
        textoBoton: 'Contactar',
        icono: FontAwesomeIcons.whatsapp,
      ),
    );
  }
}
