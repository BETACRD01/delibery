import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PantallaVerComprobanteUsuario extends StatelessWidget {
  final String comprobanteUrl;

  const PantallaVerComprobanteUsuario({
    super.key,
    required this.comprobanteUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Comprobante'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: Image.network(
            comprobanteUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CupertinoActivityIndicator(radius: 14),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'No se pudo cargar el comprobante',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
