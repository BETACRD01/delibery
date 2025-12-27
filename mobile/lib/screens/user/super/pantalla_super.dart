// lib/screens/user/super/pantalla_super.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType, Scaffold;
import 'package:provider/provider.dart';

import '../../../../../theme/app_colors_primary.dart';
import '../../../controllers/user/super_controller.dart';
import '../../../models/categoria_super_model.dart';
import '../../../theme/jp_theme.dart';
import '../../../widgets/cards/jp_category_card.dart';
import '../../../widgets/common/carrito_floating_button.dart';
import '../../../widgets/common/jp_empty_state.dart';
import '../../../widgets/common/jp_shimmer.dart';
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
        backgroundColor: JPCupertinoColors.background(context),
        floatingActionButton: const CarritoFloatingButton(),
        body: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Consumer<SuperController>(
              builder: (context, controller, _) {
                if (controller.categorias.isEmpty && controller.loading) {
                  return const _SuperSkeleton();
                }

                if (controller.error != null) {
                  return _buildSinConexion(context, controller);
                }

                if (controller.categorias.isEmpty) {
                  return _buildSinCategorias(context);
                }

                return CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JP Súper',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: JPCupertinoColors.label(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Farmacia, envíos y súper en un solo lugar',
                              style: TextStyle(
                                fontSize: 14,
                                color: JPCupertinoColors.secondaryLabel(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildGridCategorias(controller),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinConexion(BuildContext context, SuperController controller) {
    return JPNoConnectionState(
      title: 'No se pudieron cargar los datos',
      message: 'Verifica tu conexión a internet e intenta nuevamente.',
      actionText: 'Reintentar',
      onRetry: () => controller.refrescar(),
    );
  }

  Widget _buildSinCategorias(BuildContext context) {
    return JPEmptyState(
      icon: CupertinoIcons.bag,
      iconColor: AppColorsPrimary.main,
      title: 'No hay categorías',
      message:
          'Las categorías de servicios aparecerán aquí cuando estén disponibles',
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
              return JPCategoryCard(
                nombre: categoria.nombre,
                descripcion: categoria.descripcion,
                imagenUrl: categoria.imagenUrl,
                icono: categoria.icono,
                color: categoria.color,
                totalItems: categoria.totalProveedores,
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
      CupertinoPageRoute(
        builder: (context) => PantallaCategoriaDetalle(categoria: categoria),
      ),
    );
  }
}

/// Skeleton loading con shimmer effect para categorías
class _SuperSkeleton extends StatelessWidget {
  const _SuperSkeleton();

  @override
  Widget build(BuildContext context) {
    return const JPShimmerList(
      itemCount: 6,
      itemHeight: 180,
      spacing: 12,
      borderRadius: 14,
      padding: EdgeInsets.all(16),
    );
  }
}
