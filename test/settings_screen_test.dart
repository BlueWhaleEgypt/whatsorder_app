import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/cache/session_cleaner.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/features/settings/presentation/bloc/logout_bloc.dart';
import 'package:whats_order/features/settings/presentation/screens/settings_screen.dart';
import 'package:whats_order/injection/injection_container.dart';

import 'helpers/harness.dart';

void main() {
  late LocaleCubit cubit;

  Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      BlocProvider<LocaleCubit>.value(
        value: cubit,
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

  setUp(() async {
    await initPrefs({CacheKeys.firstName: 'Ahmed'});
    ProfileName.fullName.value = 'Ahmed Ali';
    cubit = LocaleCubit();

    if (sl.isRegistered<LogoutBloc>()) sl.unregister<LogoutBloc>();
    sl.registerFactory(
      () => LogoutBloc(FakeNetwork(), const LocalSessionCleaner()),
    );
  });

  tearDown(() async {
    await cubit.close();
    if (sl.isRegistered<LogoutBloc>()) sl.unregister<LogoutBloc>();
  });

  for (final locale in ['en', 'ar']) {
    testWidgets('renders every section and tile ($locale)', (tester) async {
      await pump(tester, locale: locale);
      final t = kTranslations[locale]!;

      for (final key in [
        'settings',
        'preferences',
        'branches',
        'language',
        'notifications',
        'account',
        'terms_conditions',
        'help_center',
        'logout',
        'edit_profile',
      ]) {
        expect(find.text(t[key]!), findsOneWidget, reason: key);
      }
      expect(find.text('Ahmed Ali'), findsOneWidget);
    });
  }

  testWidgets('provides its own LogoutBloc to the tree', (tester) async {
    await pump(tester);

    final bloc = BlocProvider.of<LogoutBloc>(
      tester.element(find.text('Ahmed Ali')),
    );
    expect(bloc, isA<LogoutBloc>());
  });

  testWidgets('does not show a spinner or send logout until confirmed', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final bloc = BlocProvider.of<LogoutBloc>(
      tester.element(find.text('Ahmed Ali')),
    );
    expect(bloc.state.runtimeType.toString(), 'LogoutInitial');
  });

  testWidgets('profile header follows ProfileName.fullName', (tester) async {
    await pump(tester);
    expect(find.text('Ahmed Ali'), findsOneWidget);

    ProfileName.fullName.value = 'Sara Hassan';
    await tester.pump();

    expect(find.text('Sara Hassan'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsNothing);
  });

  testWidgets('profile header opens the profile route', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Ahmed Ali'));
    await tester.pumpAndSettle();

    expect(find.text('route:${NamedRoutes.profile}'), findsOneWidget);
  });

  testWidgets('branches tile opens the branches route', (tester) async {
    await pump(tester);
    await tester.tap(find.text(kTranslations['en']!['branches']!));
    await tester.pumpAndSettle();

    expect(find.text('route:${NamedRoutes.branches}'), findsOneWidget);
  });

  testWidgets('notifications tile opens the notification route', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(kTranslations['en']!['notifications']!));
    await tester.pumpAndSettle();

    expect(find.text('route:${NamedRoutes.notification}'), findsOneWidget);
  });

  testWidgets('language tile opens a dialog that switches the locale', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text(kTranslations['en']!['language']!));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(cubit.state.languageCode, 'ar');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('logout tile opens the confirmation and cancel dismisses it', (
    tester,
  ) async {
    await pump(tester);
    final t = kTranslations['en']!;

    await tester.tap(find.text(t['logout']!));
    await tester.pumpAndSettle();
    expect(find.text(t['logout_msg']!), findsOneWidget);

    await tester.tap(find.text(t['cancel']!));
    await tester.pumpAndSettle();

    expect(find.text(t['logout_msg']!), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
