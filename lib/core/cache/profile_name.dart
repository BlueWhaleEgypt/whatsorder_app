import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';

/*
|--------------------------------------------------------------------------
| ProfileName
|--------------------------------------------------------------------------
|
| Single source for the vendor's display name outside the Profile screen.
| Every successful vendor fetch calls [update], which persists the name to
| the cache (keeping the cached user model consistent) and notifies
| listeners, so the Home and Settings screens rebuild without an extra
| API request.
|
|--------------------------------------------------------------------------
*/

class ProfileName {
  ProfileName._();

  static final ValueNotifier<String> fullName = ValueNotifier<String>(
    _readCached(),
  );

  /// First name only, for greetings. Updated together with [fullName].
  static final ValueNotifier<String> firstName = ValueNotifier<String>(
    _readFirstCached(),
  );

  static String _readFirstCached() =>
      (CacheHelper.getDataFromSharedPreference(key: CacheKeys.firstName) ?? '')
          .toString()
          .trim();

  static String _readCached() {
    String read(String key) =>
        (CacheHelper.getDataFromSharedPreference(key: key) ?? '')
            .toString()
            .trim();

    return _join(read(CacheKeys.firstName), read(CacheKeys.lastName));
  }

  static String _join(String first, String last) =>
      [first, last].where((e) => e.isNotEmpty).join(' ');

  static Future<void> update({String? firstName, String? lastName}) async {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();

    await CacheHelper.saveDataSharedPreference(
      key: CacheKeys.firstName,
      value: first,
    );
    await CacheHelper.saveDataSharedPreference(
      key: CacheKeys.lastName,
      value: last,
    );

    // Keep the cached user model in sync so it never holds a stale name.
    try {
      final raw = CacheHelper.getDataFromSharedPreference(
        key: CacheKeys.userModel,
      );
      if (raw is String && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map['firstName'] = first;
        map['lastName'] = last;
        await CacheHelper.saveDataSharedPreference(
          key: CacheKeys.userModel,
          value: jsonEncode(map),
        );
      }
    } catch (_) {}

    ProfileName.firstName.value = first;
    fullName.value = _join(first, last);
  }

  /// Clears the name (used on logout).
  static void clear() {
    CacheHelper.removeData(key: CacheKeys.firstName);
    CacheHelper.removeData(key: CacheKeys.lastName);
    ProfileName.firstName.value = '';
    fullName.value = '';
  }
}
