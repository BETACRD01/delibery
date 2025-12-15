// lib/screens/user/inicio/widgets/inicio/home_app_bar.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../../theme/jp_theme.dart';

/// AppBar premium y responsive para Home.
/// Se controla desde PantallaHome pasando props (sin lógica interna extra).
class HomeAppBar extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final int unreadCount;
  final String title;
  final String subtitle;
  final String? logoAssetPath;
  final String? logoNetworkUrl;

  const HomeAppBar({
    super.key,
    this.onNotificationTap,
    this.onSearchTap,
    this.unreadCount = 0,
    this.title = 'JP Express',
    this.subtitle = 'Entrega rápida y confiable',
    this.logoAssetPath = 'assets/images/Beta.png',
    this.logoNetworkUrl,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 340;
    final logoSize = isCompact ? 48.0 : 56.0;
    final titleSize = isCompact ? 18.0 : 20.5;
    final subtitleSize = isCompact ? 12.0 : 13.0;
    final horizontalPad = isCompact ? 14.0 : 18.0;
    final toolbarH = isCompact ? 64.0 : 70.0;
    // Altura del buscador aún más compacta
    final bottomH = isCompact ? 46.0 : 50.0;

    return SliverAppBar(
      pinned: false,
      floating: false,
      snap: false,
      elevation: 0,
      toolbarHeight: toolbarH,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleSpacing: horizontalPad,
      centerTitle: false,
      title: Row(
        children: [
          _Logo(
            size: logoSize,
            assetPath: logoAssetPath,
            networkUrl: logoNetworkUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: JPColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: JPColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _BellButton(
          unread: unreadCount,
          onTap: onNotificationTap,
        ),
        SizedBox(width: horizontalPad - 4),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomH),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 4, horizontalPad, 6),
          child: _SearchBar(onTap: onSearchTap, compact: isCompact),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  final String? assetPath;
  final String? networkUrl;

  const _Logo({
    required this.size,
    this.assetPath,
    this.networkUrl,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(size * 0.28);
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: border,
        child: CachedNetworkImage(
          imageUrl: networkUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }

    if (assetPath != null && assetPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: border,
        child: Image.asset(
          assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: JPColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: const Icon(Icons.local_shipping_rounded, color: JPColors.primary, size: 24),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int unread;
  final VoidCallback? onTap;

  const _BellButton({required this.unread, this.onTap});

  @override
  Widget build(BuildContext context) {
    final showBadge = unread > 0;
    return badges.Badge(
      showBadge: showBadge,
      badgeAnimation: const badges.BadgeAnimation.scale(toAnimate: false),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: JPColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        elevation: 0,
      ),
      position: badges.BadgePosition.topEnd(top: -6, end: -2),
      badgeContent: Text(
        showBadge ? (unread > 9 ? '9+' : '$unread') : '',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications_none_rounded, color: JPColors.textPrimary, size: 26),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final bool compact;

  const _SearchBar({this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 12.0 : 14.0;
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: compact ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.grey.shade300, width: 0.6),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey[600], size: compact ? 18 : 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buscar productos o tiendas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, color: Colors.grey[500], size: compact ? 18 : 20),
            ],
          ),
        ),
      ),
    );
  }
}
