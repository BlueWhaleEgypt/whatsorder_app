import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/otp/data/send_otp_response.dart';
import 'package:whats_order/features/auth/otp/data/verify_otp_response.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/verify_otp_screen.dart';

import 'helpers/harness.dart';

String _tr(String l, String k) => kTranslations[l]![k]!;

class _RecordingOtpBloc extends OtpBloc {
  final events = <OtpEvent>[];
  _RecordingOtpBloc() : super(FakeNetwork());

  @override
  void add(OtpEvent event) => events.add(event);

  void show(OtpState state) => emit(state);
}

void main() {
  late _RecordingOtpBloc bloc;

  Future<void> pump(
    WidgetTester tester, {
    String locale = 'en',
    Map<String, Object> prefs = const {},
    double width = 360,
  }) async {
    await initPrefs(prefs);
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bloc = _RecordingOtpBloc();
    await tester.pumpWidget(
      localizedApp(
        BlocProvider<OtpBloc>.value(
          value: bloc,
          child: const VerifyOtpScreen(phone: '201012345678'),
        ),
        locale: locale,
        onGenerateRoute: (s) => MaterialPageRoute(
          settings: s,
          builder: (_) => Scaffold(body: Text('route:${s.name}')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in ['en', 'ar']) {
    testWidgets('renders the localized header and phone ($locale)', (
      tester,
    ) async {
      await pump(tester, locale: locale);

      expect(find.text(_tr(locale, 'fp_otp_title')), findsWidgets);
      expect(find.text(_tr(locale, 'fp_otp_desc')), findsOneWidget);
      expect(find.text('201012345678'), findsOneWidget);
      expect(find.text(_tr(locale, 'Verify_OTP')), findsOneWidget);
      expect(find.text(_tr(locale, 'resend_code')), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the code input stays left-to-right in Arabic', (tester) async {
    await pump(tester, locale: 'ar');
    final direction = tester
        .widget<Directionality>(
          find
              .ancestor(
                of: find.byType(Pinput),
                matching: find.byType(Directionality),
              )
              .first,
        )
        .textDirection;
    expect(direction, TextDirection.ltr);
  });

  testWidgets('verify sends the phone and the entered code', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(Pinput), '123456');
    await tester.tap(find.text(_tr('en', 'Verify_OTP')));
    await tester.pumpAndSettle();

    final sent = bloc.events.whereType<VerifyOtpEvent>().single;
    expect(sent.phone, '201012345678');
    expect(sent.otp, '123456');
  });

  testWidgets('resend sends SendOtpEvent for the phone', (tester) async {
    await pump(tester);
    await tester.tap(find.text(_tr('en', 'resend_code')));
    await tester.pumpAndSettle();

    expect(bloc.events.whereType<SendOtpEvent>().single.phone, '201012345678');
  });

  testWidgets('loading disables verify, resend and the input', (tester) async {
    await pump(tester);
    bloc.show(LoadingOtpState());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.widget<GradientButton>(find.byType(GradientButton)).loading,
      isTrue,
    );
    await tester.tap(find.byType(GradientButton), warnIfMissed: false);
    await tester.tap(find.text(_tr('en', 'resend_code')), warnIfMissed: false);
    await tester.pump();
    expect(bloc.events, isEmpty);
  });

  testWidgets('verified with a token goes home, clearing the stack', (
    tester,
  ) async {
    await pump(tester, prefs: {CacheKeys.accessToken: 'tok'});
    bloc.show(const VerifiedOtpState(VerifyOtpResponse()));
    await tester.pumpAndSettle();

    expect(find.text('route:${NamedRoutes.home}'), findsOneWidget);
  });

  testWidgets('verified without a token goes to sign in', (tester) async {
    await pump(tester);
    bloc.show(const VerifiedOtpState(VerifyOtpResponse()));
    await tester.pumpAndSettle();

    expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
  });

  testWidgets('errors: server text kept, technical text hidden', (
    tester,
  ) async {
    await pump(tester);
    bloc.show(const ErrorOtpState('Invalid code'));
    await tester.pumpAndSettle();
    expect(snackBarText('Invalid code'), findsOneWidget);

    await clearSnackBars(tester);
    bloc.show(const ErrorOtpState('SocketException: x'));
    await tester.pumpAndSettle();
    expect(snackBarText(_tr('en', 'something_went_wrong')), findsOneWidget);
  });

  testWidgets('fits a narrow screen with the keyboard open', (tester) async {
    await pump(tester, width: 320);
    tester.view.physicalSize = const Size(320, 480);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text(_tr('en', 'Verify_OTP')));
  });
}
