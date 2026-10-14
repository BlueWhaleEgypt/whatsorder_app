import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/sign_in/data/sign_in_response.dart';
import 'package:whats_order/features/auth/sign_in/presentation/bloc/sign_in_bloc.dart';
import 'package:whats_order/features/auth/sign_in/presentation/bloc/sign_in_event.dart';
import 'package:whats_order/features/auth/sign_in/presentation/bloc/sign_in_state.dart';
import 'package:whats_order/features/auth/sign_in/presentation/screens/sign_in_screen.dart';
import 'package:whats_order/injection/injection_container.dart';

import 'helpers/harness.dart';

String _en(String key) => kTranslations['en']![key]!;
String _ar(String key) => kTranslations['ar']![key]!;

class _RecordingSignInBloc extends SignInBloc {
  final events = <SignInEvent>[];
  _RecordingSignInBloc() : super(FakeNetwork());

  @override
  void add(SignInEvent event) => events.add(event);

  void show(SignInState state) => emit(state);

  List<LoginEvent> get logins => events.whereType<LoginEvent>().toList();
}

void main() {
  late _RecordingSignInBloc bloc;
  late List<RouteSettings> pushed;
  late int tokenCalls;

  setUp(() async {
    await sl.reset();
    bloc = _RecordingSignInBloc();
    sl.registerFactory<SignInBloc>(() => bloc);
    pushed = [];
    tokenCalls = 0;
  });

  tearDown(() async => sl.reset());

  Future<void> pump(
    WidgetTester tester, {
    String locale = 'en',
    Map<String, Object> prefs = const {},
    Future<String?> Function()? token,
  }) async {
    await initPrefs(prefs);
    useTallScreen(tester);
    await tester.pumpWidget(
      BlocProvider<LocaleCubit>(
        create: (_) => LocaleCubit(),
        child: localizedApp(
          SignInScreen(
            fcmTokenProvider:
                token ??
                () async {
                  tokenCalls++;
                  return 'fcm-123';
                },
          ),
          locale: locale,
          onGenerateRoute: (settings) {
            pushed.add(settings);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => Scaffold(body: Text('route:${settings.name}')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder phoneField() => find.byType(TextFormField).at(0);
  Finder passwordField() => find.byType(TextFormField).at(1);
  Finder signInButton(String locale) =>
      find.text(kTranslations[locale]!['sign_in']!);

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String phone = '01012345678',
    String password = 'secret123',
  }) async {
    await tester.enterText(phoneField(), phone);
    await tester.enterText(passwordField(), password);
    await tester.tap(signInButton('en'));
    await tester.pumpAndSettle();
  }

  group('validation', () {
    testWidgets('empty fields show localized errors and send nothing', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(signInButton('en'));
      await tester.pumpAndSettle();

      expect(find.text(_en('phone_required')), findsOneWidget);
      expect(find.text(_en('password_required')), findsOneWidget);
      expect(bloc.logins, isEmpty);
      expect(tokenCalls, 0, reason: 'no token fetch before validation');
    });

    testWidgets('a short phone is rejected', (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '0101');
      await tester.enterText(passwordField(), 'secret123');
      await tester.tap(signInButton('en'));
      await tester.pumpAndSettle();

      expect(find.text(_en('phone_invalid_length')), findsOneWidget);
      expect(bloc.logins, isEmpty);
    });

    testWidgets('errors follow the Arabic locale', (tester) async {
      await pump(tester, locale: 'ar');
      await tester.tap(signInButton('ar'));
      await tester.pumpAndSettle();

      expect(find.text(_ar('phone_required')), findsOneWidget);
      expect(find.text(_ar('password_required')), findsOneWidget);
    });
  });

  group('submission', () {
    testWidgets('sends the normalised phone, password and FCM token', (
      tester,
    ) async {
      await pump(tester);
      await fillAndSubmit(tester, phone: '01012345678');

      final request = bloc.logins.single.request;
      expect(request.phone, '201012345678');
      expect(request.password, 'secret123');
      expect(request.fcmToken, 'fcm-123');
      expect(request.toJson()['username'], '201012345678');
      expect(request.toJson()['firebaseToken'], 'fcm-123');
    });

    testWidgets('a missing FCM token is sent as an empty string', (
      tester,
    ) async {
      await pump(tester, token: () async => null);
      await fillAndSubmit(tester, phone: '01012345678');

      expect(bloc.logins.single.request.fcmToken, '');
    });

    testWidgets('a second tap while the token loads sends only one login', (
      tester,
    ) async {
      final completer = Completer<String?>();
      await pump(tester, token: () => completer.future);

      await tester.enterText(phoneField(), '01012345678');
      await tester.enterText(passwordField(), 'secret123');
      await tester.tap(signInButton('en'));
      await tester.pump();
      await tester.tap(signInButton('en'));
      await tester.pump();

      completer.complete('late-token');
      await tester.pumpAndSettle();

      expect(bloc.logins, hasLength(1));
      expect(bloc.logins.single.request.fcmToken, 'late-token');
    });

    testWidgets('no login is sent while the bloc is loading', (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '01012345678');
      await tester.enterText(passwordField(), 'secret123');

      bloc.show(LoadingSignInState());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.widget<GradientButton>(find.byType(GradientButton)).loading,
        isTrue,
      );
      await tester.tap(find.byType(GradientButton));
      await tester.pump();
      expect(bloc.logins, isEmpty);
      expect(tokenCalls, 0);
    });

    testWidgets('leaving the screen before the token arrives sends nothing', (
      tester,
    ) async {
      final completer = Completer<String?>();
      await pump(tester, token: () => completer.future);
      await tester.enterText(phoneField(), '01012345678');
      await tester.enterText(passwordField(), 'secret123');
      await tester.tap(signInButton('en'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      completer.complete('too-late');
      await tester.pumpAndSettle();

      expect(bloc.logins, isEmpty);
    });
  });

  group('result handling', () {
    testWidgets('an error shows the message and stays on the form', (
      tester,
    ) async {
      await pump(tester);
      bloc.show(const ErrorSignInState(message: 'Wrong password'));
      await tester.pumpAndSettle();

      expect(snackBarText('Wrong password'), findsOneWidget);
      expect(find.text(_en('sign_in')), findsWidgets);
      expect(pushed.where((r) => r.name == NamedRoutes.home), isEmpty);
    });

    testWidgets('success opens home and clears the route stack', (
      tester,
    ) async {
      await pump(tester);
      bloc.show(const LoadedSignInState(getSignInResponse: SignInResponse()));
      await tester.pumpAndSettle();

      expect(find.text('route:${NamedRoutes.home}'), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('Remember Me on saves the credentials after login', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(phoneField(), '01012345678');
      await tester.enterText(passwordField(), 'secret123');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      bloc.show(const LoadedSignInState(getSignInResponse: SignInResponse()));
      await tester.pumpAndSettle();

      String? read(String key) =>
          CacheHelper.getDataFromSharedPreference(key: key) as String?;
      expect(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.rememberMe),
        true,
      );
      expect(read(CacheKeys.phone), '01012345678');
      expect(read(CacheKeys.password), 'secret123');
    });

    testWidgets('Remember Me off removes the stored credentials', (
      tester,
    ) async {
      await pump(
        tester,
        prefs: {
          CacheKeys.rememberMe: true,
          CacheKeys.phone: '01099998888',
          CacheKeys.password: 'old',
        },
      );
      await tester.tap(find.byType(Checkbox)); // un-check
      await tester.pump();

      bloc.show(const LoadedSignInState(getSignInResponse: SignInResponse()));
      await tester.pumpAndSettle();

      for (final key in [
        CacheKeys.rememberMe,
        CacheKeys.phone,
        CacheKeys.password,
      ]) {
        expect(CacheHelper.getDataFromSharedPreference(key: key), isNull);
      }
    });
  });

  group('remember me on open', () {
    testWidgets('restores saved credentials and ticks the box', (tester) async {
      await pump(
        tester,
        prefs: {
          CacheKeys.rememberMe: true,
          CacheKeys.phone: '01099998888',
          CacheKeys.password: 'saved-pass',
        },
      );

      expect(find.text('01099998888'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('does nothing when Remember Me was not chosen', (tester) async {
      await pump(
        tester,
        prefs: {CacheKeys.phone: '01099998888'}, // stale value, flag missing
      );

      expect(find.text('01099998888'), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    });

    testWidgets('leaving before the cache read completes is safe', (
      tester,
    ) async {
      await initPrefs({CacheKeys.rememberMe: true});
      useTallScreen(tester);
      await tester.pumpWidget(
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit(),
          child: localizedApp(SignInScreen(fcmTokenProvider: () async => '')),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('navigation', () {
    testWidgets('Forgot password passes the normalised phone', (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '01012345678');
      await tester.tap(find.text(_en('forget_password')));
      await tester.pumpAndSettle();

      final route = pushed.lastWhere(
        (r) => r.name == NamedRoutes.forgotPassword,
      );
      expect(route.arguments, '201012345678');
    });

    testWidgets('Forgot password with an empty phone passes an empty one', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(_en('forget_password')));
      await tester.pumpAndSettle();

      expect(
        pushed.lastWhere((r) => r.name == NamedRoutes.forgotPassword).arguments,
        '',
      );
    });

    testWidgets('the sign-up link replaces the screen', (tester) async {
      await pump(tester);
      await tester.tap(find.textContaining(_en('sign_up'), findRichText: true));
      await tester.pumpAndSettle();

      expect(find.text('route:${NamedRoutes.signup}'), findsOneWidget);
    });
  });

  group('rendering', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('shows the $locale texts', (tester) async {
        await pump(tester, locale: locale);
        final t = kTranslations[locale]!;

        for (final key in [
          'welcome_back',
          'signin_subtitle',
          'forget_password',
          'remember_me',
          'secure_platform',
          'fast_delivery',
        ]) {
          expect(find.text(t[key]!), findsOneWidget, reason: '$locale/$key');
        }
        expect(find.text(t['sign_in']!), findsOneWidget);
      });
    }
  });
}
