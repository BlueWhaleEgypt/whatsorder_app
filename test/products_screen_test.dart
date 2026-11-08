import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/price_formatter.dart';
import 'package:whats_order/features/auth/sign_up/data/sector_model.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/settings/presentation/bloc/add_product_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/delete_product_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/add_product_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/delete_product_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/add_product_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/delete_product_state.dart';
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
  List<String> photos = const [],
}) => ProductModel(
  id: 'p$i',
  name: name ?? 'Product $i',
  price: price,
  deliveryTime: '$i',
  note: note,
  sectorId: sectorId,
  sectorName: sectorName,
  photos: photos,
);

class _FakeProductsBloc extends ProductsBloc {
  final events = <ProductsEvent>[];

  _FakeProductsBloc() : super(FakeNetwork());

  @override
  void add(ProductsEvent event) => events.add(event);

  void show(ProductsState state) => emit(state);
}

class _FakeDeleteProductBloc extends DeleteProductBloc {
  final events = <DeleteProductEvent>[];

  _FakeDeleteProductBloc() : super(FakeNetwork());

  @override
  void add(DeleteProductEvent event) => events.add(event);

  void show(DeleteProductState state) => emit(state);
}

class _FakeAddProductBloc extends AddProductBloc {
  final events = <AddProductEvent>[];

  _FakeAddProductBloc() : super(FakeNetwork());

  @override
  void add(AddProductEvent event) => events.add(event);

  void show(AddProductState state) => emit(state);
}

class _FakeOnboardingCubit extends OnboardingCubit {
  @override
  Future<void> loadSectors() async => emit(
    state.copyWith(
      sectors: const [
        SectorModel(
          id: 's1',
          name: 'Supermarket',
          note: '',
          cost: 0,
          view: true,
        ),
        SectorModel(id: 's2', name: 'Bakery', note: '', cost: 0, view: true),
      ],
    ),
  );
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

