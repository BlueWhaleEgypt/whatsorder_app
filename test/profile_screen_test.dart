import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/orders/data/vendor_response.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/sectors_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';
import 'package:whats_order/features/settings/presentation/screens/profile_screen.dart';
import 'package:whats_order/features/settings/presentation/taps/security_tab.dart';
import 'package:whats_order/injection/injection_container.dart';

import 'helpers/harness.dart';

String _en(String key) => kTranslations['en']![key]!;
String _ar(String key) => kTranslations['ar']![key]!;

class _RecordingOtpBloc extends OtpBloc {
  final events = <OtpEvent>[];
  _RecordingOtpBloc() : super(FakeNetwork());

  @override
  void add(OtpEvent event) => events.add(event);

  void show(OtpState state) => emit(state);
}

const _vendor = VendorModel(
  id: 'v1',
  firstName: 'Ahmed',
  lastName: 'Ali',
  email: 'ahmed@example.com',
);

void main() {
  late RecordingVendorBloc vendorBloc;
  late List<RecordingUpdateProfileBloc> updateBlocs;
  late _RecordingOtpBloc otpBloc;

  setUp(() async {
    await initPrefs();
    await sl.reset();
    updateBlocs = [];
    otpBloc = _RecordingOtpBloc();
    sl.registerFactory<UpdateProfileBloc>(() {
      final b = RecordingUpdateProfileBloc();
      updateBlocs.add(b);
      return b;
    });
    sl.registerFactory<SectorsBloc>(() => RecordingSectorsBloc());
    sl.registerFactory<ChangePhoneBloc>(() => RecordingChangePhoneBloc());
    sl.registerFactory<ChangePasswordBloc>(() => RecordingChangePasswordBloc());
    sl.registerFactory<OtpBloc>(() => otpBloc);
  });

  tearDown(() async => sl.reset());

  Future<void> pumpScreen(WidgetTester tester, {String locale = 'en'}) async {
    useTallScreen(tester);
    vendorBloc = RecordingVendorBloc();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VendorBloc>.value(value: vendorBloc),
          BlocProvider<OnboardingCubit>(create: (_) => OnboardingCubit()),
        ],
        child: localizedApp(const ProfileScreen(), locale: locale),
      ),
    );
    await tester.pump();
  }

  Future<void> showVendor(
    WidgetTester tester, [
    VendorModel? v = _vendor,
  ]) async {
    vendorBloc.show(VendorLoaded(vendorResponse: VendorResponse(vendor: v)));
    await tester.pumpAndSettle();
  }

  group('ProfileScreen', () {
    testWidgets('requests the vendor once when opened', (tester) async {
      await pumpScreen(tester);
      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(1));
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('shows all six tabs in $locale', (tester) async {
        await pumpScreen(tester, locale: locale);
        await showVendor(tester);

        for (final key in [
          'profile',
          'files',
          'location',
          'sector',
          'change_phone',
          'security',
        ]) {
          expect(
            find.text(kTranslations[locale]![key]!),
            findsWidgets,
            reason: '$locale/$key',
          );
        }
      });
    }

    testWidgets('selecting a tab shows its content', (tester) async {
      await pumpScreen(tester);
      await showVendor(tester);

      await tester.tap(find.text(_en('sector')));
      await tester.pumpAndSettle();
      expect(find.text(_en('no_sectors_available')), findsOneWidget);
    });

    testWidgets('missing vendor data shows a localized message', (
      tester,
    ) async {
      await pumpScreen(tester, locale: 'ar');
      await showVendor(tester, null);
      expect(find.text(_ar('vendor_data_not_available')), findsOneWidget);
    });

    testWidgets('load errors are localized or sanitised', (tester) async {
      await pumpScreen(tester, locale: 'ar');
      vendorBloc.show(const VendorError(message: 'no_internet'));
      await tester.pumpAndSettle();
      expect(find.text(_ar('no_internet')), findsOneWidget);

      vendorBloc.show(const VendorError(message: 'DioException: 500'));
      await tester.pumpAndSettle();
      expect(find.text(_ar('something_went_wrong')), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
    });

    testWidgets('refreshes the vendor once per successful update', (
      tester,
    ) async {
      await pumpScreen(tester);
      await showVendor(tester);
      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(1));

      // Info, Files and Location each own an UpdateProfileBloc.
      expect(updateBlocs, hasLength(3));

      updateBlocs[0].show(
        const UpdateProfileSuccess('profile_updated_successfully'),
      );
      await tester.pumpAndSettle();
      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(2));

      // Failures and loading never refresh.
      updateBlocs[1].show(const UpdateProfileLoading());
      updateBlocs[1].show(const UpdateProfileError('profile_update_failed'));
      await tester.pumpAndSettle();
      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(2));
    });

    testWidgets('keeps the tabs on screen while the vendor refreshes', (
      tester,
    ) async {
      await pumpScreen(tester);
      await showVendor(tester);

      vendorBloc.show(VendorLoading());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Ahmed'), findsOneWidget);

      vendorBloc.show(const VendorError(message: 'no_internet'));
      await tester.pump();
      expect(find.text('Ahmed'), findsOneWidget);
    });

    testWidgets('the refreshed vendor reaches the Info tab', (tester) async {
      await pumpScreen(tester);
      await showVendor(tester);

      await showVendor(
        tester,
        const VendorModel(id: 'v1', firstName: 'Omar', lastName: 'Ali'),
      );
      expect(find.text('Omar'), findsOneWidget);
      expect(find.text('Ahmed'), findsNothing);
    });
  });

  group('SecurityTab', () {
    Future<void> pumpTab(
      WidgetTester tester, {
      required VendorModel vendor,
      String locale = 'en',
    }) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        localizedApp(SecurityTab(vendor: vendor), locale: locale),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('missing phone shows a localized hint and sends no OTP', (
      tester,
    ) async {
      await pumpTab(
        tester,
        vendor: const VendorModel(id: 'v1'),
        locale: 'ar',
      );
      await tester.tap(find.text(_ar('phone_verification')));
      await tester.pumpAndSettle();

      expect(snackBarText(_ar('phone_number_missing')), findsOneWidget);
      expect(otpBloc.events, isEmpty);
    });

    testWidgets('a vendor phone triggers an OTP request', (tester) async {
      await pumpTab(
        tester,
        vendor: const VendorModel(id: 'v1', phone: '01012345678'),
      );
      await tester.tap(find.text(_en('phone_verification')));
      await tester.pumpAndSettle();

      expect(otpBloc.events.single, isA<SendOtpEvent>());
    });

    testWidgets('OTP errors are sanitised and localized', (tester) async {
      await pumpTab(
        tester,
        vendor: const VendorModel(id: 'v1'),
        locale: 'ar',
      );
      otpBloc.show(const ErrorOtpState('SocketException: x'));
      await tester.pumpAndSettle();

      expect(snackBarText(_ar('something_went_wrong')), findsOneWidget);
    });
  });
}
