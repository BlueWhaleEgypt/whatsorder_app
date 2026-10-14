import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/features/settings/presentation/screens/settings_screen.dart';

Widget _app(LocaleCubit cubit) {
  return BlocProvider.value(
    value: cubit,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: SettingsScreen(),
    ),
  );
}

void main() {
  late LocaleCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    ProfileName.fullName.value = 'Ahmed Ali';
    cubit = LocaleCubit();
  });

  tearDown(() => cubit.close());

  testWidgets('renders sections and labels', (tester) async {
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    for (final key in [
      'preferences',
      'branches',
      'language',
      'notifications',
      'account',
      'terms_conditions',
      'help_center',
      'logout',
    ]) {
      final ctx = tester.element(find.byType(SettingsScreen));
      expect(find.text(ctx.tr(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('profile header follows ProfileName.fullName', (tester) async {
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Ali'), findsOneWidget);

    ProfileName.fullName.value = 'Sara Hassan';
    await tester.pump();

    expect(find.text('Sara Hassan'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsNothing);
  });

  testWidgets('language dialog toggles the locale', (tester) async {
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(SettingsScreen));

    await tester.tap(find.text(ctx.tr('language')));
    await tester.pumpAndSettle();
    expect(find.text('العربية'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('English'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(cubit.state.languageCode, 'ar');
    expect(find.text('العربية'), findsNothing);
  });

  testWidgets('selecting the active language keeps it; indicator follows', (
    tester,
  ) async {
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(SettingsScreen));

    Finder checkIn(String label) => find.descendant(
      of: find.ancestor(
        of: find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(label),
        ),
        matching: find.byType(InkWell),
      ),
      matching: find.byIcon(Icons.check_circle),
    );

    // English is active: it is marked, Arabic is not.
    await tester.tap(find.text(ctx.tr('language')));
    await tester.pumpAndSettle();
    expect(checkIn('English'), findsOneWidget);
    expect(checkIn('العربية'), findsNothing);

    // Tapping the active language must not switch.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('English'),
      ),
    );
    await tester.pumpAndSettle();
    expect(cubit.state.languageCode, 'en');

    // Switch to Arabic, then the indicator moves.
    await tester.tap(find.text(ctx.tr('language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(cubit.state.languageCode, 'ar');

    await tester.tap(find.text(ctx.tr('language')));
    await tester.pumpAndSettle();
    expect(checkIn('العربية'), findsOneWidget);
    expect(checkIn('English'), findsNothing);
  });

  testWidgets('logout dialog shows and can be dismissed', (tester) async {
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(SettingsScreen));

    await tester.scrollUntilVisible(find.text(ctx.tr('logout')), 100);
    await tester.tap(find.text(ctx.tr('logout')));
    await tester.pumpAndSettle();

    expect(find.text(ctx.tr('logout_msg')), findsOneWidget);

    await tester.tap(find.text(ctx.tr('cancel')));
    await tester.pumpAndSettle();

    expect(find.text(ctx.tr('logout_msg')), findsNothing);
  });
}
