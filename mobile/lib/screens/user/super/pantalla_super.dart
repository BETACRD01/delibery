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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<SuperController>(
            builder: (context, controller, _) {
              if (controller.categorias.isEmpty && controller.loading) {
                return const _SuperSkeleton();
              }

              if (controller.categorias.isEmpty) {
                return _buildSinCategorias();
              }

              return RefreshIndicator(
                onRefresh: controller.refrescar,
                color: Colors.teal,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JP Súper',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15212B),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Farmacia, envíos y súper en un solo lugar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7A90),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildGridCategorias(controller),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSinCategorias() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
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

  Widget _buildGridCategorias(SuperController controller) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          int crossAxisCount = 2;
          if (width > 900) {
            crossAxisCount = 4;
          } else if (width > 640) {
            crossAxisCount = 3;
          }
          const spacing = 12.0;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final categoria = controller.categorias[index];
              return _CategoriaCard(
                categoria: categoria,
                onTap: () => _onCategoriaPressed(categoria),
              );
            }, childCount: controller.categorias.length),
          );
        },
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

class _CategoriaCard extends StatelessWidget {
  final CategoriaSuperModel categoria;
  final VoidCallback? onTap;

  const _CategoriaCard({required this.categoria, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = categoria.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Container(
                height: 96,
                width: double.infinity,
                color: color.withValues(alpha: 0.08),
                child: CachedNetworkImage(
                  imageUrl: categoria.imagenUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: Icon(
                      categoria.icono,
                      color: color.withValues(alpha: 0.35),
                      size: 42,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Icon(
                      categoria.icono,
                      color: color.withValues(alpha: 0.35),
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(categoria.icono, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15212B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoria.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7A90),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.store_mall_directory,
                          size: 14,
                          color: Color(0xFF45525F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${categoria.totalProveedores ?? 0} prov.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF45525F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
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
}

class _SuperSkeleton extends StatelessWidget {
  const _SuperSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
