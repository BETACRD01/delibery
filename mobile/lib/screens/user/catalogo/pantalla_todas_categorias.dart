// lib/screens/user/catalogo/pantalla_todas_categorias.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../config/rutas.dart';
import '../../../../../services/productos_service.dart';
import '../../../models/categoria_model.dart';

/// Pantalla que muestra todas las categorías en formato grid
class PantallaTodasCategorias extends StatefulWidget {
  const PantallaTodasCategorias({super.key});

  @override
  State<PantallaTodasCategorias> createState() => _PantallaTodasCategoriasState();
}

class _PantallaTodasCategoriasState extends State<PantallaTodasCategorias> {
  final _productosService = ProductosService();
  
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

  Future<void> _cargarCategorias() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // Llamada real al backend
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Todas las Categorías'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar categoría...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _busqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _aplicarBusqueda(''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _aplicarBusqueda,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: JPColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarCategorias,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_categoriasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron categorías',
              style: TextStyle(color: JPColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarCategorias,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categoriasFiltradas.length,
        itemBuilder: (context, index) {
          return _CategoriaCard(categoria: _categoriasFiltradas[index]);
        },
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final CategoriaModel categoria;

  const _CategoriaCard({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Rutas.irACategoriaDetalle(context, categoria),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Círculo con imagen
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipOval(
                child: categoria.tieneImagen
                    ? Image.network(
                        categoria.imagenUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported_outlined,
                        size: 32,
                        color: Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Nombre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                categoria.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: JPColors.textPrimary,
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
                  color: JPColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${categoria.totalProductos} productos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JPColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
