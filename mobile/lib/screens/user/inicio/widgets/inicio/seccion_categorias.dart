// lib/screens/user/inicio/widgets/seccion_categorias.dart

import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors_primary.dart';
import 'package:mobile/theme/app_colors_support.dart';

import '../../../../../models/categoria_model.dart';

/// Sección de categorías en la pantalla Home
class SeccionCategorias extends StatelessWidget {
  final List<CategoriaModel> categorias;
  final Function(CategoriaModel)? onCategoriaPressed;
  final VoidCallback? onVerTodo;
  final bool loading;

  const SeccionCategorias({
    super.key,
    required this.categorias,
    this.onCategoriaPressed,
    this.onVerTodo,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        if (loading)
          _buildLoadingState()
        else if (categorias.isEmpty)
          _buildEmptyState()
        else
          _buildCategoriasList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsSupport.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (onVerTodo != null)
            GestureDetector(
              onTap: onVerTodo,
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  color: AppColorsPrimary.main,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriasList() {
    // Solo mostramos las primeras 5 para no saturar la home; el resto va en "Ver todo"
    final visibles = categorias.length > 5
        ? categorias.take(5).toList()
        : categorias;

    return SizedBox(
      height: 110, // Increased slightly for spacing
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visibles.length,
        itemBuilder: (context, index) {
          return _CategoriaItem(
            categoria: visibles[index],
            onTap: () => onCategoriaPressed?.call(visibles[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          'No hay categorías disponibles',
          style: TextStyle(color: AppColorsSupport.textSecondary),
        ),
      ),
    );
  }
}

/// Widget individual de categoría (Inteligente: Foto o Icono)
class _CategoriaItem extends StatelessWidget {
  final CategoriaModel categoria;
  final VoidCallback? onTap;

  const _CategoriaItem({required this.categoria, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                // Si tiene foto fondo blanco, si no fondo suave del color
                color: categoria.tieneImagen
                    ? Colors.white
                    : (categoria.color ?? AppColorsPrimary.main).withValues(
                        alpha: 0.1,
                      ),
                borderRadius: BorderRadius.circular(20), // iOS squaricle-ish
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildContenidoVisual(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                categoria.nombre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColorsSupport.textSecondary,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decide qué mostrar basado en lo que mandó Django
  Widget _buildContenidoVisual() {
    // 1. Si Django mandó una URL de imagen, la mostramos
    if (categoria.tieneImagen && categoria.imagenUrl != null) {
      return Image.network(
        categoria.imagenUrl!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: categoria.color ?? AppColorsPrimary.main,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        // Si la imagen falla (404), mostramos el icono como respaldo
        errorBuilder: (_, _, _) => _buildIcono(),
      );
    }

    // 2. Si no hay imagen, mostramos el icono que definimos por defecto
    return _buildIcono();
  }

  Widget _buildIcono() {
    return Center(
      child: Icon(
        // Si no hay icono definido, usa uno genérico
        categoria.icono ?? Icons.category_outlined,
        color: categoria.color ?? AppColorsPrimary.main,
        size: 30,
      ),
    );
  }
}
