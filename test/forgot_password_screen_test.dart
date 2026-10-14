import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/otp/data/forget_password_response.dart';
import 'package:whats_order/features/auth/otp/data/send_otp_response.dart';
import 'package:whats_order/features/auth/otp/data/verify_otp_response.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/forgot_password_screen.dart';

import 'helpers/harness.dart';

String _en(String key) => kTranslations['en']![key]!;
String _ar(String key) => kTranslations['ar']![key]!;

class _RecordingOtpBloc extends OtpBloc {
  final events = <OtpEvent>[];
  _RecordingOtpBloc() : super(FakeNetwork());

  @override
  void add(OtpEvent event) => events.add(event);

  void show(OtpState state) => emit(state);

  List<T> of<T extends OtpEvent>() => events.whereType<T>().toList();
}

void main() {
  late _RecordingOtpBloc bloc;

  setUp(() => initPrefs());

  Future<void> pump(
    WidgetTester tester, {
    String phone = '',
    String locale = 'en',
  }) async {
    useTallScreen(tester);
    bloc = _RecordingOtpBloc();
    // Pushed on top of a launcher so the final Navigator.pop is safe.
    await tester.pumpWidget(
      localizedApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider<OtpBloc>.value(
                  value: bloc,
                  child: ForgotPasswordScreen(phone: phone),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> goToOtpStep(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField), '01012345678');
    await tester.tap(find.text(_en('Send_OTP')));
    await tester.pumpAndSettle();
    bloc.show(
      const LoadedOtpState(SendOtpResponse(message: 'raw server text')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToPasswordStep(WidgetTester tester) async {
    await goToOtpStep(tester);
    await tester.enterText(find.byType(Pinput), '123456');
    await tester.tap(find.text(_en('Verify_OTP')));
    await tester.pumpAndSettle();
    await clearSnackBars(tester);
    bloc.show(const VerifiedOtpState(VerifyOtpResponse(userId: 'u-9')));
    await tester.pumpAndSettle();
  }

  group('phone step', () {
    testWidgets('prefills the phone and shows the localized header', (
      tester,
    ) async {
      await pump(tester, phone: '01012345678');
      expect(find.text('01012345678'), findsOneWidget);
      expect(find.text(_en('forgot_password_title')), findsOneWidget);
      expect(find.text(_en('fp_phone_title')), findsOneWidget);
      expect(find.text(_en('fp_step_phone')), findsOneWidget);
      expect(find.text(_en('fp_step_otp')), findsOneWidget);
      expect(find.text(_en('fp_step_password')), findsOneWidget);
    });

    testWidgets('empty and malformed phones are rejected', (tester) async {
      await pump(tester);

      await tester.tap(find.text(_en('Send_OTP')));
      await tester.pumpAndSettle();
      expect(find.text(_en('phone_required')), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12ab');
      await tester.tap(find.text(_en('Send_OTP')));
      await tester.pumpAndSettle();
      expect(find.text(_en('phone_invalid')), findsOneWidget);
      expect(bloc.of<SendOtpEvent>(), isEmpty);
    });

    testWidgets('a valid phone is normalised and sent once', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), '010 1234 5678');
      await tester.tap(find.text(_en('Send_OTP')));
      await tester.pumpAndSettle();

      expect(
        bloc.of<SendOtpEvent>().single.phone,
        '2010 1234 5678'.replaceAll(' ', ''),
      );
    });

    testWidgets('loading blocks duplicate submissions', (tester) async {
      await pump(tester, phone: '01012345678');
      bloc.show(LoadingOtpState());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.widget<GradientButton>(find.byType(GradientButton)).loading,
        isTrue,
      );
      await tester.tap(find.byType(GradientButton));
      await tester.pump();
      expect(bloc.of<SendOtpEvent>(), isEmpty);
    });

    testWidgets('validation text follows the Arabic locale', (tester) async {
      await pump(tester, locale: 'ar');
      await tester.tap(find.text(_ar('Send_OTP')));
      await tester.pumpAndSettle();
      expect(find.text(_ar('phone_required')), findsOneWidget);
      expect(find.text(_ar('fp_phone_title')), findsOneWidget);
    });
  });

  group('otp step', () {
    testWidgets('moves on with a localized message, never server text', (
      tester,
    ) async {
      await pump(tester);
      await goToOtpStep(tester);

      expect(find.text(_en('fp_otp_title')), findsOneWidget);
      expect(find.text('201012345678'), findsOneWidget);
      expect(snackBarText(_en('otp_sent_successfully')), findsOneWidget);
      expect(find.text('raw server text'), findsNothing);
    });

    testWidgets('the code input stays left-to-right in Arabic', (tester) async {
      await pump(tester, locale: 'ar');
      await tester.enterText(find.byType(TextFormField), '01012345678');
      await tester.tap(find.text(_ar('Send_OTP')));
      await tester.pumpAndSettle();
      bloc.show(const LoadedOtpState(SendOtpResponse()));
      await tester.pumpAndSettle();

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
      expect(find.text(_ar('fp_otp_title')), findsOneWidget);
    });

    testWidgets('an incomplete code cannot be submitted', (tester) async {
      await pump(tester);
      await goToOtpStep(tester);

      await tester.tap(find.text(_en('Verify_OTP')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_en('otp_incomplete')), findsOneWidget);

      await tester.enterText(find.byType(Pinput), '123');
      await tester.tap(find.text(_en('Verify_OTP')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(bloc.of<VerifyOtpEvent>(), isEmpty);
    });

    testWidgets('a full code is verified with the phone', (tester) async {
      await pump(tester);
      await goToOtpStep(tester);
      await tester.enterText(find.byType(Pinput), '123456');
      await tester.tap(find.text(_en('Verify_OTP')));
      await tester.pumpAndSettle();

      final sent = bloc.of<VerifyOtpEvent>().single;
      expect(sent.phone, '201012345678');
      expect(sent.otp, '123456');
    });

    testWidgets('resend sends the code again; loading disables it', (
      tester,
    ) async {
      await pump(tester);
      await goToOtpStep(tester);

      await tester.tap(find.text(_en('resend_code')));
      await tester.pumpAndSettle();
      expect(bloc.of<SendOtpEvent>(), hasLength(2));

      bloc.show(LoadingOtpState());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text(_en('resend_code')), warnIfMissed: false);
      await tester.pump();
      expect(bloc.of<SendOtpEvent>(), hasLength(2));
    });

    testWidgets('Change number goes back to the phone step', (tester) async {
      await pump(tester);
      await goToOtpStep(tester);
      await tester.tap(find.text(_en('change_number')));
      await tester.pumpAndSettle();

      expect(find.text(_en('fp_phone_title')), findsOneWidget);
    });

    testWidgets('errors are localized and technical text is hidden', (
      tester,
    ) async {
      await pump(tester);
      await goToOtpStep(tester);
      await clearSnackBars(tester);

      bloc.show(const VerifiedOtpErrorState('invalid_response'));
      await tester.pumpAndSettle();
      expect(snackBarText(_en('invalid_response')), findsOneWidget);

      await clearSnackBars(tester);
      bloc.show(const ErrorOtpState('SocketException: failed'));
      await tester.pumpAndSettle();
      expect(snackBarText(_en('something_went_wrong')), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
    });
  });

  group('password step', () {
    testWidgets('validates required and minimum length', (tester) async {
      await pump(tester);
      await goToPasswordStep(tester);
      expect(find.text(_en('fp_password_title')), findsOneWidget);
      expect(find.text(_en('password_requirement_min_6')), findsOneWidget);

      await tester.tap(find.text(_en('Reset_Password')));
      await tester.pumpAndSettle();
      expect(find.text(_en('field_required')), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text(_en('Reset_Password')));
      await tester.pumpAndSettle();
      expect(find.text(_en('password_min_6')), findsOneWidget);
      expect(bloc.of<ForgetPasswordEvent>(), isEmpty);
    });

    testWidgets('the visibility toggle reveals the password', (tester) async {
      await pump(tester);
      await goToPasswordStep(tester);

      EditableText input() =>
          tester.widget<EditableText>(find.byType(EditableText));
      expect(input().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(input().obscureText, isFalse);
    });

    testWidgets('a valid password is submitted with the verified user id', (
      tester,
    ) async {
      await pump(tester);
      await goToPasswordStep(tester);
      await tester.enterText(find.byType(TextFormField), 'secret123');
      await tester.tap(find.text(_en('Reset_Password')));
      await tester.pumpAndSettle();

      final sent = bloc.of<ForgetPasswordEvent>().single;
      expect(sent.userId, 'u-9');
      expect(sent.newPassword, 'secret123');
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('success shows the $locale message and closes', (
        tester,
      ) async {
        await pump(tester, locale: locale);
        await tester.enterText(find.byType(TextFormField), '01012345678');
        await tester.tap(find.text(kTranslations[locale]!['Send_OTP']!));
        await tester.pumpAndSettle();
        bloc.show(const LoadedOtpState(SendOtpResponse()));
        await tester.pumpAndSettle();
        bloc.show(const VerifiedOtpState(VerifyOtpResponse(userId: 'u-9')));
        await tester.pumpAndSettle();
        await clearSnackBars(tester);

        bloc.show(const ForgetPasswordSuccessState(ForgetPasswordResponse()));
        await tester.pumpAndSettle();

        expect(
          snackBarText(
            kTranslations[locale]!['password_changed_successfully']!,
          ),
          findsOneWidget,
        );
        expect(find.byType(ForgotPasswordScreen), findsNothing);
      });
    }

    testWidgets('reset errors keep the user on the password step', (
      tester,
    ) async {
      await pump(tester);
      await goToPasswordStep(tester);

      await clearSnackBars(tester);
      bloc.show(const ForgetPasswordErrorState('Password is too weak'));
      await tester.pumpAndSettle();

      expect(snackBarText('Password is too weak'), findsOneWidget);
      expect(find.text(_en('Reset_Password')), findsOneWidget);
    });
  });
}