  group('ProductModel photos', () {
    Map<String, dynamic> json(Object? photos) => {
      'id': 'p1',
      'name': 'Tea',
      'price': 50,
      'delivaryTime': '5',
      'note': 'x',
      if (photos != null) 'photos': photos,
      'sector': {'id': 's1', 'name': 'Supermarket'},
    };

    test('reads the photo file names in order', () {
      final product = ProductModel.fromJson(
        json(['1794125568629A-Ascaled_1000001089.jpg', 'second.jpg']),
      );
      expect(product.photos, [
        '1794125568629A-Ascaled_1000001089.jpg',
        'second.jpg',
      ]);
    });

    test('the cover is the first photo, served from /uploads/', () {
      final product = ProductModel.fromJson(json(['a.jpg', 'b.jpg']));
      expect(product.coverPhotoUrl, '${EndPoints.baseUrl}/uploads/a.jpg');
    });

    test('file names are URL-encoded', () {
      final product = ProductModel.fromJson(json(['my photo ص.jpg']));
      expect(
        product.coverPhotoUrl,
        '${EndPoints.baseUrl}/uploads/${Uri.encodeComponent('my photo ص.jpg')}',
      );
    });

    test('missing, null, empty or malformed photos mean no cover', () {
      expect(ProductModel.fromJson(json(null)).coverPhotoUrl, isNull);
      expect(ProductModel.fromJson(json(<String>[])).coverPhotoUrl, isNull);
      expect(ProductModel.fromJson(json('oops')).photos, isEmpty);
      expect(ProductModel.fromJson(json([null, '', 'ok.jpg'])).photos, [
        'ok.jpg',
      ]);
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
    late _FakeDeleteProductBloc deleteBloc;
    late _FakeAddProductBloc addBloc;

    void unregisterAll() {
      if (sl.isRegistered<ProductsBloc>()) sl.unregister<ProductsBloc>();
      if (sl.isRegistered<DeleteProductBloc>()) {
        sl.unregister<DeleteProductBloc>();
      }
      if (sl.isRegistered<AddProductBloc>()) sl.unregister<AddProductBloc>();
      if (sl.isRegistered<OnboardingCubit>()) sl.unregister<OnboardingCubit>();
    }

    setUp(() async {
      await initPrefs({CacheKeys.vendorId: 'vendor-1'});
      bloc = _FakeProductsBloc();
      deleteBloc = _FakeDeleteProductBloc();
      addBloc = _FakeAddProductBloc();
      unregisterAll();
      sl.registerFactory<ProductsBloc>(() => bloc);
      sl.registerFactory<DeleteProductBloc>(() => deleteBloc);
      sl.registerFactory<AddProductBloc>(() => addBloc);
      sl.registerFactory<OnboardingCubit>(() => _FakeOnboardingCubit());
    });

    tearDown(unregisterAll);

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

    group('cover photo', () {
      testWidgets('shows the first photo of the product', (tester) async {
        await pump(tester);
        await show(
          tester,
          ProductsLoadedState([
            _product(1, photos: ['cover.jpg', 'other.jpg']),
          ]),
        );

        final image = tester.widget<Image>(
          find.descendant(
            of: find.byType(ProductCard),
            matching: find.byType(Image),
          ),
        );
        expect((image.image as ResizeImage).imageProvider, isA<NetworkImage>());
        final provider =
            (image.image as ResizeImage).imageProvider as NetworkImage;
        expect(provider.url, '${EndPoints.baseUrl}/uploads/cover.jpg');
      });

      testWidgets('a product without photos shows the placeholder', (
        tester,
      ) async {
        await pump(tester);
        await show(tester, ProductsLoadedState([_product(1)]));

        expect(
          find.descendant(
            of: find.byType(ProductCard),
            matching: find.byType(Image),
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      });

      testWidgets('a photo that fails to load falls back to the placeholder', (
        tester,
      ) async {
        await pump(tester);
        await show(
          tester,
          ProductsLoadedState([
            _product(1, photos: ['broken.jpg']),
          ]),
        );
        // Let the (blocked) test HTTP request fail.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();

        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('edit and delete', () {
      Future<void> load(WidgetTester tester) async {
        await pump(tester);
        await show(
          tester,
          ProductsLoadedState([
            _product(1, name: 'Tea', price: 50),
            _product(2, name: 'Sugar'),
          ]),
        );
      }

      testWidgets('every card has an edit and a delete button', (tester) async {
        await load(tester);
        expect(find.byTooltip('Edit'), findsNWidgets(2));
        expect(find.byTooltip('Delete'), findsNWidgets(2));
      });

      testWidgets('delete asks first and cancelling sends nothing', (
        tester,
      ) async {
        await load(tester);
        await tester.tap(find.byTooltip('Delete').first);
        await tester.pumpAndSettle();

        expect(find.text('Delete product'), findsOneWidget);
        expect(find.text('Tea'), findsWidgets);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(deleteBloc.events, isEmpty);
      });

      testWidgets('confirming deletes that product', (tester) async {
        await load(tester);
        await tester.tap(find.byTooltip('Delete').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final event = deleteBloc.events.single as SubmitDeleteProductEvent;
        expect(event.productId, 'p2');
      });

      testWidgets('a successful delete confirms and reloads the list', (
        tester,
      ) async {
        await load(tester);
        expect(bloc.events, hasLength(1));

        deleteBloc.show(
          const DeleteProductSuccess('product_deleted_successfully'),
        );
        await tester.pump();

        expect(find.text('Product deleted successfully'), findsOneWidget);
        expect(bloc.events, hasLength(2));
      });

      testWidgets('a failed delete shows the error and does not reload', (
        tester,
      ) async {
        await load(tester);
        deleteBloc.show(const DeleteProductError('product_delete_failed'));
        await tester.pump();

        expect(find.text('Failed to delete the product'), findsOneWidget);
        expect(bloc.events, hasLength(1));
      });

      testWidgets('only the product being deleted is locked', (tester) async {
        await load(tester);
        deleteBloc.show(const DeleteProductLoading('p1'));
        await tester.pump();

        // p1 swaps its delete button for a spinner; p2 is untouched.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byTooltip('Delete'), findsOneWidget);

        // A second delete while one is running is ignored.
        await tester.tap(find.byTooltip('Delete'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Delete product'), findsNothing);
      });

      testWidgets('edit opens the form filled in, and saving reloads', (
        tester,
      ) async {
        await load(tester);
        await tester.tap(find.byTooltip('Edit').first);
        await tester.pumpAndSettle();

        expect(find.text('Edit product'), findsOneWidget);
        expect(find.text('Tea'), findsOneWidget); // name field
        expect(find.text('50'), findsOneWidget); // price field

        addBloc.show(const AddProductSuccess('product_updated_successfully'));
        await tester.pumpAndSettle();

        expect(find.text('Edit product'), findsNothing);
        expect(find.text('Product updated successfully'), findsOneWidget);
        expect(bloc.events, hasLength(2));
      });

      testWidgets('leaving the edit form without saving does not reload', (
        tester,
      ) async {
        await load(tester);
        await tester.tap(find.byTooltip('Edit').first);
        await tester.pumpAndSettle();

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(bloc.events, hasLength(1));
      });
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
