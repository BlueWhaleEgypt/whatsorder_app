import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/orders/data/vendor_response.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_request.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';
import 'package:whats_order/features/settings/presentation/screens/store_profile_screen.dart';

import 'helpers/harness.dart';

const _vendor = VendorModel(
  id: 'v1',
  firstName: 'Ahmed',
  lastName: 'Ali',
  phone: '01012345678',
  email: 'a@b.com',
  city: 'Cairo',
  rate: 4.5,
  faceIdCard: 'face.jpg',
  storeName: 'Home Appliances',
  storeAbout: 'About my store',
  storePhoto: 'photo.jpg',
);

void main() {
  group('UpdateProfileRequest store fields', () {
    test('resends the vendor store fields when none are given', () {
      final r = UpdateProfileRequest.fromVendor(userId: 'v1', vendor: _vendor);
      expect(r.fields['storeName'], 'Home Appliances');
      expect(r.fields['storeAbout'], 'About my store');
      expect(r.fields.containsKey('storePhoto'), isFalse);
      expect(r.existingFileNames['storePhoto'], 'photo.jpg');
      expect(r.existingFileNames['faceIdCard'], 'face.jpg');
    });

    test('explicit values override the vendor ones', () {
      final r = UpdateProfileRequest.fromVendor(
        userId: 'v1',
        vendor: _vendor,
        storeName: 'New',
        storeAbout: 'New about',
      );
      expect(r.fields['storeName'], 'New');
      expect(r.fields['storeAbout'], 'New about');
    });

    test('a vendor without store data sends empty strings, no photo name', () {
      final r = UpdateProfileRequest.fromVendor(
        userId: 'v1',
        vendor: const VendorModel(id: 'v1'),
      );
      expect(r.fields['storeName'], '');
      expect(r.fields['storeAbout'], '');
      expect(r.existingFileNames.containsKey('storePhoto'), isFalse);
    });
  });

  group('StoreProfileScreen', () {
    late RecordingVendorBloc vendorBloc;
    late RecordingUpdateProfileBloc updateBloc;

    Future<void> open(
      WidgetTester tester, {
      VendorModel vendor = _vendor,
      bool verified = true,
    }) async {
      await initPrefs({
        CacheKeys.verificationStatus: verified ? 'Verified' : 'Pending',
      });
      useTallScreen(tester);
      vendorBloc = RecordingVendorBloc();
      updateBloc = RecordingUpdateProfileBloc();
      await tester.pumpWidget(
        localizedApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<VendorBloc>.value(value: vendorBloc),
              BlocProvider<UpdateProfileBloc>.value(value: updateBloc),
            ],
            child: const StoreProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      vendorBloc.show(
        VendorLoaded(vendorResponse: VendorResponse(vendor: vendor)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> startEditing(WidgetTester tester) async {
      final edit = find.text('EDIT');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
    }

    Future<void> tapSave(WidgetTester tester) async {
      final save = find.text('Save Changes');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
    }

    bool fieldsEnabled(WidgetTester tester) => tester
        .widgetList<AppTextField>(find.byType(AppTextField))
        .every((f) => f.enabled);

    testWidgets('requests the vendor and shows a spinner until it loads', (
      tester,
    ) async {
      await initPrefs();
      useTallScreen(tester);
      vendorBloc = RecordingVendorBloc();
      await tester.pumpWidget(
        localizedApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<VendorBloc>.value(value: vendorBloc),
              BlocProvider<UpdateProfileBloc>.value(
                value: RecordingUpdateProfileBloc(),
              ),
            ],
            child: const StoreProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AppTextField), findsNothing);
    });

    testWidgets('fields are read-only until Edit is pressed', (tester) async {
      await open(tester);

      expect(fieldsEnabled(tester), isFalse);
      expect(find.text('EDIT'), findsOneWidget);
      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Change'), findsNothing);

      await startEditing(tester);

      expect(fieldsEnabled(tester), isTrue);
      expect(find.text('EDIT'), findsNothing);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel discards the edits and goes back to read-only', (
      tester,
    ) async {
      await open(tester);
      await startEditing(tester);
      await tester.enterText(find.text('Home Appliances'), 'Changed');
      await tester.enterText(find.text('About my store'), 'Changed about');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Home Appliances'), findsOneWidget);
      expect(find.text('About my store'), findsOneWidget);
      expect(find.text('Changed'), findsNothing);
      expect(fieldsEnabled(tester), isFalse);
      expect(updateBloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    testWidgets('while saving the buttons are locked (no duplicate submit)', (
      tester,
    ) async {
      await open(tester);
      await startEditing(tester);

      updateBloc.show(const UpdateProfileLoading());
      await tester.pump();
      await tester.pump();

      expect(fieldsEnabled(tester), isFalse);
      final cancel = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Cancel'),
      );
      expect(cancel.onPressed, isNull);

      await tester.tap(find.byType(GradientButton), warnIfMissed: false);
      await tester.pump();
      expect(updateBloc.of<SubmitUpdateProfileEvent>(), isEmpty);
    });

    testWidgets('shows the store name, about and rating', (tester) async {
      await open(tester);

      expect(find.text('Home Appliances'), findsOneWidget);
      expect(find.text('About my store'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
    });

    testWidgets('a missing rate shows 0.0', (tester) async {
      await open(
        tester,
        vendor: const VendorModel(id: 'v1', storeName: 'S'),
      );
      expect(find.text('0.0'), findsOneWidget);
    });

    testWidgets('save sends the edits through update profile', (tester) async {
      await open(tester);
      await startEditing(tester);

      await tester.enterText(find.text('Home Appliances'), 'New Name');
      await tester.enterText(find.text('About my store'), 'New about');
      await tapSave(tester);

      final events = updateBloc.of<SubmitUpdateProfileEvent>();
      expect(events, hasLength(1));
      final r = events.single.request;
      expect(r.userId, 'v1');
      expect(r.fields['storeName'], 'New Name');
      expect(r.fields['storeAbout'], 'New about');
      // Other profile data is resent unchanged.
      expect(r.fields['firstName'], 'Ahmed');
      expect(r.fields['city'], 'Cairo');
      expect(r.existingFileNames['storePhoto'], 'photo.jpg');
      expect(r.files, isEmpty);
    });

    testWidgets('an empty store name blocks the save', (tester) async {
      await open(tester);
      await startEditing(tester);

      await tester.enterText(find.text('Home Appliances'), '');
      await tapSave(tester);

      expect(updateBloc.of<SubmitUpdateProfileEvent>(), isEmpty);
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('a successful save shows a message and reloads the vendor', (
      tester,
    ) async {
      await open(tester);
      await startEditing(tester);
      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(1));

      updateBloc.show(
        const UpdateProfileSuccess('profile_updated_successfully'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Changes saved'), findsOneWidget);
      expect(find.text('EDIT'), findsOneWidget); // back to read-only
      expect(fieldsEnabled(tester), isFalse);
      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(2));
    });

    testWidgets('a failed save shows the error and keeps the form', (
      tester,
    ) async {
      await open(tester);
      await startEditing(tester);
      await tester.enterText(find.text('Home Appliances'), 'Edited');

      updateBloc.show(const UpdateProfileError('no_internet'));
      await tester.pumpAndSettle();

      expect(find.text('Edited'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget); // still editing
      expect(fieldsEnabled(tester), isTrue);
      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(1));
    });

    testWidgets('a failed load offers a retry', (tester) async {
      await initPrefs();
      useTallScreen(tester);
      vendorBloc = RecordingVendorBloc();
      await tester.pumpWidget(
        localizedApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<VendorBloc>.value(value: vendorBloc),
              BlocProvider<UpdateProfileBloc>.value(
                value: RecordingUpdateProfileBloc(),
              ),
            ],
            child: const StoreProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      vendorBloc.show(const VendorError(message: 'no_internet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(vendorBloc.of<FetchVendorEvent>(), hasLength(2));
    });

    testWidgets('an unverified vendor is asked to verify before the photo', (
      tester,
    ) async {
      await open(tester, verified: false);
      await startEditing(tester);

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(
        find.text('You need to verify your account to change the store photo.'),
        findsOneWidget,
      );
      expect(find.text('Verify account'), findsOneWidget);
    });
  });
}
