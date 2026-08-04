import 'package:shared_preferences/shared_preferences.dart';

/*
|--------------------------------------------------------------------------
| CacheHelper
|--------------------------------------------------------------------------
|
| Thin wrapper around SharedPreferences. Must call CacheHelper.init()
| once at app startup (usually right after sl<SharedPreferences>()
| is registered) so `sharedPreferences` is ready everywhere.
|
|--------------------------------------------------------------------------
*/

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> reload() async {
    await sharedPreferences.reload();
  }

  static Future<bool> saveDataSharedPreference({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) return sharedPreferences.setString(key, value);
    if (value is int) return sharedPreferences.setInt(key, value);
    if (value is bool) return sharedPreferences.setBool(key, value);
    if (value is double) return sharedPreferences.setDouble(key, value);
    return sharedPreferences.setString(key, value.toString());
  }

  static dynamic getDataFromSharedPreference({required String key}) {
    return sharedPreferences.get(key);
  }

  static Future<bool> removeData({required String key}) async {
    return sharedPreferences.remove(key);
  }

  static Future<bool> clearAll() async {
    return sharedPreferences.clear();
  }
}
