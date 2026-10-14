import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/features/settings/presentation/screens/settings_screen.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_confirmation_dialog.dart';

import 'helpers/harness.dart';

void main() {
  Future<void> pump(WidgetTester tester, String locale) async {
    await initPrefs({
      CacheKeys.userModel: '{"id":"v1"}',
      CacheKeys.accessToken: 'access',
      CacheKeys.refreshToken: 'refresh',
      CacheKeys.firstName: 'Ahmed',
    });
    ProfileName.fullName.value = 'Ahmed';
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

  for (final locale in ['en', 'ar']) {
    group('logout dialog ($locale)', () {
      final t = kTranslations[locale]!;

      testWidgets('uses the shared confirmation dialog with localized text', (
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
        // Title and confirm button both read "logout".
        expect(
          find.descendant(of: dialog, matching: find.text(t['logout']!)),
          findsNWidgets(2),
        );
      });

      testWidgets('shows no icon badge or button icon', (tester) async {
        await pump(tester, locale);
        await openDialog(tester, locale);

        expect(
          find.descendant(
            of: find.byType(SettingsConfirmationDialog),
            matching: find.byType(SvgPicture),
          ),
          findsNothing,
        );
      });

      testWidgets('cancel keeps the session', (tester) async {
        await pump(tester, locale);
        await openDialog(tester, locale);
        await tester.tap(find.text(t['cancel']!));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsConfirmationDialog), findsNothing);
        expect(
          CacheHelper.getDataFromSharedPreference(key: CacheKeys.accessToken),
          'access',
        );
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('barrier dismissal keeps the session', (tester) async {
        await pump(tester, locale);
        await openDialog(tester, locale);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsConfirmationDialog), findsNothing);
        expect(
          CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel),
          isNotNull,
        );
      });

      testWidgets('confirm clears the session and opens sign-in', (
        tester,
      ) async {
        await pump(tester, locale);
        await openDialog(tester, locale);
        await tester.tap(
          find.descendant(
            of: find.byType(SettingsConfirmationDialog),
            matching: find.widgetWithText(ElevatedButton, t['logout']!),
          ),
        );
        await tester.pumpAndSettle();

        for (final key in [
          CacheKeys.userModel,
          CacheKeys.accessToken,
          CacheKeys.refreshToken,
          CacheKeys.firstName,
        ]) {
          expect(
            CacheHelper.getDataFromSharedPreference(key: key),
            isNull,
            reason: key,
          );
        }
        expect(ProfileName.fullName.value, '');
        expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
        expect(find.byType(SettingsScreen), findsNothing);
      });
    });
  }
}
