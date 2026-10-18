import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/utils/account_type.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/sign_up/data/sign_up_request.dart';
import 'package:whats_order/features/auth/sign_up/data/sign_up_response.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_state.dart';
import 'package:whats_order/features/auth/sign_up/presentation/screens/steps/upload_files_step.dart';

import 'helpers/harness.dart';

/// Answers every request with a fixed status and JSON body (no network).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);
  final int status;
  final Object? body;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RecordingOtpBloc extends OtpBloc {
  final events = <OtpEvent>[];
  _RecordingOtpBloc() : super(FakeNetwork());

  @override
  void add(OtpEvent event) => events.add(event);
}

class _TestOnboardingCubit extends OnboardingCubit {
  void show(OnboardingState s) => emit(s);
}

String _en(String k) => kTranslations['en']![k]!;

void main() {
  late File file;

  setUp(() async {
    await initPrefs();
    file = File('${Directory.systemTemp.path}/signup_test_register.jpg')
      ..writeAsBytesSync([1, 2, 3]);
  });

  SignUpRequest request() => SignUpRequest(
    phone: '201012345678',
    password: 'secret123',
    firstName: 'Ahmed',
    email: 'a@b.com',
    type: AccountType.company,
    commercialRegister: file,
  );

  Future<({dynamic result, _FakeAdapter adapter})> signUp(
    int status,
    Object? body,
  ) async {
    final adapter = _FakeAdapter(status, body);
    DioHelper.dio = Dio()..httpClientAdapter = adapter;
    final result = await const SignupResponse().getData(request());
    return (result: result, adapter: adapter);
  }

  String? failureOf(dynamic result) =>
      (result as dynamic).fold((f) => f.message as String, (_) => null);

  group('signup API result', () {
    test('success (201) returns the response and stores the user id', () async {
      final r = await signUp(201, {'userId': 'u-1', 'message': 'ok'});

      expect(failureOf(r.result), isNull);
      expect(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.userId),
        'u-1',
      );
    });

    test('409 Conflict is a failure with a stable, localizable key', () async {
      final r = await signUp(409, {
        'type': 'about:blank',
        'title': 'Conflict',
        'status': 409,
        'detail': 'Error: Phone is already taken! Try to verify it.',
        'instance': '/api/auth/signup',
      });

      expect(failureOf(r.result), 'phone_already_registered');
      expect(r.adapter.requests, 1, reason: 'no retry / second request');
      expect(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.userId),
        isNull,
        reason: 'nothing is stored as if signup worked',
      );
    });

    test('other API errors keep the backend detail', () async {
      final r = await signUp(400, {'detail': 'Email is invalid'});
      expect(failureOf(r.result), 'Email is invalid');
    });

    test('an error without a body falls back to the generic message', () async {
      final r = await signUp(500, null);
      expect(failureOf(r.result), 'Something went wrong');
    });
  });

  group('upload step reaction', () {
    late _TestOnboardingCubit cubit;
    late _RecordingOtpBloc otp;
    late List<RouteSettings> pushed;

    Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
      useTallScreen(tester);
      cubit = _TestOnboardingCubit();
      otp = _RecordingOtpBloc();
      pushed = [];
      await tester.pumpWidget(
        localizedApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<OnboardingCubit>.value(value: cubit),
              BlocProvider<OtpBloc>.value(value: otp),
            ],
            child: const UploadFilesStep(),
          ),
          locale: locale,
          onGenerateRoute: (s) {
            pushed.add(s);
            return MaterialPageRoute(
              settings: s,
              builder: (_) => Scaffold(body: Text('route:${s.name}')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final locale in ['en', 'ar']) {
      testWidgets('409 shows the localized message, no OTP ($locale)', (
        tester,
      ) async {
        await pump(tester, locale: locale);
        cubit.show(
          cubit.state.copyWith(
            isSubmitting: false,
            submitError: 'phone_already_registered',
          ),
        );
        await tester.pumpAndSettle();

        expect(
          snackBarText(kTranslations[locale]!['phone_already_registered']!),
          findsOneWidget,
        );
        expect(otp.events, isEmpty, reason: 'no SendOtpEvent');
        expect(pushed, isEmpty, reason: 'stays on the signup step');
        // Loading is cleared, so the user can fix the number and retry.
        expect(cubit.state.isSubmitting, isFalse);
      });
    }

    testWidgets('the old English "already taken" text no longer starts OTP', (
      tester,
    ) async {
      await pump(tester);
      cubit.show(
        cubit.state.copyWith(
          submitError: 'Error: Phone is already taken! Try to verify it.',
        ),
      );
      await tester.pumpAndSettle();

      expect(otp.events, isEmpty);
    });

    testWidgets('other errors are shown, with no OTP', (tester) async {
      await pump(tester);
      cubit.show(cubit.state.copyWith(submitError: 'Email is invalid'));
      await tester.pumpAndSettle();
      expect(snackBarText('Email is invalid'), findsOneWidget);

      await clearSnackBars(tester);
      cubit.show(cubit.state.copyWith(submitError: 'SocketException: x'));
      await tester.pumpAndSettle();
      expect(snackBarText(_en('something_went_wrong')), findsOneWidget);
      expect(otp.events, isEmpty);
    });

    testWidgets('a successful signup still requests the OTP', (tester) async {
      await pump(tester);
      cubit.show(cubit.state.copyWith(submitted: true));
      await tester.pumpAndSettle();

      expect(otp.events.whereType<SendOtpEvent>(), hasLength(1));
    });
  });
}
