import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cache/cache_helper.dart';
import '../cache/cache_keys.dart';

/*
|--------------------------------------------------------------------------
| LocaleCubit
|--------------------------------------------------------------------------
|
| Holds the current app Locale, persisted via CacheHelper under the
| existing CacheKeys.appLang key (same key DioHelper already reads for
| the Accept-Language header, so switching language here also changes
| what the API sees). Created once at app root — see main.dart.
|--------------------------------------------------------------------------
*/

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(_loadInitial());

  static Locale _loadInitial() {
    final saved = CacheHelper.getDataFromSharedPreference(key: CacheKeys.appLang);
    if (saved is String && (saved == 'en' || saved == 'ar')) {
      return Locale(saved);
    }
    return const Locale('en');
  }

  Future<void> changeLocale(Locale locale) async {
    if (locale.languageCode == state.languageCode) return;
    await CacheHelper.saveDataSharedPreference(
      key: CacheKeys.appLang,
      value: locale.languageCode,
    );
    emit(locale);
  }

  Future<void> toggle() =>
      changeLocale(state.languageCode == 'en' ? const Locale('ar') : const Locale('en'));
}
