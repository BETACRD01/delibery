import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/core/theme_provider.dart';
import '../../../../theme/primary_colors.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final int solicitudesPendientesCount;
  final VoidCallback onRefresh;
  final VoidCallback onSolicitudesTap;

  const DashboardAppBar({
    super.key,
    required this.tabController,
    required this.solicitudesPendientesCount,
    required this.onRefresh,
    required this.onSolicitudesTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFF2F2F7);
    final primaryColor = AppColorsPrimary.main;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Text(
        'Panel de Admin',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        _buildNotificationButton(context, isDark),
        IconButton(
          icon: Icon(CupertinoIcons.refresh, color: primaryColor),
          onPressed: onRefresh,
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'Resumen'),
              Tab(text: 'Actividad'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            CupertinoIcons.bell,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            if (solicitudesPendientesCount > 0) {
              onSolicitudesTap();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No hay notificaciones pendientes'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        if (solicitudesPendientesCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$solicitudesPendientesCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
