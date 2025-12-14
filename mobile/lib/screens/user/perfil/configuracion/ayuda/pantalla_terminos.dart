import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';

/// 📄 PANTALLA DE TÉRMINOS Y CONDICIONES
/// Diseño: Documento Legal Clean UI
class PantallaTerminos extends StatelessWidget {
  const PantallaTerminos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Términos y Condiciones',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del documento
            const Text(
              'Última actualización: 20 Noviembre 2024',
              style: TextStyle(
                color: JPColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // ─── CONTENIDO LEGAL ───
            
            _buildSection(
              '1. Introducción',
              'Bienvenido a JP Express. Al acceder o utilizar nuestra aplicación móvil, sitio web y servicios, aceptas estar legalmente vinculado por estos Términos y Condiciones. Si no estás de acuerdo con alguna parte de estos términos, no podrás utilizar nuestros servicios.',
            ),

            _buildSection(
              '2. Definiciones',
              '• "Usuario": Persona que utiliza la plataforma para solicitar servicios.\n'
              '• "Proveedor": Usuario registrado para vender productos.\n'
              '• "Repartidor": Usuario registrado para realizar entregas.\n'
              '• "Servicio": La intermediación tecnológica provista por JP Express.',
            ),

            _buildSection(
              '3. Uso de la Cuenta',
              'Eres responsable de mantener la confidencialidad de tu cuenta y contraseña. Aceptas notificar inmediatamente cualquier uso no autorizado de tu cuenta. JP Express se reserva el derecho de cerrar cuentas, eliminar o editar contenido a su exclusiva discreción.',
            ),

            _buildSection(
              '4. Pedidos y Pagos',
              'Todos los pedidos están sujetos a disponibilidad. Los precios mostrados incluyen los impuestos aplicables según la ley. El pago se procesará a través de los métodos disponibles en la aplicación al momento de confirmar la orden.',
            ),

            _buildSection(
              '5. Política de Cancelación',
              'Los usuarios pueden cancelar un pedido antes de que el restaurante o proveedor haya confirmado su preparación. Una vez confirmado, la cancelación podría estar sujeta a un cargo total o parcial.',
            ),

            _buildSection(
              '6. Propiedad Intelectual',
              'Todo el contenido incluido en o disponible a través de JP Express, como texto, gráficos, logotipos, iconos de botones e imágenes, es propiedad de JP Express o de sus proveedores de contenido.',
            ),

            _buildSection(
              '7. Limitación de Responsabilidad',
              'JP Express no será responsable por daños indirectos, incidentales, especiales, consecuentes o punitivos, incluyendo sin limitación, pérdida de beneficios, datos, uso, fondo de comercio, u otras pérdidas intangibles.',
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Pie de página
            Center(
              child: Text(
                'JP Express S.A.\nQuito, Ecuador',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: JPColors.textSecondary.withValues(alpha: 0.6),
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
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: JPColors.textSecondary,
              height: 1.6, // Altura de línea para mejor lectura
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}