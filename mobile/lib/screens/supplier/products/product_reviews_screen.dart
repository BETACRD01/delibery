import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile/models/products/producto_model.dart';
import 'package:mobile/services/productos/productos_service.dart';

class ProductReviewsScreen extends StatefulWidget {
  final String productoId;
  final String productoNombre;

  const ProductReviewsScreen({
    super.key,
    required this.productoId,
    required this.productoNombre,
  });

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final ProductosService _service = ProductosService();
  late Future<List<ResenaPreview>> _futureReviews;

  @override
  void initState() {
    super.initState();
    _futureReviews = _service.obtenerRatingsProductoProveedor(
      widget.productoId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      appBar: AppBar(
        title: Text('Reseñas de ${widget.productoNombre}'),
        centerTitle: true,
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        surfaceTintColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      body: FutureBuilder<List<ResenaPreview>>(
        future: _futureReviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                'No hay reseñas aún.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReviewCard(review: review);
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ResenaPreview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: review.usuarioFoto != null
                    ? Colors.transparent
                    : Colors.grey.shade200,
                backgroundImage: review.usuarioFoto != null
                    ? NetworkImage(review.usuarioFoto!)
                    : null,
                child: review.usuarioFoto == null
                    ? Text(
                        review.usuario.isNotEmpty
                            ? review.usuario[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.usuario,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                review
                    .fecha, // Assuming already formatted string or will formatting later
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.estrellas
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          if (review.comentario != null && review.comentario!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comentario!, style: const TextStyle(height: 1.4)),
          ],
        ],
      ),
    );
  }
}
