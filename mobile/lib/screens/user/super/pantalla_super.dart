// lib/screens/user/super/pantalla_super.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../controllers/user/super_controller.dart';
import '../../../models/categoria_super_model.dart';
import 'pantalla_categoria_detalle.dart';

/// Pantalla Super - Categorías de servicios
class PantallaSuper extends StatefulWidget {
  const PantallaSuper({super.key});

  @override
  State<PantallaSuper> createState() => _PantallaSuperState();
}

class _PantallaSuperState extends State<PantallaSuper> {
  late final SuperController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SuperController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'JP Super',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Consumer<SuperController>(
          builder: (context, controller, _) {
            if (controller.error != null) {
              return _buildError(controller.error!);
            }

            if (controller.categorias.isEmpty && controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.categorias.isEmpty) {
              return _buildSinCategorias();
            }

            return _buildListaCategorias(controller);
          },
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
          const SizedBox(height: 24),
          Text(
            'Error al cargar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _controller.refrescar(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSinCategorias() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No hay categorías',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las categorías aparecerán aquí',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCategorias(SuperController controller) {
    return RefreshIndicator(
      onRefresh: controller.refrescar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.categorias.length,
        itemBuilder: (context, index) {
          final categoria = controller.categorias[index];
          return _buildTarjetaCategoria(categoria);
        },
      ),
    );
  }

  Widget _buildTarjetaCategoria(CategoriaSuperModel categoria) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onCategoriaPressed(categoria),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la categoría
            if (categoria.imagenUrl != null && categoria.imagenUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: categoria.imagenUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
                        color: categoria.color.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            categoria.icono,
                            size: 60,
                            color: categoria.color.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: categoria.color.withValues(alpha: 0.1),
                        child: Icon(
                          categoria.icono,
                          size: 60,
                          color: categoria.color.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Badge NUEVO
                    if (categoria.destacado)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NUEVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              // Fallback sin imagen
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: categoria.color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(
                    categoria.icono,
                    size: 80,
                    color: categoria.color.withValues(alpha: 0.5),
                  ),
                ),
              ),

            // Contenido de la tarjeta
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoria.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoria.icono,
                      color: categoria.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoria.descripcion,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoriaPressed(CategoriaSuperModel categoria) {
    _controller.seleccionarCategoria(categoria);

    // Navegar a la pantalla de detalle de la categoría
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaCategoriaDetalle(categoria: categoria),
      ),
    );
  }
}
