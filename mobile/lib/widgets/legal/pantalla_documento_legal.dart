import 'package:flutter/cupertino.dart';
import '../../models/entities/documento_legal_model.dart';
import '../../services/legal/legal_service.dart';
import '../../theme/primary_colors.dart';
import '../../theme/jp_theme.dart';

/// Pantalla para mostrar documentos legales estilo iPhone
class PantallaDocumentoLegal extends StatefulWidget {
  final TipoDocumento tipo;

  const PantallaDocumentoLegal({
    super.key,
    required this.tipo,
  });

  @override
  State<PantallaDocumentoLegal> createState() => _PantallaDocumentoLegalState();
}

enum TipoDocumento { terminos, privacidad }

class _PantallaDocumentoLegalState extends State<PantallaDocumentoLegal> {
  final _legalService = LegalService();
  DocumentoLegalModel? _documento;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDocumento();
  }

  Future<void> _cargarDocumento() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final documento = widget.tipo == TipoDocumento.terminos
          ? await _legalService.obtenerTerminos()
          : await _legalService.obtenerPrivacidad();

      if (mounted) {
        setState(() {
          _documento = documento;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 15,
        color: JPCupertinoColors.label(context),
        fontFamily: '.SF Pro Text',
      ),
      child: CupertinoPageScaffold(
        backgroundColor: JPCupertinoColors.background(context),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: JPCupertinoColors.surface(context).withValues(alpha: 0.95),
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
                Icon(
                  CupertinoIcons.back,
                  color: AppColorsPrimary.main,
                  size: 28,
                ),
                const SizedBox(width: 4),
                Text(
                  'Atrás',
                  style: TextStyle(
                    color: AppColorsPrimary.main,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          middle: Text(
            widget.tipo == TipoDocumento.terminos
                ? 'Términos y Condiciones'
                : 'Política de Privacidad',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return DefaultTextStyle(
        style: TextStyle(
          fontSize: 15,
          color: JPCupertinoColors.secondaryLabel(context),
          fontFamily: '.SF Pro Text',
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CupertinoActivityIndicator(
                radius: 16,
                color: AppColorsPrimary.main,
              ),
              const SizedBox(height: 16),
              const Text('Cargando documento...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return DefaultTextStyle(
        style: TextStyle(
          fontSize: 15,
          color: JPCupertinoColors.label(context),
          fontFamily: '.SF Pro Text',
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 64,
                  color: JPCupertinoColors.systemRed(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: JPCupertinoColors.label(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No se pudo cargar el documento. Verifica tu conexión.',
                  style: TextStyle(
                    fontSize: 15,
                    color: JPCupertinoColors.secondaryLabel(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: _cargarDocumento,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_documento == null) {
      return const Center(child: Text('No hay documento disponible'));
    }

    return Column(
      children: [
        // Header con información del documento
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColorsPrimary.main.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(
                color: JPCupertinoColors.separator(context),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsPrimary.main.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Versión ${_documento!.version}',
                      style: TextStyle(
                        color: AppColorsPrimary.main,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Última actualización: ${_formatearFecha(_documento!.fechaModificacion)}',
                      style: TextStyle(
                        color: JPCupertinoColors.secondaryLabel(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Contenido del documento
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text(
              _limpiarHtml(_documento!.contenido),
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: JPCupertinoColors.label(context),
                fontFamily: '.SF Pro Text',
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  /// Limpia el HTML y lo convierte a texto plano legible y profesional
  String _limpiarHtml(String html) {
    // Eliminar etiquetas de script, style y divs
    String texto = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<div[^>]*>', dotAll: true), '')
        .replaceAll('</div>', '');

    // Convertir encabezados H1 con formato elegante
    texto = texto.replaceAllMapped(
      RegExp(r'<h1[^>]*>(.*?)</h1>', dotAll: true),
      (match) => '\n\n${match.group(1)?.toUpperCase()}\n${'─' * 40}\n',
    );

    // Convertir encabezados H2 con viñeta profesional
    texto = texto.replaceAllMapped(
      RegExp(r'<h2[^>]*>(.*?)</h2>', dotAll: true),
      (match) => '\n\n📋 ${match.group(1)}\n',
    );

    // Convertir encabezados H3
    texto = texto.replaceAllMapped(
      RegExp(r'<h3[^>]*>(.*?)</h3>', dotAll: true),
      (match) => '\n  ▪ ${match.group(1)}\n',
    );

    // Convertir párrafos con espaciado adecuado
    texto = texto.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true),
      (match) => '\n${match.group(1)?.trim()}\n',
    );

    // Convertir items de lista con viñetas bonitas
    texto = texto.replaceAllMapped(
      RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true),
      (match) => '\n  • ${match.group(1)?.trim()}',
    );

    // Eliminar tags de lista
    texto = texto.replaceAll(RegExp(r'</?ul[^>]*>'), '');
    texto = texto.replaceAll(RegExp(r'</?ol[^>]*>'), '');

    // Mantener negritas con formato (usando texto sin modificar)
    texto = texto.replaceAllMapped(
      RegExp(r'<strong[^>]*>(.*?)</strong>', dotAll: true),
      (match) => '${match.group(1)}',
    );
    texto = texto.replaceAllMapped(
      RegExp(r'<b[^>]*>(.*?)</b>', dotAll: true),
      (match) => '${match.group(1)}',
    );

    // Convertir saltos de línea
    texto = texto
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n');

    // Eliminar todas las etiquetas HTML restantes
    texto = texto.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decodificar entidades HTML comunes
    texto = texto
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&aacute;', 'á')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&iacute;', 'í')
        .replaceAll('&oacute;', 'ó')
        .replaceAll('&uacute;', 'ú')
        .replaceAll('&ntilde;', 'ñ')
        .replaceAll('&Aacute;', 'Á')
        .replaceAll('&Eacute;', 'É')
        .replaceAll('&Iacute;', 'Í')
        .replaceAll('&Oacute;', 'Ó')
        .replaceAll('&Uacute;', 'Ú')
        .replaceAll('&Ntilde;', 'Ñ')
        .replaceAll('&iquest;', '¿')
        .replaceAll('&iexcl;', '¡');

    // Limpiar espacios múltiples
    texto = texto.replaceAll(RegExp(r'  +'), ' ');

    // Limpiar múltiples saltos de línea (máximo 2)
    texto = texto.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

    // Limpiar espacios al inicio y final de cada línea
    texto = texto.split('\n').map((line) => line.trim()).join('\n');

    return texto.trim();
  }
}
