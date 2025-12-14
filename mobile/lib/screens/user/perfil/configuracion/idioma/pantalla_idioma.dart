import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../providers/locale_provider.dart';
import '../../../../../l10n/app_localizations.dart';

/// 🌍 PANTALLA DE SELECCIÓN DE IDIOMA
/// Diseño: Clean UI con selección simple
class PantallaIdioma extends StatefulWidget {
  const PantallaIdioma({super.key});

  @override
  State<PantallaIdioma> createState() => _PantallaIdiomaState();
}

class _PantallaIdiomaState extends State<PantallaIdioma> {
  late LocaleProvider _localeProvider;
  String _idiomaSeleccionado = 'es';

  final List<Map<String, String>> _idiomas = [
    {'code': 'es', 'label': 'Español', 'flag': '🇪🇸'},
    {'code': 'en', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'pt', 'label': 'Português', 'flag': '🇧🇷'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localeProvider = Provider.of<LocaleProvider>(context);
    final actual = _localeProvider.locale?.languageCode;
    if (actual != null && actual != _idiomaSeleccionado) {
      _idiomaSeleccionado = actual;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background, // Fondo Gris Claro
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).languageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: JPColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).languageSubtitle,
              style: const TextStyle(
                color: JPColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de idiomas
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _idiomas.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _idiomaSeleccionado == item['code'];
                  final isLast = index == _idiomas.length - 1;

                  return Column(
                    children: [
                      _buildLanguageItem(
                        label: item['label']!,
                        flag: item['flag']!,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _idiomaSeleccionado = item['code']!);
                          _guardarIdioma(item['code']!);
                        },
                      ),
                      if (!isLast)
                        Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem({
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? JPColors.textPrimary : JPColors.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: JPColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  void _guardarIdioma(String codigo) {
    _localeProvider.setLocale(codigo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).languageChanged(codigo)),
        backgroundColor: JPColors.primary,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
