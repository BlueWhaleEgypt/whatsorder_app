import 'package:flutter/material.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/utils/logger.dart';

class NotificationCounter {
  NotificationCounter._();

  static const String _notificationKey = 'notification_count';
  static const String _smsKey = 'sms_count';

  static final ValueNotifier<int> notificationCount = ValueNotifier(0);
  static final ValueNotifier<int> smsCount = ValueNotifier(0);
  static Future<void> incrementNotificationFromBackground() async {
    final current =
        CacheHelper.getDataFromSharedPreference(key: _notificationKey) ?? 0;

    await CacheHelper.saveDataSharedPreference(
      key: _notificationKey,
      value: current + 1,
    );
  }

  static Future<void> incrementSmsFromBackground() async {
    final current = CacheHelper.getDataFromSharedPreference(key: _smsKey) ?? 0;

    await CacheHelper.saveDataSharedPreference(
      key: _smsKey,
      value: current + 1,
    );
  }

  static Future<void> loadFromCache() async {
    await CacheHelper.reload();

    notificationCount.value =
        CacheHelper.getDataFromSharedPreference(key: _notificationKey) ?? 0;

    smsCount.value = CacheHelper.getDataFromSharedPreference(key: _smsKey) ?? 0;
  }

  static void incrementNotification() {
    final value = notificationCount.value + 1;
    logger.i("SAVE COUNT = ${notificationCount.value}");

    CacheHelper.saveDataSharedPreference(key: _notificationKey, value: value);

    notificationCount.value = value;
  }

  static void incrementSms() {
    final value = smsCount.value + 1;

    CacheHelper.saveDataSharedPreference(key: _smsKey, value: value);

    smsCount.value = value;
  }

  static void resetNotification() {
    CacheHelper.saveDataSharedPreference(key: _notificationKey, value: 0);

    notificationCount.value = 0;
  }

  static void resetSms() {
    CacheHelper.saveDataSharedPreference(key: _smsKey, value: 0);

    smsCount.value = 0;
  }
}
