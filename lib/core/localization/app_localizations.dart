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

  /// Turns a message coming from a Bloc/repository into text safe to show.
  ///
  /// * a known translation key is translated;
  /// * technical text (exceptions, "Error 500", raw maps, ...) is replaced by
  ///   the generic `something_went_wrong` message;
  /// * anything else is treated as a server-provided message and shown as is.
  String message(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return translate('something_went_wrong');

    final en = kTranslations['en']!;
    if (en.containsKey(text)) return translate(text);

    if (_looksTechnical(text)) return translate('something_went_wrong');
    return text;
  }

  static final _technical = RegExp(
    r'exception|^error\b|failure\(|instance of|stack ?trace|is not a subtype|'
    r'null check|^\{|^\[|status code|socket|timeout|dioexception',
    caseSensitive: false,
  );

  static bool _looksTechnical(String text) => _technical.hasMatch(text);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Ergonomic shortcut: `context.tr('welcome_back')`.
extension TranslateContext on BuildContext {
  String tr(String key, [Map<String, String>? args]) =>
      AppLocalizations.of(this).translate(key, args);

  /// Localizes a Bloc/repository message. See [AppLocalizations.message].
  String trMessage(String? raw) => AppLocalizations.of(this).message(raw);
}
