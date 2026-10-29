import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/cache/session_cleaner.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/features/settings/presentation/bloc/logout_bloc.dart';
import 'package:whats_order/features/settings/presentation/screens/settings_screen.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_confirmation_dialog.dart';
import 'package:whats_order/injection/injection_container.dart';

import 'helpers/harness.dart';

class _FakeAdapter implements HttpClientAdapter {
  int status = 200;
  bool offline = false;
  Completer<void>? gate;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await gate?.future;
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;

  Object? cached(String key) =>
      CacheHelper.getDataFromSharedPreference(key: key);

  Future<void> pump(WidgetTester tester, String locale) async {
    await initPrefs({
      CacheKeys.userModel: '{"id":"v1"}',
      CacheKeys.accessToken: 'access',
      CacheKeys.refreshToken: 'refresh',
      CacheKeys.firstName: 'Ahmed',
      CacheKeys.appLang: locale,
    });
    ProfileName.fullName.value = 'Ahmed';

    adapter = _FakeAdapter();
    DioHelper.dio = Dio(BaseOptions(baseUrl: EndPoints.baseUrl))
      ..httpClientAdapter = adapter;
    if (sl.isRegistered<LogoutBloc>()) sl.unregister<LogoutBloc>();
    sl.registerFactory(
      () => LogoutBloc(FakeNetwork(), const LocalSessionCleaner()),
    );
    addTearDown(() {
      if (sl.isRegistered<LogoutBloc>()) sl.unregister<LogoutBloc>();
    });

    useTallScreen(tester);
    await tester.pumpWidget(
      BlocProvider<LocaleCubit>(
        create: (_) => LocaleCubit(),
        child: localizedApp(
          const SettingsScreen(),
          locale: locale,
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(body: Text('route:${settings.name}')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester, String locale) async {
    await tester.tap(find.text(kTranslations[locale]!['logout']!));
    await tester.pumpAndSettle();
  }

  Finder confirmButton(String locale) => find.descendant(
    of: find.byType(SettingsConfirmationDialog),
    matching: find.widgetWithText(
      ElevatedButton,
      kTranslations[locale]!['logout']!,
    ),
  );

  for (final locale in ['en', 'ar']) {
    final t = kTranslations[locale]!;

    group('logout flow ($locale)', () {
      testWidgets('tapping logout opens the confirmation dialog', (
        tester,
      ) async {
        await pump(tester, locale);
        await openDialog(tester, locale);

        final dialog = find.byType(SettingsConfirmationDialog);
        expect(dialog, findsOneWidget);
        expect(
          find.descendant(of: dialog, matching: find.text(t['logout_msg']!)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text(t['cancel']!)),
          findsOneWidget,
        );
        // Dialog title and confirm button both read "logout".
        expect(
          find.descendant(of: dialog, matching: find.text(t['logout']!)),
          findsNWidgets(2),
        );
        expect(adapter.requests, isEmpty);
      });

      testWidgets('cancel keeps the session and sends no request', (
        tester,
      ) async {
        await pump(tester, locale);
        await openDialog(tester, locale);
        await tester.tap(find.text(t['cancel']!));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsConfirmationDialog), findsNothing);
        expect(cached(CacheKeys.accessToken), 'access');
        expect(cached(CacheKeys.userModel), isNotNull);
        expect(adapter.requests, isEmpty);
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('dismissing the dialog keeps the session', (tester) async {
        await pump(tester, locale);
        await openDialog(tester, locale);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsConfirmationDialog), findsNothing);
        expect(cached(CacheKeys.refreshToken), 'refresh');
        expect(adapter.requests, isEmpty);
      });

      testWidgets('confirm calls the API, clears the session, opens sign-in', (
        tester,
      ) async {
        await pump(tester, locale);
        await openDialog(tester, locale);
        await tester.tap(confirmButton(locale));
        await tester.pumpAndSettle();

        expect(adapter.requests, hasLength(1));
        expect(adapter.requests.single.path, EndPoints.epLogout);
        for (final key in [
          CacheKeys.userModel,
          CacheKeys.accessToken,
          CacheKeys.refreshToken,
          CacheKeys.firstName,
        ]) {
          expect(cached(key), isNull, reason: key);
        }
        expect(cached(CacheKeys.appLang), locale);
        expect(ProfileName.fullName.value, '');
        expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
        expect(find.byType(SettingsScreen), findsNothing);
      });

      testWidgets('shows a blocking spinner while the request is running', (
        tester,
      ) async {
        await pump(tester, locale);
        adapter.gate = Completer<void>();
        await openDialog(tester, locale);
        await tester.tap(confirmButton(locale));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(SettingsScreen), findsOneWidget);

        // The barrier swallows taps, so logout cannot be triggered twice.
        await tester.tap(find.text(t['logout']!), warnIfMissed: false);
        await tester.pump();
        expect(find.byType(SettingsConfirmationDialog), findsNothing);
        expect(adapter.requests, hasLength(1));

        adapter.gate!.complete();
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
        expect(adapter.requests, hasLength(1));
      });

      testWidgets('server error: message shown and user still signed out', (
        tester,
      ) async {
        await pump(tester, locale);
        adapter.status = 500;
        await openDialog(tester, locale);
        await tester.tap(confirmButton(locale));
        await tester.pumpAndSettle();

        expect(snackBarText(t['logout_server_failed']!), findsOneWidget);
        expect(cached(CacheKeys.accessToken), isNull);
        expect(cached(CacheKeys.refreshToken), isNull);
        expect(cached(CacheKeys.userModel), isNull);
        expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
      });

      testWidgets('no connection behaves like a server error', (tester) async {
        await pump(tester, locale);
        adapter.offline = true;
        await openDialog(tester, locale);
        await tester.tap(confirmButton(locale));
        await tester.pumpAndSettle();

        expect(snackBarText(t['logout_server_failed']!), findsOneWidget);
        expect(cached(CacheKeys.accessToken), isNull);
        expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
      });
    });
  }
}
