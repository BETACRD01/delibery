import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('pt'),
  ];

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // Idioma
      'languageTitle': 'Idioma',
      'languageSubtitle': 'Selecciona tu idioma preferido',
      'languageChanged': 'Idioma cambiado a ',
      'selectOnMap': 'Selecciona en el mapa',
      // Configuración
      'settings': 'Configuración',
      'account': 'Cuenta',
      'myAddresses': 'Mis Direcciones',
      'notifications': 'Notificaciones',
      'language': 'Idioma',
      'helpSupport': 'Ayuda y Soporte',
      'termsConditions': 'Términos y Condiciones',
      // General
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'accept': 'Aceptar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Agregar',
      'search': 'Buscar',
      'home': 'Inicio',
      'profile': 'Perfil',
    },
    'en': {
      // Language
      'languageTitle': 'Language',
      'languageSubtitle': 'Select your preferred language',
      'languageChanged': 'Language changed to ',
      'selectOnMap': 'Select on the map',
      // Settings
      'settings': 'Settings',
      'account': 'Account',
      'myAddresses': 'My Addresses',
      'notifications': 'Notifications',
      'language': 'Language',
      'helpSupport': 'Help & Support',
      'termsConditions': 'Terms & Conditions',
      // General
      'save': 'Save',
      'cancel': 'Cancel',
      'accept': 'Accept',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'home': 'Home',
      'profile': 'Profile',
    },
    'pt': {
      // Idioma
      'languageTitle': 'Idioma',
      'languageSubtitle': 'Selecione seu idioma preferido',
      'languageChanged': 'Idioma alterado para ',
      'selectOnMap': 'Selecione no mapa',
      // Configurações
      'settings': 'Configurações',
      'account': 'Conta',
      'myAddresses': 'Meus Endereços',
      'notifications': 'Notificações',
      'language': 'Idioma',
      'helpSupport': 'Ajuda e Suporte',
      'termsConditions': 'Termos e Condições',
      // Geral
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'accept': 'Aceitar',
      'delete': 'Excluir',
      'edit': 'Editar',
      'add': 'Adicionar',
      'search': 'Buscar',
      'home': 'Início',
      'profile': 'Perfil',
    },
  };

  String _text(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['es']![key]!;

  // Idioma
  String get languageTitle => _text('languageTitle');
  String get languageSubtitle => _text('languageSubtitle');
  String languageChanged(String code) => '${_text('languageChanged')}$code';
  String get selectOnMap => _text('selectOnMap');

  // Configuración
  String get settings => _text('settings');
  String get account => _text('account');
  String get myAddresses => _text('myAddresses');
  String get notifications => _text('notifications');
  String get language => _text('language');
  String get helpSupport => _text('helpSupport');
  String get termsConditions => _text('termsConditions');

  // General
  String get save => _text('save');
  String get cancel => _text('cancel');
  String get accept => _text('accept');
  String get delete => _text('delete');
  String get edit => _text('edit');
  String get add => _text('add');
  String get search => _text('search');
  String get home => _text('home');
  String get profile => _text('profile');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
