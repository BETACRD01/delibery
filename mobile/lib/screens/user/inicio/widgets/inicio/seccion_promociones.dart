// lib/screens/user/inicio/widgets/seccion_promociones.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../models/promocion_model.dart';

class SeccionPromociones extends StatefulWidget {
  final List<PromocionModel> promociones;
  final Function(PromocionModel)? onPromocionPressed;
  final bool loading;

  const SeccionPromociones({
    super.key,
    required this.promociones,
    this.onPromocionPressed,
    this.loading = false,
  });

  @override
  State<SeccionPromociones> createState() => _SeccionPromocionesState();
}

class _SeccionPromocionesState extends State<SeccionPromociones> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loading && widget.promociones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Text(
                'Promociones Especiales',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: JPColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              if (widget.loading)
                const SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        SizedBox(
          height: 200,
          child: widget.loading
              ? _buildLoadingList()
              : PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.promociones.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _PromocionCardImpacto(
                        promocion: widget.promociones[index],
                        onTap: () => widget.onPromocionPressed?.call(widget.promociones[index]),
                      ),
                    );
                  },
                ),
        ),

        // Indicadores de página (dots)
        if (!widget.loading && widget.promociones.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.promociones.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? JPColors.primary
                        : JPColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (_, __) => Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

/// Tarjeta de Promoción: Diseño "Impacto Visual"
class _PromocionCardImpacto extends StatelessWidget {
  final PromocionModel promocion;
  final VoidCallback? onTap;

  const _PromocionCardImpacto({
    required this.promocion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = promocion.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 310, // Tarjeta ancha y protagonista
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24), // Bordes modernos
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 8), // Sombra inferior suave
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. FONDO INTELIGENTE (Color + Imagen)
              // Ponemos el color de fondo PRIMERO para que si la imagen es PNG transparente,
              // se vea el color bonito detrás.
              Container(color: cardColor),

              _buildBackgroundImage(),

              // 2. GRADIENTE DE LECTURA (Overlay)
              // Oscurece la parte de abajo para que el texto blanco resalte
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8), // Negro sólido abajo
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),

              // 3. CONTENIDO FLOTANTE
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- STICKER DE DESCUENTO (BADGE) ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, 
                            vertical: 8
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white, // Fondo blanco puro
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_offer_rounded, 
                                color: cardColor, 
                                size: 18
                              ),
                              const SizedBox(width: 6),
                              Text(
                                promocion.descuento.toUpperCase(),
                                style: TextStyle(
                                  color: cardColor, // Texto del color de la promo
                                  fontSize: 16, // ¡Más grande!
                                  fontWeight: FontWeight.w900, // Extra Bold
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // --- TEXTOS LLAMATIVOS ---
                    Text(
                      promocion.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Título Grande
                        fontWeight: FontWeight.w900, // Letra muy gruesa
                        height: 1.1,
                        // Sombra para leer sobre fotos claras
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      promocion.descripcion,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95), // Casi blanco
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la imagen de fondo adaptativa
  Widget _buildBackgroundImage() {
    if (promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: promocion.imagenUrl!,
        fit: BoxFit.cover, 
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackDecoration(),
      );
    } else {
      return _buildFallbackDecoration();
    }
  }

  /// Decoración por si no hay imagen (Icono gigante de fondo)
  Widget _buildFallbackDecoration() {
    return Stack(
      children: [
        Positioned(
          right: -40,
          bottom: -40,
          child: Icon(
            Icons.fastfood_rounded,
            size: 200,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}