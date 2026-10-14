import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/features/orders/data/order_model.dart';
import 'package:whats_order/features/orders/data/orders_response.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/orders/data/vendor_response.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_state.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/orders/presentation/screens/home_screen.dart';
import 'package:whats_order/features/orders/presentation/screens/order_details_screen.dart';
import 'package:whats_order/features/orders/presentation/screens/widgets/order_search_delegate.dart';

import 'helpers/harness.dart';

String _en(String key) => kTranslations['en']![key]!;

void main() {
  late RecordingOrdersBloc ordersBloc;
  late RecordingVendorBloc vendorBloc;

  setUp(() async {
    await initPrefs();
    ProfileName.firstName.value = 'Ahmed';
    NotificationCounter.notificationCount.value = 0;
    NotificationCounter.smsCount.value = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    useTallScreen(tester);
    ordersBloc = RecordingOrdersBloc();
    vendorBloc = RecordingVendorBloc();
    await tester.pumpWidget(
      // Providers sit *inside* the app's Navigator, like MainShell's do, so
      // routes pushed on it (search page, details) cannot see them.
      localizedApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<OrdersBloc>.value(value: ordersBloc),
            BlocProvider<VendorBloc>.value(value: vendorBloc),
          ],
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> showVendor(WidgetTester tester, VendorModel vendor) async {
    vendorBloc.show(
      VendorLoaded(vendorResponse: VendorResponse(vendor: vendor)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('welcome card greets with the profile first name', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('${_en('welcome')} Ahmed'), findsOneWidget);
    expect(find.text(_en('welcome_subtitle')), findsOneWidget);

    ProfileName.firstName.value = 'Omar';
    await tester.pump();
    expect(find.text('${_en('welcome')} Omar'), findsOneWidget);
  });

  testWidgets('verification chip follows the vendor status', (tester) async {
    await pump(tester);
    expect(find.text(_en('account_verified')), findsNothing);
    expect(find.text(_en('account_not_verified')), findsNothing);

    await showVendor(
      tester,
      const VendorModel(id: 'v', verificationStatus: 'Verified'),
    );
    expect(find.text(_en('account_verified')), findsOneWidget);

    await showVendor(
      tester,
      const VendorModel(id: 'v', verificationStatus: 'Pending'),
    );
    expect(find.text(_en('account_not_verified')), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
  });

  testWidgets('inactive banner appears only when activation is false', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(_en('account_inactive_banner')), findsNothing);

    await showVendor(tester, const VendorModel(id: 'v', activation: true));
    expect(find.text(_en('account_inactive_banner')), findsNothing);

    await showVendor(tester, const VendorModel(id: 'v'));
    expect(find.text(_en('account_inactive_banner')), findsNothing);

    await showVendor(tester, const VendorModel(id: 'v', activation: false));
    expect(find.text(_en('account_inactive_banner')), findsOneWidget);
  });

  testWidgets('notification and SMS badges show counts, capped at 9+', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('3'), findsNothing);

    NotificationCounter.notificationCount.value = 3;
    NotificationCounter.smsCount.value = 12;
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('search is disabled until orders are loaded', (tester) async {
    await pump(tester);
    IconButton search() =>
        tester.widget<IconButton>(find.byType(IconButton).first);
    expect(search().onPressed, isNull);

    ordersBloc.show(LoadedOrdersState(const OrdersResponse(orders: [])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(search().onPressed, isNotNull);
  });

  testWidgets('export without selected orders shows the hint', (tester) async {
    await pump(tester);
    ordersBloc.show(
      LoadedOrdersState(
        const OrdersResponse(
          orders: [OrderModel(id: '1', orderId: 11, isChecked: false)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en('export')));
    await tester.pumpAndSettle();
    expect(snackBarText(_en('select_at_least_one_order')), findsOneWidget);
  });

  testWidgets('pull to refresh asks for orders and vendor once', (
    tester,
  ) async {
    await pump(tester);
    ordersBloc.show(LoadedOrdersState(const OrdersResponse(orders: [])));
    await tester.pumpAndSettle();

    final refresh = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    refresh.show();
    await tester.pump();
    // The refresh completes once orders leave the loading state.
    ordersBloc.show(ErrorOrdersState(message: 'x'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(ordersBloc.events.whereType<FetchOrdersEvent>(), hasLength(1));
    expect(vendorBloc.events.whereType<FetchVendorEvent>(), hasLength(1));
  });

  group('search result -> order details', () {
    const order = OrderModel(
      id: 'o-1',
      orderId: 1001,
      latitude: null,
      longitude: null,
      components: 'Two chairs',
      createdDate: 'today',
    );

    Future<void> openDetails(WidgetTester tester) async {
      await initPrefs({
        CacheKeys.userModel: jsonEncode({'id': 'vendor-9'}),
      });
      await pump(tester);
      ordersBloc.show(LoadedOrdersState(const OrdersResponse(orders: [order])));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).first); // search
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1001');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
    }

    testWidgets('opens details without ProviderNotFound and marks viewed', (
      tester,
    ) async {
      await openDetails(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      expect(find.text('Two chairs'), findsOneWidget);

      final views = ordersBloc.events.whereType<ViewOrderEvent>().toList();
      expect(views, hasLength(1));
      expect(views.single.orderId, 'o-1');

      final details = tester.widget<OrderDetailsScreen>(
        find.byType(OrderDetailsScreen),
      );
      expect(details.orderId, 1001);
      expect(details.userId, 'vendor-9');
      expect(details.latitude, isNull);
      expect(details.components, 'Two chairs');
    });

    testWidgets('make offer from there goes to the same bloc', (tester) async {
      await openDetails(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(OrderDetailsScreen),
          matching: find.byType(TextFormField),
        ),
        'Good price for you',
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en('30_minutes')).last);
      await tester.pumpAndSettle();
      final button = find.text(_en('make_offer'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      final offer = ordersBloc.offers.single;
      expect(offer.orderId, 1001);
      expect(offer.userId, 'vendor-9');
    });
  });

  group('OrderSearchDelegate', () {
    const orders = [
      OrderModel(id: '1', orderId: 1001, createdDate: 'today'),
      OrderModel(id: '2', orderId: 2002),
    ];

    test('filters by order number, empty query returns nothing', () {
      final delegate = OrderSearchDelegate(
        orders,
        ordersBloc: RecordingOrdersBloc(),
      );
      expect(delegate.filteredOrders, isEmpty);

      delegate.query = '200';
      expect(delegate.filteredOrders.map((o) => o.orderId), [2002]);

      delegate.query = '  ';
      expect(delegate.filteredOrders, isEmpty);
    });
  });
}
