import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 📄 PANTALLA DE TÉRMINOS Y CONDICIONES
/// Diseño: Documento Legal Clean UI - Modo Oscuro Compatible
class PantallaTerminos extends StatelessWidget {
  const PantallaTerminos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        foregroundColor: CupertinoColors.label.resolveFrom(context),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: CupertinoColors.separator.resolveFrom(context),
            height: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: CupertinoColors.label.resolveFrom(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del documento
            Text(
              'Última actualización: 20 Noviembre 2024',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // ─── CONTENIDO LEGAL ───
            _buildSection(
              context,
              '1. Introducción',
              'Bienvenido a JP Express. Al acceder o utilizar nuestra aplicación móvil, sitio web y servicios, aceptas estar legalmente vinculado por estos Términos y Condiciones. Si no estás de acuerdo con alguna parte de estos términos, no podrás utilizar nuestros servicios.',
            ),

            _buildSection(
              context,
              '2. Definiciones',
              '• "Usuario": Persona que utiliza la plataforma para solicitar servicios.\n'
                  '• "Proveedor": Usuario registrado para vender productos.\n'
                  '• "Repartidor": Usuario registrado para realizar entregas.\n'
                  '• "Servicio": La intermediación tecnológica provista por JP Express.',
            ),

            _buildSection(
              context,
              '3. Uso de la Cuenta',
              'Eres responsable de mantener la confidencialidad de tu cuenta y contraseña. Aceptas notificar inmediatamente cualquier uso no autorizado de tu cuenta. JP Express se reserva el derecho de cerrar cuentas, eliminar o editar contenido a su exclusiva discreción.',
            ),

            _buildSection(
              context,
              '4. Pedidos y Pagos',
              'Todos los pedidos están sujetos a disponibilidad. Los precios mostrados incluyen los impuestos aplicables según la ley. El pago se procesará a través de los métodos disponibles en la aplicación al momento de confirmar la orden.',
            ),

            _buildSection(
              context,
              '5. Política de Cancelación',
              'Los usuarios pueden cancelar un pedido antes de que el restaurante o proveedor haya confirmado su preparación. Una vez confirmado, la cancelación podría estar sujeta a un cargo total o parcial.',
            ),

            _buildSection(
              context,
              '6. Propiedad Intelectual',
              'Todo el contenido incluido en o disponible a través de JP Express, como texto, gráficos, logotipos, iconos de botones e imágenes, es propiedad de JP Express o de sus proveedores de contenido.',
            ),

            _buildSection(
              context,
              '7. Limitación de Responsabilidad',
              'JP Express no será responsable por daños indirectos, incidentales, especiales, consecuentes o punitivos, incluyendo sin limitación, pérdida de beneficios, datos, uso, fondo de comercio, u otras pérdidas intangibles.',
            ),

            const SizedBox(height: 20),
            Divider(color: CupertinoColors.separator.resolveFrom(context)),
            const SizedBox(height: 20),

            // Pie de página
            Center(
              child: Text(
                'JP Express S.A.\nQuito, Ecuador',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper para secciones de texto
  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              height: 1.6, // Altura de línea para mejor lectura
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
