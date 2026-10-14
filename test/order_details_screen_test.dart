import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_state.dart';
import 'package:whats_order/features/orders/presentation/screens/order_details_screen.dart';

import 'helpers/harness.dart';

String _tr(String locale, String key) => kTranslations[locale]![key]!;

/// Controllable stand-in for the platform geocoder (no channel, no network).
class _FakeGeocoding extends GeocodingPlatform with MockPlatformInterfaceMixin {
  Completer<List<Placemark>>? pending;
  List<Placemark> result = const [];
  Object? error;
  final calls = <(double, double)>[];

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    String? localeIdentifier,
  }) {
    calls.add((latitude, longitude));
    if (pending != null) return pending!.future;
    if (error != null) return Future.error(error!);
    return Future.value(result);
  }
}

void main() {
  late RecordingOrdersBloc bloc;
  late _FakeGeocoding geocoding;

  setUp(() {
    geocoding = _FakeGeocoding();
    GeocodingPlatform.instance = geocoding;
  });

  Future<void> pump(
    WidgetTester tester, {
    String locale = 'en',
    double? latitude = 30.0,
    double? longitude = 31.0,
    String? components = 'Two chairs and a table',
  }) async {
    useTallScreen(tester);
    bloc = RecordingOrdersBloc();
    await tester.pumpWidget(
      localizedApp(
        BlocProvider<OrdersBloc>.value(
          value: bloc,
          child: OrderDetailsScreen(
            orderId: 42,
            userId: 'u-1',
            latitude: latitude,
            longitude: longitude,
            components: components,
          ),
        ),
        locale: locale,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder offerField() => find.byType(TextFormField).first;

  Future<void> chooseTime(
    WidgetTester tester,
    String locale,
    String key,
  ) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_tr(locale, key)).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapMakeOffer(WidgetTester tester, String locale) async {
    final button = find.text(_tr(locale, 'make_offer'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('rendering', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('shows summary, location, offer field and time ($locale)', (
        tester,
      ) async {
        geocoding.result = const [
          Placemark(street: 'Nile St', locality: 'Giza'),
        ];
        await pump(tester, locale: locale);
        final t = kTranslations[locale]!;

        expect(find.text('Two chairs and a table'), findsOneWidget);
        expect(find.textContaining('#42'), findsOneWidget);
        expect(find.text(t['location']!), findsOneWidget);
        expect(find.text('Nile St, Giza'), findsOneWidget);
        expect(find.text(t['open_map']!), findsOneWidget);
        expect(
          find.textContaining(
            t['offer_details']!.toUpperCase(),
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(find.text(t['write_your_offer']!), findsOneWidget);
        expect(find.text(t['make_offer']!), findsOneWidget);
      });
    }

    testWidgets('long descriptions and ids do not overflow', (tester) async {
      geocoding.result = const [Placemark(street: 'x')];
      await pump(
        tester,
        components: List.filled(60, 'a very long order description').join(' '),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('all five execution times are offered', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      for (final key in [
        '15_minutes',
        '30_minutes',
        '45_minutes',
        '1_hour',
        '2_hours',
      ]) {
        expect(find.text(_tr('en', key)), findsWidgets, reason: key);
      }
    });
  });

  group('location', () {
    testWidgets('shows a loading state while the address resolves', (
      tester,
    ) async {
      geocoding.pending = Completer();
      await pump(tester);

      expect(find.text(_tr('en', 'loading_location')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      geocoding.pending!.complete(const [Placemark(street: 'Late St')]);
      await tester.pumpAndSettle();
      expect(find.text('Late St'), findsOneWidget);
      expect(find.text(_tr('en', 'loading_location')), findsNothing);
    });

    testWidgets('trims and de-duplicates address parts', (tester) async {
      geocoding.result = const [
        Placemark(
          street: ' Main St ',
          subLocality: '',
          locality: 'Cairo',
          administrativeArea: 'Cairo',
          country: null,
        ),
      ];
      await pump(tester);
      expect(find.text('Main St, Cairo'), findsOneWidget);
    });

    testWidgets('a failed lookup falls back and stops loading', (tester) async {
      geocoding.error = Exception('platform down');
      await pump(tester);

      expect(find.text(_tr('en', 'unknown_location')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('platform down'), findsNothing);
    });

    testWidgets('an empty lookup falls back', (tester) async {
      geocoding.result = const [Placemark(street: '', locality: '  ')];
      await pump(tester);
      expect(find.text(_tr('ar', 'unknown_location')), findsNothing);
      expect(find.text(_tr('en', 'unknown_location')), findsOneWidget);
    });

    testWidgets('missing coordinates: no lookup, no crash, map disabled', (
      tester,
    ) async {
      await pump(tester, latitude: null, longitude: null);

      expect(geocoding.calls, isEmpty);
      expect(find.text(_tr('en', 'unknown_location')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final map = find.widgetWithText(OutlinedButton, _tr('en', 'open_map'));
      expect(tester.widget<OutlinedButton>(map).onPressed, isNull);
    });

    testWidgets('only one coordinate is also treated as missing', (
      tester,
    ) async {
      await pump(tester, longitude: null);
      expect(geocoding.calls, isEmpty);
    });

    testWidgets(
      'with coordinates the lookup gets them and the map is enabled',
      (tester) async {
        geocoding.result = const [Placemark(street: 'S')];
        await pump(tester);

        expect(geocoding.calls.single, (30.0, 31.0));
        final map = find.widgetWithText(OutlinedButton, _tr('en', 'open_map'));
        expect(tester.widget<OutlinedButton>(map).onPressed, isNotNull);
      },
    );

    testWidgets('leaving the screen before the lookup ends is safe', (
      tester,
    ) async {
      geocoding.pending = Completer();
      await pump(tester);
      await tester.pumpWidget(const SizedBox());
      geocoding.pending!.complete(const [Placemark(street: 'x')]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('validation and submission', () {
    testWidgets('empty fields are reported and nothing is sent', (
      tester,
    ) async {
      geocoding.result = const [Placemark(street: 'x')];
      await pump(tester);
      await tapMakeOffer(tester, 'en');

      expect(
        find.text(_tr('en', 'please_enter_offer_details')),
        findsOneWidget,
      );
      expect(
        find.text(_tr('en', 'please_select_execution_time')),
        findsOneWidget,
      );
      expect(bloc.offers, isEmpty);
    });

    testWidgets('details shorter than five characters are rejected', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(offerField(), '  abcd  ');
      await chooseTime(tester, 'en', '30_minutes');
      await tapMakeOffer(tester, 'en');

      expect(find.text(_tr('en', 'offer_details_too_short')), findsOneWidget);
      expect(bloc.offers, isEmpty);
    });

    testWidgets('a missing execution time blocks the offer', (tester) async {
      await pump(tester);
      await tester.enterText(offerField(), 'Good price for you');
      await tapMakeOffer(tester, 'en');

      expect(
        find.text(_tr('en', 'please_select_execution_time')),
        findsOneWidget,
      );
      expect(bloc.offers, isEmpty);
    });

    testWidgets('sends the existing payload with the English time', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(offerField(), '  Good price for you  ');
      await chooseTime(tester, 'en', '30_minutes');
      await tapMakeOffer(tester, 'en');

      final offer = bloc.offers.single;
      expect(offer.orderId, 42);
      expect(offer.userId, 'u-1');
      expect(offer.offerDetails, 'Good price for you\nمدة التنفيذ: 30 minutes');
    });

    testWidgets('sends the Arabic time label under the Arabic locale', (
      tester,
    ) async {
      await pump(tester, locale: 'ar');
      await tester.enterText(offerField(), 'عرض مناسب جدا');
      await chooseTime(tester, 'ar', '1_hour');
      await tapMakeOffer(tester, 'ar');

      expect(
        bloc.offers.single.offerDetails,
        'عرض مناسب جدا\nمدة التنفيذ: ${_tr('ar', '1_hour')}',
      );
    });

    testWidgets('loading blocks duplicate submissions', (tester) async {
      await pump(tester);
      await tester.enterText(offerField(), 'Good price for you');
      await chooseTime(tester, 'en', '30_minutes');

      bloc.show(MakeOfferLoadingState());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.widget<GradientButton>(find.byType(GradientButton)).loading,
        isTrue,
      );
      await tester.tap(find.byType(GradientButton), warnIfMissed: false);
      await tester.pump();
      expect(bloc.offers, isEmpty);

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.onChanged, isNull);
    });
  });

  group('feedback', () {
    testWidgets('success shows the localized message and closes', (
      tester,
    ) async {
      useTallScreen(tester);
      bloc = RecordingOrdersBloc();
      await tester.pumpWidget(
        localizedApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider<OrdersBloc>.value(
                    value: bloc,
                    child: const OrderDetailsScreen(
                      orderId: 1,
                      userId: 'u',
                      latitude: null,
                      longitude: null,
                      components: null,
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
          locale: 'ar',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      bloc.show(MakeOfferSuccessState());
      await tester.pumpAndSettle();

      expect(
        snackBarText(_tr('ar', 'offer_sent_successfully')),
        findsOneWidget,
      );
      expect(find.byType(OrderDetailsScreen), findsNothing);
    });

    testWidgets('errors: server text kept, technical text hidden', (
      tester,
    ) async {
      await pump(tester);

      bloc.show(MakeOfferErrorState('Order already taken'));
      await tester.pumpAndSettle();
      expect(snackBarText('Order already taken'), findsOneWidget);

      await clearSnackBars(tester);
      bloc.show(MakeOfferErrorState('DioException: 500'));
      await tester.pumpAndSettle();
      expect(snackBarText(_tr('en', 'something_went_wrong')), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.byType(OrderDetailsScreen), findsOneWidget);
    });
  });
}
