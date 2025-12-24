// lib/screens/user/catalogo/pantalla_todas_categorias.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Material, MaterialType, Curves, KeyedSubtree;
import '../../../../../config/rutas.dart';
import '../../../../../services/productos/productos_service.dart';
import '../../../../../theme/app_colors_primary.dart';
import '../../../../../theme/app_colors_support.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../models/categoria_model.dart';
import '../../../widgets/common/jp_shimmer.dart';

/// Pantalla que muestra todas las categorías en formato grid iOS-style
class PantallaTodasCategorias extends StatefulWidget {
  const PantallaTodasCategorias({super.key});

  @override
  State<PantallaTodasCategorias> createState() =>
      _PantallaTodasCategoriasState();
}

class _PantallaTodasCategoriasState extends State<PantallaTodasCategorias> {
  final _productosService = ProductosService();

  List<CategoriaModel> _categorias = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      _categorias = await _productosService.obtenerCategorias();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar categorías: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      child: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // AppBar iOS
            CupertinoSliverNavigationBar(
              backgroundColor: JPCupertinoColors.surface(context),
              largeTitle: Text(
                'Categorías',
                style: TextStyle(color: AppColorsSupport.textPrimary),
              ),
              border: Border(
                bottom: BorderSide(
                  color: JPCupertinoColors.separator(context),
                  width: 0.5,
                ),
              ),
            ),

            // Refresh Control iOS
            CupertinoSliverRefreshControl(onRefresh: _cargarCategorias),

            // Contenido
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Usar AnimatedSwitcher para transiciones suaves
    return SliverToBoxAdapter(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildBodyContent(),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_loading) {
      return KeyedSubtree(
        key: const ValueKey('loading'),
        child: _buildShimmerGrid(),
      );
    }

    if (_error.isNotEmpty) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: _buildEstadoError(),
      );
    }

    if (_categorias.isEmpty) {
      return KeyedSubtree(
        key: const ValueKey('empty'),
        child: _buildSinResultados(),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('content'),
      child: _buildGridContent(),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => _ShimmerCategoryCard(),
      ),
    );
  }

  Widget _buildGridContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categorias.length,
        itemBuilder: (context, index) =>
            _CategoriaCard(categoria: _categorias[index]),
      ),
    );
  }

  Widget _buildEstadoError() {
    return Center(
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
              _error,
              style: TextStyle(
                color: JPCupertinoColors.secondaryLabel(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _cargarCategorias,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search_circle,
            size: 64,
            color: JPCupertinoColors.systemGrey3(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron categorías',
            style: TextStyle(
              color: JPCupertinoColors.secondaryLabel(context),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CARD DE CATEGORÍA iOS-STYLE
// ══════════════════════════════════════════════════════════════════════════

class _CategoriaCard extends StatelessWidget {
  final CategoriaModel categoria;

  const _CategoriaCard({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        onPressed: () => Rutas.irACategoriaDetalle(context, categoria),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Círculo con imagen
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: JPCupertinoColors.separator(context),
                  width: 0.5,
                ),
              ),
              child: ClipOval(
                child: categoria.tieneImagen
                    ? CachedNetworkImage(
                        imageUrl: categoria.imagenUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CupertinoActivityIndicator(
                            radius: 10,
                            color: JPCupertinoColors.systemGrey(context),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          CupertinoIcons.photo,
                          size: 32,
                          color: JPCupertinoColors.systemGrey3(context),
                        ),
                      )
                    : Icon(
                        CupertinoIcons.square_grid_2x2,
                        size: 32,
                        color: JPCupertinoColors.systemGrey3(context),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Nombre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                categoria.nombre,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColorsSupport.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Total productos
            if (categoria.totalProductos != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColorsPrimary.main.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${categoria.totalProductos} productos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColorsPrimary.main,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHIMMER CARD - Placeholder de carga para categoría
// ══════════════════════════════════════════════════════════════════════════════

class _ShimmerCategoryCard extends StatelessWidget {
  const _ShimmerCategoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: JPConstants.cardShadow(context),
      ),
      child: JPShimmer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Círculo placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Nombre placeholder
            Container(
              width: 80,
              height: 16,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Badge placeholder
            Container(
              width: 60,
              height: 22,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
