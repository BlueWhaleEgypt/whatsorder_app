import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'core/cache/cache_helper.dart';
import 'core/network/dio_helper.dart';
import 'core/routing/app_router.dart';
import 'core/routing/named_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/navigation_helper.dart';
import 'injection/injection_container.dart' as di;
import 'firebase_options.dart';

/*
|--------------------------------------------------------------------------
| App entry point
|--------------------------------------------------------------------------
|
| Order of init matters:
|   1. CacheHelper (SharedPreferences) — DioHelper's interceptor AND
|      LocaleCubit both read from it.
|   2. DioHelper — sets up Dio + the 401 interceptor.
|   3. DI container (GetIt) — registers Blocs/services, including
|      LocaleCubit.
|
| MaterialApp is wrapped in a BlocProvider<LocaleCubit> at the root so
| any screen can switch language (see TopBarPills) and the whole app —
| including automatic RTL for Arabic — rebuilds via `locale: state`.
|--------------------------------------------------------------------------
*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // سجل الـ Background Handler هنا
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await getFirebaseToken();
  await CacheHelper.init();
  NotificationCounter.loadFromCache();
  DioHelper.init();
  await di.init();
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    logger.i('New FCM Token: $newToken');
    // Send the new token to your backend
  });

  runApp(const MyApp());
  // // بعد ما الـ app اتبنى، دور على الـ initial message
  // final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  // if (initialMessage != null) {
  //   final orderId = initialMessage.data['order_id'];
  //   logger.w('order id is $orderId');

  //   // استنى فريم واحد كمان عشان تتأكد إن الـ Navigator جاهز
  //   WidgetsBinding.instance.addPostFrameCallback((context) {
  //     //Navigator.pushNamed(context, NamedRoutes.notification);
  //   });
  // }
}

Future<void> getFirebaseToken() async {
  final messaging = FirebaseMessaging.instance;

  // Required on iOS and Android 13+
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  final token = await messaging.getToken();

  print('FCM Token: $token');
  logger.w('FCM Token: $token');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    logger.w(
      'notification count is ${CacheHelper.getDataFromSharedPreference(key: 'notification_count')}',
    );
    logger.w(
      'sms count is ${CacheHelper.getDataFromSharedPreference(key: 'sms_count')}',
    );
    return BlocProvider<LocaleCubit>(
      create: (_) => di.sl<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            title: "What's Order",
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.lightTheme,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: NamedRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await CacheHelper.init();

  logger.i("========== BACKGROUND MESSAGE ==========");
  logger.i("Message ID: ${message.messageId}");
  logger.i("Title: ${message.notification?.title}");
  logger.i("Body: ${message.notification?.body}");
  logger.i("Data: ${message.data}");

  final title = message.data['title'] ?? message.notification?.title ?? '';
  if (title.contains('العميل اختارك')) {
    await NotificationCounter.incrementSmsFromBackground();
  } else {
    await NotificationCounter.incrementNotificationFromBackground();

    logger.w(
      CacheHelper.getDataFromSharedPreference(key: 'notification_count'),
    );
  }
}
