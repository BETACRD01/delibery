import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  static const _prefsKey = 'locale';

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {
      // Preferimos silencioso; si falla se usará el locale por defecto
    }
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, languageCode);
    } catch (_) {
      // Si no se puede persistir, no bloqueamos el cambio en memoria
    }
  }
}
