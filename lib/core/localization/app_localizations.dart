import 'package:flutter/material.dart';
import 'app_translations.dart';

/*
|--------------------------------------------------------------------------
| AppLocalizations
|--------------------------------------------------------------------------
|
| Looks up `kTranslations[locale][key]`, falling back to English then to
| the key itself if something's missing (so a forgotten translation
| shows up as visible mismatched text instead of crashing).
|--------------------------------------------------------------------------
*/

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const delegate = _AppLocalizationsDelegate();

  String translate(String key, [Map<String, String>? args]) {
    final table = kTranslations[locale.languageCode] ?? kTranslations['en']!;
    var value = table[key] ?? kTranslations['en']![key] ?? key;

    if (args != null) {
      args.forEach((argKey, argValue) {
        value = value.replaceAll('{$argKey}', argValue);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Ergonomic shortcut: `context.tr('welcome_back')`.
extension TranslateContext on BuildContext {
  String tr(String key, [Map<String, String>? args]) =>
      AppLocalizations.of(this).translate(key, args);
}
