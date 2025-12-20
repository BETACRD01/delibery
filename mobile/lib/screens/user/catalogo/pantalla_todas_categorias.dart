// lib/screens/user/catalogo/pantalla_todas_categorias.dart

import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../config/rutas.dart';
import '../../../../../services/productos_service.dart';
import '../../../models/categoria_model.dart';

/// Pantalla que muestra todas las categorías en formato grid iOS-style
class PantallaTodasCategorias extends StatefulWidget {
  const PantallaTodasCategorias({super.key});

  @override
  State<PantallaTodasCategorias> createState() => _PantallaTodasCategoriasState();
}

class _PantallaTodasCategoriasState extends State<PantallaTodasCategorias> {
  final _productosService = ProductosService();
  final _searchController = TextEditingController();

  List<CategoriaModel> _categorias = [];
  List<CategoriaModel> _categoriasFiltradas = [];
  bool _loading = true;
  String _error = '';
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      _categorias = await _productosService.obtenerCategorias();
      _categoriasFiltradas = List.from(_categorias);

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

  void _aplicarBusqueda(String query) {
    setState(() {
      _busqueda = query;
      if (query.isEmpty) {
        _categoriasFiltradas = List.from(_categorias);
      } else {
        _categoriasFiltradas = _categorias.where((categoria) {
          return categoria.nombre.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _limpiarBusqueda() {
    _searchController.clear();
    _aplicarBusqueda('');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // AppBar iOS
          CupertinoSliverNavigationBar(
            backgroundColor: JPCupertinoColors.surface(context),
            largeTitle: const Text('Categorías'),
            border: Border(
              bottom: BorderSide(
                color: JPCupertinoColors.separator(context),
                width: 0.5,
              ),
            ),
          ),

          // Refresh Control iOS
          CupertinoSliverRefreshControl(
            onRefresh: _cargarCategorias,
          ),

          // Barra de búsqueda pegajosa
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              child: Container(
                color: JPCupertinoColors.background(context),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: CupertinoTextField(
                  controller: _searchController,
                  placeholder: 'Buscar categoría...',
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Icon(
                      CupertinoIcons.search,
                      size: 20,
                      color: JPCupertinoColors.systemGrey(context),
                    ),
                  ),
                  suffix: _busqueda.isNotEmpty
                      ? CupertinoButton(
                          padding: const EdgeInsets.only(right: 8),
                          minimumSize: Size.zero,
                          onPressed: _limpiarBusqueda,
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            size: 20,
                            color: JPCupertinoColors.systemGrey(context),
                          ),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: JPCupertinoColors.systemGrey6(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onChanged: _aplicarBusqueda,
                ),
              ),
            ),
          ),

          // Contenido
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return SliverFillRemaining(
        child: Center(
          child: CupertinoActivityIndicator(
            radius: 14,
            color: JPCupertinoColors.systemGrey(context),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return SliverFillRemaining(
        child: _buildEstadoError(),
      );
    }

    if (_categoriasFiltradas.isEmpty) {
      return SliverFillRemaining(
        child: _buildSinResultados(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _CategoriaCard(categoria: _categoriasFiltradas[index]);
          },
          childCount: _categoriasFiltradas.length,
        ),
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
// PERSISTENT HEADER DELEGATE PARA SEARCH BAR
// ══════════════════════════════════════════════════════════════════════════

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
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
                  color: JPCupertinoColors.label(context),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${categoria.totalProductos} productos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JPCupertinoColors.systemBlue(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
