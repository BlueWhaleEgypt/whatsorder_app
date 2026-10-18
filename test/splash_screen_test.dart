import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/features/general_screens/splash_screen.dart';

import 'helpers/harness.dart';

void main() {
  Future<void> pump(WidgetTester tester, Map<String, Object> prefs) async {
    await initPrefs(prefs);
    await tester.pumpWidget(
      localizedApp(
        const SplashScreen(),
        onGenerateRoute: (s) => MaterialPageRoute(
          settings: s,
          builder: (_) => Scaffold(body: Text('route:${s.name}')),
        ),
      ),
    );
    // Localization delegates load asynchronously; build the first real frame.
    await tester.pump();
  }

  testWidgets('shows the brand and waits two seconds before navigating', (
    tester,
  ) async {
    await pump(tester, {});
    expect(find.text('WhatsOrder'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('WhatsOrder'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
  });

  testWidgets('a stored token goes home', (tester) async {
    await pump(tester, {CacheKeys.accessToken: 'tok'});
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('route:${NamedRoutes.home}'), findsOneWidget);
  });

  testWidgets('an empty token goes to sign in', (tester) async {
    await pump(tester, {CacheKeys.accessToken: ''});
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('route:${NamedRoutes.signin}'), findsOneWidget);
  });

  testWidgets('leaving before the delay ends does not navigate or throw', (
    tester,
  ) async {
    await pump(tester, {});
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a small screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(240, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester, {});
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
