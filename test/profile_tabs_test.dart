import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';
import 'package:whats_order/features/settings/data/phone/change_phone_response.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/change_password_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/change_phone_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/sectors_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/branches_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/sectors_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';
import 'package:whats_order/features/settings/presentation/screens/change_password_screen.dart';
import 'package:whats_order/features/settings/presentation/taps/branches_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/change_phone_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/files_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/location_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/sectores_tap.dart';
import 'package:whats_order/features/settings/presentation/taps/user_info_tab.dart';

import 'helpers/harness.dart';

String _en(String key) => kTranslations['en']![key]!;
String _ar(String key) => kTranslations['ar']![key]!;

const _vendor = VendorModel(
  id: 'v1',
  firstName: 'Ahmed',
  lastName: 'Ali',
  email: 'ahmed@example.com',
  phone: '01012345678',
  latitude: 30.5,
  longitude: 31.25,
  city: 'Cairo',
  state: 'Cairo Governorate',
  serviceDistance: 12.5,
  servingTheEntireArea: true,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() => initPrefs());

  // ───────────────────────── UserInfoTab ─────────────────────────
  group('UserInfoTab', () {
    late RecordingUpdateProfileBloc bloc;

    Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
      useTallScreen(tester);
      bloc = RecordingUpdateProfileBloc();
      await tester.pumpWidget(
        localizedApp(
          BlocProvider<UpdateProfileBloc>.value(
            value: bloc,
            child: const UserInfoTab(vendor: _vendor),
          ),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
    }

    List<TextFormField> fields(WidgetTester tester) =>
        tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();

    Future<void> tapAction(WidgetTester tester, String key) async {
      await tester.tap(find.text(t(tester, key)));
      await tester.pumpAndSettle();
    }

    testWidgets('is read-only and shows the vendor data by default', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('ahmed@example.com'), findsOneWidget);
      expect(fields(tester).every((f) => f.enabled == false), isTrue);
    });

    testWidgets('Edit enables the fields', (tester) async {
      await pump(tester);
      await tapAction(tester, 'edit');

      expect(fields(tester).every((f) => f.enabled == true), isTrue);
      expect(find.text(t(tester, 'save_changes')), findsOneWidget);
    });

    testWidgets('required and invalid values show validation errors', (
      tester,
    ) async {
      await pump(tester);
      await tapAction(tester, 'edit');

      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.enterText(find.byType(TextFormField).at(2), '');
      await tapAction(tester, 'save_changes');
      expect(find.text(_en('field_required')), findsOneWidget);
      expect(find.text(_en('email_is_required')), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ahmed');
      await tester.enterText(find.byType(TextFormField).at(2), 'not-an-email');
      await tapAction(tester, 'save_changes');
      expect(find.text(_en('enter_a_valid_email')), findsOneWidget);

      expect(bloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    testWidgets('validation messages follow the Arabic locale', (tester) async {
      await pump(tester, locale: 'ar');
      await tapAction(tester, 'edit');
      await tester.enterText(find.byType(TextFormField).at(2), '');
      await tapAction(tester, 'save_changes');

      expect(find.text(_ar('email_is_required')), findsOneWidget);
      expect(find.text(_en('email_is_required')), findsNothing);
    });

    testWidgets('save submits the edited values with the vendor id', (
      tester,
    ) async {
      await pump(tester);
      await tapAction(tester, 'edit');
      await tester.enterText(find.byType(TextFormField).at(0), 'Omar');
      await tapAction(tester, 'save_changes');

      final sent = bloc.of<SubmitUpdateProfileEvent>();
      expect(sent, hasLength(1));
      expect(sent.single.request.userId, 'v1');
      expect(sent.single.request.fields['firstName'], 'Omar');
      expect(sent.single.request.fields['lastName'], 'Ali');
      expect(sent.single.request.fields['email'], 'ahmed@example.com');
    });

    testWidgets('loading disables editing and duplicate submits', (
      tester,
    ) async {
      await pump(tester);
      await tapAction(tester, 'edit');

      bloc.show(const UpdateProfileLoading());
      await _settle(tester);

      expect(fields(tester).every((f) => f.enabled == false), isTrue);
      await tester.tap(find.text(t(tester, 'loading')));
      await _settle(tester);
      expect(bloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('success shows the $locale message and leaves edit mode', (
        tester,
      ) async {
        await pump(tester, locale: locale);
        await tapAction(tester, 'edit');

        bloc.show(const UpdateProfileSuccess('profile_updated_successfully'));
        await tester.pumpAndSettle();

        expect(
          snackBarText(kTranslations[locale]!['profile_updated_successfully']!),
          findsOneWidget,
        );
        expect(fields(tester).every((f) => f.enabled == false), isTrue);
      });
    }

    testWidgets('technical errors are hidden, server messages are kept', (
      tester,
    ) async {
      await pump(tester);
      await tapAction(tester, 'edit');

      bloc.show(const UpdateProfileError('SocketException: no route'));
      await tester.pumpAndSettle();
      expect(snackBarText(_en('something_went_wrong')), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);

      await clearSnackBars(tester);
      bloc.show(const UpdateProfileError('Email already in use'));
      await tester.pumpAndSettle();
      expect(snackBarText('Email already in use'), findsOneWidget);

      // Still editable so the user can correct and retry.
      expect(fields(tester).every((f) => f.enabled == true), isTrue);
    });
  });

  // ───────────────────────── FilesTab ─────────────────────────
  group('FilesTab', () {
    late RecordingUpdateProfileBloc bloc;

    Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
      useTallScreen(tester);
      bloc = RecordingUpdateProfileBloc();
      await tester.pumpWidget(
        localizedApp(
          BlocProvider<UpdateProfileBloc>.value(
            value: bloc,
            child: const FilesTab(vendor: VendorModel(id: 'v1')),
          ),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
    }

    Iterable<TextButton> chooseButtons(WidgetTester tester) =>
        tester.widgetList<TextButton>(find.byType(TextButton));

    testWidgets('file selection is disabled until Edit is pressed', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text(_en('file_choose')), findsNWidgets(3));
      expect(chooseButtons(tester).every((b) => b.onPressed == null), isTrue);

      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();
      expect(chooseButtons(tester).every((b) => b.onPressed != null), isTrue);
    });

    testWidgets('Cancel leaves edit mode without any request', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en('cancel')));
      await tester.pumpAndSettle();

      expect(find.text(_en('edit_label')), findsOneWidget);
      expect(bloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    testWidgets('Save submits for the vendor id; loading blocks Cancel', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en('save_files')));
      await tester.pumpAndSettle();

      expect(bloc.of<SubmitUpdateProfileEvent>().single.request.userId, 'v1');

      bloc.show(const UpdateProfileLoading());
      await _settle(tester);
      final cancel = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, _en('cancel')),
      );
      expect(cancel.onPressed, isNull);
      expect(chooseButtons(tester).every((b) => b.onPressed == null), isTrue);
    });

    for (final locale in ['en', 'ar']) {
      testWidgets('success message is localized ($locale) and exits edit', (
        tester,
      ) async {
        await pump(tester, locale: locale);
        await tester.tap(find.text(kTranslations[locale]!['edit_label']!));
        await tester.pumpAndSettle();

        bloc.show(const UpdateProfileSuccess('profile_updated_successfully'));
        await tester.pumpAndSettle();

        expect(
          snackBarText(kTranslations[locale]!['profile_updated_successfully']!),
          findsOneWidget,
        );
        expect(
          find.text(kTranslations[locale]!['edit_label']!),
          findsOneWidget,
        );
      });
    }

    testWidgets('failure keeps edit mode and shows a safe message', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();

      bloc.show(const UpdateProfileError('profile_update_failed'));
      await tester.pumpAndSettle();

      expect(snackBarText(_en('profile_update_failed')), findsOneWidget);
      expect(find.text(_en('save_files')), findsOneWidget);
    });
  });

  // ───────────────────────── LocationTab ─────────────────────────
  group('LocationTab', () {
    late RecordingUpdateProfileBloc bloc;

    Future<void> pump(
      WidgetTester tester, {
      VendorModel vendor = _vendor,
      String locale = 'en',
    }) async {
      useTallScreen(tester);
      bloc = RecordingUpdateProfileBloc();
      await tester.pumpWidget(
        localizedApp(
          BlocProvider<UpdateProfileBloc>.value(
            value: bloc,
            child: LocationTab(vendor: vendor),
          ),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder distanceField() => find.byType(TextFormField).last;

    testWidgets('shows the current location data read-only', (tester) async {
      await pump(tester);
      expect(find.text('30.5'), findsOneWidget);
      expect(find.text('31.25'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(tester.widget<TextFormField>(distanceField()).enabled, isFalse);
    });

    testWidgets('save sends coordinates and a numeric service distance', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();
      await tester.enterText(distanceField(), '20');
      await tester.tap(find.text(_en('save_location')));
      await tester.pumpAndSettle();

      final request = bloc.of<SubmitUpdateProfileEvent>().single.request;
      expect(request.userId, 'v1');
      expect(request.fields['latitude'], '30.5');
      expect(request.fields['longitude'], '31.25');
      expect(request.fields['serviceDistance'], isA<double>());
      expect(request.fields['serviceDistance'], 20.0);
      expect(request.fields['servingTheEntireArea'], true);
    });

    testWidgets('service distance above 50 is rejected by the input', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();
      await tester.enterText(distanceField(), '30');
      await tester.enterText(distanceField(), '99');
      expect(
        tester.widget<TextFormField>(distanceField()).controller!.text,
        '30',
      );
    });

    testWidgets('missing coordinates blocks the save with a localized hint', (
      tester,
    ) async {
      await pump(
        tester,
        vendor: const VendorModel(id: 'v1'),
        locale: 'ar',
      );
      await tester.tap(find.text(_ar('edit_label')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_ar('save_location')));
      await tester.pumpAndSettle();

      expect(snackBarText(_ar('location_is_required')), findsOneWidget);
      expect(bloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    testWidgets('Cancel restores the original values', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();
      await tester.enterText(distanceField(), '40');
      await tester.tap(find.text(_en('cancel')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextFormField>(distanceField()).controller!.text,
        '12.5',
      );
      expect(bloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    testWidgets('loading prevents Cancel and a second save', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_en('edit_label')));
      await tester.pumpAndSettle();

      bloc.show(const UpdateProfileLoading());
      await _settle(tester);

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, _en('cancel')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(GradientButton));
      await _settle(tester);
      expect(bloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    testWidgets('success and failure messages are localized', (tester) async {
      await pump(tester, locale: 'ar');
      await tester.tap(find.text(_ar('edit_label')));
      await tester.pumpAndSettle();

      bloc.show(const UpdateProfileError('Exception: boom'));
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('something_went_wrong')), findsOneWidget);
      // Failure keeps edit mode.
      expect(find.text(_ar('save_location')), findsOneWidget);

      await clearSnackBars(tester);
      bloc.show(const UpdateProfileSuccess('profile_updated_successfully'));
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('profile_updated_successfully')), findsOneWidget);
      expect(find.text(_ar('edit_label')), findsOneWidget);
    });
  });

  // ───────────────────────── ChangePhoneTab ─────────────────────────
  group('ChangePhoneTab', () {
    late RecordingChangePhoneBloc bloc;

    Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
      useTallScreen(tester);
      bloc = RecordingChangePhoneBloc();
      await tester.pumpWidget(
        localizedApp(
          BlocProvider<ChangePhoneBloc>.value(
            value: bloc,
            child: const ChangePhoneTab(vendor: _vendor),
          ),
          locale: locale,
          onGenerateRoute: (settings) => settings.name == NamedRoutes.verifyOtp
              ? MaterialPageRoute(
                  settings: settings,
                  builder: (_) =>
                      Scaffold(body: Text('otp:${settings.arguments}')),
                )
              : null,
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder newPhone() => find.byType(TextFormField).last;
    Finder submit(String locale) =>
        find.text(kTranslations[locale]!['change_phone']!).last;

    testWidgets('shows the current phone, disabled', (tester) async {
      await pump(tester);
      expect(find.text('01012345678'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse,
      );
    });

    testWidgets('required and malformed phones are rejected', (tester) async {
      await pump(tester);

      await tester.tap(submit('en'));
      await tester.pumpAndSettle();
      expect(find.text(_en('phone_required')), findsOneWidget);

      await tester.enterText(newPhone(), '123');
      await tester.tap(submit('en'));
      await tester.pumpAndSettle();
      expect(find.text(_en('phone_invalid_length')), findsOneWidget);
      expect(bloc.of<SubmitChangePhoneEvent>(), isEmpty);
    });

    testWidgets('a valid phone is normalised and sent with the vendor id', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(newPhone(), '01099998888');
      await tester.tap(submit('en'));
      await tester.pumpAndSettle();

      final sent = bloc.of<SubmitChangePhoneEvent>().single;
      expect(sent.userId, 'v1');
      expect(sent.phone, '201099998888');
    });

    testWidgets('loading blocks a second submit', (tester) async {
      await pump(tester);
      await tester.enterText(newPhone(), '01099998888');
      bloc.show(const ChangePhoneLoading());
      await _settle(tester);

      expect(
        tester.widget<GradientButton>(find.byType(GradientButton)).loading,
        isTrue,
      );
      await tester.tap(find.byType(GradientButton));
      await _settle(tester);
      expect(bloc.of<SubmitChangePhoneEvent>(), isEmpty);
    });

    testWidgets('errors are localized / sanitised', (tester) async {
      await pump(tester, locale: 'ar');
      bloc.show(const ChangePhoneError('invalid_response'));
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('invalid_response')), findsOneWidget);

      await clearSnackBars(tester);
      bloc.show(const ChangePhoneError('DioException [connection error]'));
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('something_went_wrong')), findsOneWidget);
    });

    testWidgets('success is localized and opens OTP verification', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(newPhone(), '01099998888');
      bloc.show(const ChangePhoneSuccess(ChangePhoneResponse()));
      await tester.pumpAndSettle();

      expect(find.text('otp:201099998888'), findsOneWidget);
      expect(snackBarText(_en('phone_change_request_sent')), findsOneWidget);
    });
  });

  // ───────────────────────── ChangePasswordScreen ─────────────────────────
  group('ChangePasswordScreen', () {
    late RecordingChangePasswordBloc bloc;

    Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
      useTallScreen(tester);
      bloc = RecordingChangePasswordBloc();
      await tester.pumpWidget(
        localizedApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider<ChangePasswordBloc>.value(
                    value: bloc,
                    child: const ChangePasswordScreen(userId: 'v1'),
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

    Finder field(int i) => find.byType(TextFormField).at(i);

    Finder saveButton(String locale) =>
        find.text(kTranslations[locale]!['save_new_password']!);

    testWidgets('validates required, minimum length and confirmation', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(saveButton('en'));
      await tester.pumpAndSettle();
      expect(find.text(_en('field_required')), findsWidgets);

      await tester.enterText(field(0), 'oldpass123');
      await tester.enterText(field(1), 'short');
      await tester.enterText(field(2), 'short');
      await tester.tap(saveButton('en'));
      await tester.pumpAndSettle();
      expect(find.text(_en('minimum_8_characters')), findsWidgets);

      await tester.enterText(field(1), 'newpass1234');
      await tester.enterText(field(2), 'different123');
      await tester.tap(saveButton('en'));
      await tester.pumpAndSettle();
      expect(find.text(_en('passwords_dont_match')), findsOneWidget);
      expect(bloc.of<SubmitChangePasswordEvent>(), isEmpty);
    });

    testWidgets('a valid form submits for the vendor id', (tester) async {
      await pump(tester);
      await tester.enterText(field(0), 'oldpass123');
      await tester.enterText(field(1), 'newpass1234');
      await tester.enterText(field(2), 'newpass1234');
      await tester.tap(saveButton('en'));
      await tester.pumpAndSettle();

      final sent = bloc.of<SubmitChangePasswordEvent>().single;
      expect(sent.userId, 'v1');
      expect(sent.plainPassword, 'oldpass123');
      expect(sent.newPassword, 'newpass1234');
    });

    testWidgets('errors are localized and the screen stays open', (
      tester,
    ) async {
      await pump(tester, locale: 'ar');
      bloc.show(const ChangePasswordError('password_change_failed'));
      await tester.pumpAndSettle();

      expect(snackBarText(_ar('password_change_failed')), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('success shows the localized message and closes', (
      tester,
    ) async {
      await pump(tester);
      bloc.show(const ChangePasswordSuccess('password_changed_successfully'));
      await tester.pumpAndSettle();

      expect(
        snackBarText(_en('password_changed_successfully')),
        findsOneWidget,
      );
      expect(find.byType(ChangePasswordScreen), findsNothing);
    });

    testWidgets('Arabic labels exist for every field (no English fallback)', (
      tester,
    ) async {
      await pump(tester, locale: 'ar');
      for (final key in [
        'old_password',
        'new_password',
        'confirm_password',
        'save_new_password',
      ]) {
        expect(
          find.textContaining(_ar(key), findRichText: true),
          findsWidgets,
          reason: key,
        );
      }
    });
  });

  // ───────────────────────── BranchesTab ─────────────────────────
  group('BranchesTab', () {
    late RecordingBranchesBloc bloc;

    Future<void> pump(
      WidgetTester tester, {
      String locale = 'en',
      bool withUser = true,
    }) async {
      useTallScreen(tester);
      await initPrefs({
        if (withUser) CacheKeys.userModel: jsonEncode({'id': 'v1'}),
      });
      bloc = RecordingBranchesBloc();
      await tester.pumpWidget(
        localizedApp(
          BlocProvider<BranchesBloc>.value(
            value: bloc,
            child: const BranchesTab(),
          ),
          locale: locale,
        ),
      );
      await tester.pump();
    }

    testWidgets('loads the branches of the current user', (tester) async {
      await pump(tester);
      expect(bloc.events.single.toString(), contains('FetchBranchesEvent'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state', (tester) async {
      await pump(tester);
      bloc.show(const BranchesLoadedState([]));
      await tester.pumpAndSettle();
      expect(find.text(_en('no_branches_available')), findsOneWidget);
    });

    testWidgets('lists loaded branches', (tester) async {
      await pump(tester);
      bloc.show(
        const BranchesLoadedState([
          BranchModel(id: 'b1', name: 'Main', nameEn: '', address: 'A'),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Main'), findsOneWidget);
    });

    testWidgets('unknown user shows a localized message and no request', (
      tester,
    ) async {
      await pump(tester, locale: 'ar', withUser: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(snackBarText(_ar('current_user_not_identified')), findsOneWidget);
      expect(bloc.events, isEmpty);

      // Add Branch stays disabled while the user is unknown.
      final add = find.widgetWithText(FilledButton, _ar('add_branch'));
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
    });

    testWidgets('Add Branch is enabled for a known user', (tester) async {
      await pump(tester);
      final add = find.widgetWithText(FilledButton, _en('add_branch'));
      expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
    });

    testWidgets('errors are sanitised; successes are localized', (
      tester,
    ) async {
      await pump(tester, locale: 'ar');
      bloc.show(const BranchesErrorState('SocketException: x'));
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('something_went_wrong')), findsOneWidget);

      await clearSnackBars(tester);
      bloc.show(
        const BranchesActionSuccessState(
          message: 'branch_deleted_successfully',
          branches: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('branch_deleted_successfully')), findsOneWidget);
    });
  });

  // ───────────────────────── SectorsTab ─────────────────────────
  group('SectorsTab', () {
    late RecordingSectorsBloc bloc;

    Future<void> pump(
      WidgetTester tester, {
      VendorModel vendor = const VendorModel(id: 'v1'),
      String locale = 'en',
    }) async {
      useTallScreen(tester);
      bloc = RecordingSectorsBloc();
      await tester.pumpWidget(
        localizedApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<SectorsBloc>.value(value: bloc),
              BlocProvider<OnboardingCubit>(create: (_) => OnboardingCubit()),
            ],
            child: SectorsTab(vendor: vendor),
          ),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows a localized empty state', (tester) async {
      await pump(tester, locale: 'ar');
      expect(find.text(_ar('no_sectors_available')), findsOneWidget);
    });

    testWidgets('lists the vendor sectors', (tester) async {
      await pump(
        tester,
        vendor: const VendorModel(
          id: 'v1',
          sectors: [VendorSectorModel(id: 's1', name: 'Food', note: 'Hot')],
        ),
      );
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Hot'), findsOneWidget);
    });

    testWidgets('success and error messages are localized', (tester) async {
      await pump(tester, locale: 'ar');

      bloc.show(const SectorsError(messageKey: 'sector_add_failed'));
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('sector_add_failed')), findsOneWidget);

      await clearSnackBars(tester);
      bloc.show(const SectorsError(messageKey: 'DioException: 500'));
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('something_went_wrong')), findsOneWidget);

      await clearSnackBars(tester);
      bloc.show(
        const SectorsActionSuccess(
          messageKey: 'sector_removed_successfully',
          sectors: [],
          assignedSectorIds: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(snackBarText(_ar('sector_removed_successfully')), findsOneWidget);
    });
  });
}
