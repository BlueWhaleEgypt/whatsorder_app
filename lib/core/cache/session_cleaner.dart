import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/cache/profile_name.dart';

/*
|--------------------------------------------------------------------------
| SessionCleaner
|--------------------------------------------------------------------------
|
| Single place that removes the signed-in user's local session. Only
| session data is cleared; language and other app-wide settings are kept.
|
|--------------------------------------------------------------------------
*/

abstract class SessionCleaner {
  Future<void> clear();
}

class LocalSessionCleaner implements SessionCleaner {
  const LocalSessionCleaner();

  @override
  Future<void> clear() async {
    await CacheHelper.removeData(key: CacheKeys.userModel);
    await CacheHelper.removeData(key: CacheKeys.accessToken);
    await CacheHelper.removeData(key: CacheKeys.refreshToken);
    ProfileName.clear();
  }
}
