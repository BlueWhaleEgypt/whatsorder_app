import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/utils/price_formatter.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/products_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/products_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/products_state.dart';
import 'package:whats_order/features/settings/presentation/screens/products_screen.dart';
import 'package:whats_order/features/settings/presentation/utils/products_listing.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/product_card.dart';
import 'package:whats_order/injection/injection_container.dart';

import 'helpers/harness.dart';

ProductModel _product(
  int i, {
  String sectorId = 's1',
  String sectorName = 'Supermarket',
  String? name,
  String note = '',
  double price = 10,
}) => ProductModel(
  id: 'p$i',
  name: name ?? 'Product $i',
  price: price,
  deliveryTime: '$i',
  note: note,
  sectorId: sectorId,
  sectorName: sectorName,
);

class _FakeProductsBloc extends ProductsBloc {
  final events = <ProductsEvent>[];

  _FakeProductsBloc() : super(FakeNetwork());

  @override
  void add(ProductsEvent event) => events.add(event);

  void show(ProductsState state) => emit(state);
}

void main() {
  group('PriceFormatter', () {
    test('whole amounts have no decimals and are grouped', () {
      expect(PriceFormatter.egp(13), '13 EGP');
      expect(PriceFormatter.egp(1450), '1,450 EGP');
      expect(PriceFormatter.egp(1234567), '1,234,567 EGP');
    });

    test('fractional amounts keep two decimals', () {
      expect(PriceFormatter.egp(12.5), '12.50 EGP');
      expect(PriceFormatter.egp(1999.99), '1,999.99 EGP');
    });
  });

  group('ProductsListing', () {
    final products = [
      _product(1, name: 'Tea', note: 'Black'),
      _product(
        2,
        name: 'Sugar',
        note: 'White',
        sectorId: 's2',
        sectorName: 'Bakery',
      ),
      _product(3, name: 'Coffee', note: 'tea time'),
    ];

    test('search matches name or note, ignoring case and whitespace', () {
      final listing = ProductsListing.from(products, query: '  TEA ');
      expect(listing.pageItems.map((p) => p.id), ['p1', 'p3']);
      expect(listing.filteredCount, 2);
      expect(listing.totalCount, 3);
    });

    test('sector filter and search combine', () {
      final listing = ProductsListing.from(
        products,
        query: 'tea',
        sectorId: 's1',
      );
      expect(listing.pageItems.map((p) => p.id), ['p1', 'p3']);
      expect(ProductsListing.from(products, sectorId: 's2').filteredCount, 1);
    });

    test('sectors come from all products, not the filtered ones', () {
      final listing = ProductsListing.from(products, query: 'sugar');
      expect(listing.sectors, {'s1': 'Supermarket', 's2': 'Bakery'});
    });

    test('paginates and clamps the requested page', () {
      final many = [for (var i = 1; i <= 10; i++) _product(i)];

      final first = ProductsListing.from(many);
      expect(first.pageCount, 2);
      expect(first.pageItems, hasLength(ProductsListing.pageSize));
      expect(first.firstIndex, 0);

      final second = ProductsListing.from(many, page: 1);
      expect(second.pageItems.map((p) => p.id), ['p9', 'p10']);
      expect(second.firstIndex, ProductsListing.pageSize);

      final past = ProductsListing.from(many, page: 5);
      expect(past.page, 1);
      expect(ProductsListing.from(many, page: -3).page, 0);
    });

    test('no matches yields one empty page', () {
      final listing = ProductsListing.from(products, query: 'zzz', page: 3);
      expect(listing.isEmpty, isTrue);
      expect(listing.filteredCount, 0);
      expect(listing.pageCount, 1);
      expect(listing.page, 0);
    });

    test('hasSector', () {
      expect(ProductsListing.hasSector(products, 's2'), isTrue);
      expect(ProductsListing.hasSector(products, 'gone'), isFalse);
    });
  });

  group('ProductsScreen', () {
    late _FakeProductsBloc bloc;

    setUp(() async {
      await initPrefs();
      bloc = _FakeProductsBloc();
      if (sl.isRegistered<ProductsBloc>()) sl.unregister<ProductsBloc>();
      sl.registerFactory<ProductsBloc>(() => bloc);
    });

    tearDown(() async {
      if (sl.isRegistered<ProductsBloc>()) sl.unregister<ProductsBloc>();
    });

    Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        localizedApp(const ProductsScreen(), locale: locale),
      );
      await tester.pump();
    }

    Future<void> show(WidgetTester tester, ProductsState state) async {
      bloc.show(state);
      await tester.pump();
    }

    testWidgets('requests the products on open and shows a spinner', (
      tester,
    ) async {
      await pump(tester);
      expect(bloc.events.single, isA<FetchProductsEvent>());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows products, the count and the categories', (tester) async {
      await pump(tester);
      await show(
        tester,
        ProductsLoadedState([
          _product(1, price: 1450),
          _product(2, sectorId: 's2', sectorName: 'Bakery'),
        ]),
      );

      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('2 products in your catalog'), findsOneWidget);
      expect(find.text('1,450 EGP'), findsOneWidget);
      expect(find.text('Delivery time: 1'), findsOneWidget);
    });

    testWidgets('search filters and shows the empty state', (tester) async {
      await pump(tester);
      await show(
        tester,
        ProductsLoadedState([
          _product(1, name: 'Tea'),
          _product(2, name: 'Rice'),
        ]),
      );

      await tester.enterText(find.byType(TextField), 'tea');
      await tester.pump();
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('Showing 1–1 of 1 products'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nothing');
      await tester.pump();
      expect(find.byType(ProductCard), findsNothing);
      expect(find.text('No products found'), findsOneWidget);
    });

    testWidgets('search text survives an error and a reload', (tester) async {
      await pump(tester);
      await show(
        tester,
        ProductsLoadedState([
          _product(1, name: 'Tea'),
          _product(2, name: 'Rice'),
        ]),
      );
      await tester.enterText(find.byType(TextField), 'tea');
      await tester.pump();

      await show(tester, const ProductsErrorState('no_internet'));
      expect(find.byType(TextField), findsNothing);

      await show(
        tester,
        ProductsLoadedState([
          _product(1, name: 'Tea'),
          _product(2, name: 'Rice'),
        ]),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'tea');
      expect(find.byType(ProductCard), findsOneWidget);
    });

    testWidgets('error view offers a retry that refetches', (tester) async {
      await pump(tester);
      await show(tester, const ProductsErrorState('no_internet'));

      await tester.tap(find.byType(OutlinedButton));
      expect(bloc.events, hasLength(2));
    });

    testWidgets('keeps the list visible while reloading', (tester) async {
      await pump(tester);
      await show(tester, ProductsLoadedState([_product(1)]));

      await show(tester, const ProductsLoadingState());
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('pull to refresh works on a short list', (tester) async {
      await pump(tester);
      await show(tester, ProductsLoadedState([_product(1)]));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(bloc.events, hasLength(2));

      // Like the real Bloc: loading first, then the refreshed list.
      await show(tester, const ProductsLoadingState());
      await show(tester, ProductsLoadedState([_product(1)]));
      await tester.pumpAndSettle();
    });

    testWidgets('paginates and clamps when the list shrinks', (tester) async {
      await pump(tester);
      await show(
        tester,
        ProductsLoadedState([for (var i = 1; i <= 10; i++) _product(i)]),
      );
      expect(find.byType(ProductCard), findsNWidgets(8));

      await tester.tap(find.text('2'));
      await tester.pump();
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('Showing 9–10 of 10 products'), findsOneWidget);

      // A refresh returns fewer products: the page must not point past the end.
      await show(tester, ProductsLoadedState([_product(1), _product(2)]));
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('Showing 1–2 of 2 products'), findsOneWidget);
    });

    testWidgets('a selected sector that disappears falls back to all', (
      tester,
    ) async {
      await pump(tester);
      await show(
        tester,
        ProductsLoadedState([
          _product(1),
          _product(2, sectorId: 's2', sectorName: 'Bakery'),
        ]),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bakery').last);
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsOneWidget);

      await show(tester, ProductsLoadedState([_product(1)]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('All categories'), findsOneWidget);
    });

    testWidgets('renders in Arabic', (tester) async {
      await pump(tester, locale: 'ar');
      await show(tester, ProductsLoadedState([_product(1)]));

      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('إضافة منتج'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
