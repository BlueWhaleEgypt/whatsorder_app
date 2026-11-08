import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/sign_up/data/sector_model.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/add_product_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/add_product_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/add_product_state.dart';
import 'package:whats_order/features/settings/presentation/screens/add_product_screen.dart';
import 'package:whats_order/features/settings/presentation/utils/add_product_form_rules.dart';
import 'package:whats_order/features/settings/presentation/utils/product_photos_controller.dart';
import 'package:whats_order/injection/injection_container.dart';

import 'helpers/harness.dart';

XFile _photo(int i) => XFile('/tmp/photo_$i.jpg');

class _FakeAddProductBloc extends AddProductBloc {
  final events = <AddProductEvent>[];

  _FakeAddProductBloc() : super(FakeNetwork());

  @override
  void add(AddProductEvent event) => events.add(event);

  void show(AddProductState state) => emit(state);

  List<SubmitAddProductEvent> get submits =>
      events.whereType<SubmitAddProductEvent>().toList();
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
  group('AddProductFormRules', () {
    test('hasText ignores null, empty and blank values', () {
      expect(AddProductFormRules.hasText(null), isFalse);
      expect(AddProductFormRules.hasText(''), isFalse);
      expect(AddProductFormRules.hasText('   '), isFalse);
      expect(AddProductFormRules.hasText(' a '), isTrue);
    });

    test('parsePrice accepts only finite numbers above zero', () {
      expect(AddProductFormRules.parsePrice('12.5'), 12.5);
      expect(AddProductFormRules.parsePrice(' 7 '), 7);
      for (final bad in [
        null,
        '',
        ' ',
        '0',
        '0.0',
        '-5',
        'abc',
        '1,5',
        'NaN',
        'Infinity',
        '-Infinity',
      ]) {
        expect(AddProductFormRules.parsePrice(bad), isNull, reason: '$bad');
      }
    });
  });

  group('ProductPhotosController', () {
    test('caps the list at the maximum', () {
      final c = ProductPhotosController();
      c.add([for (var i = 0; i < 6; i++) _photo(i)]);
      expect(c.photos, hasLength(6));
      expect(c.remaining, 2);

      c.add([for (var i = 10; i < 20; i++) _photo(i)]);
      expect(c.photos, hasLength(ProductPhotosController.maxPhotos));
      expect(c.canAddMore, isFalse);

      c.add([_photo(99)]);
      expect(c.photos, hasLength(ProductPhotosController.maxPhotos));
    });

    test('remove frees a slot, and ignores bad indexes', () {
      final c = ProductPhotosController()..add([_photo(1), _photo(2)]);
      c.removeAt(5);
      c.removeAt(-1);
      expect(c.photos, hasLength(2));

      c.removeAt(0);
      expect(c.photos.single.path, _photo(2).path);
    });

    test('error only shows after a submit attempt and follows the list', () {
      final c = ProductPhotosController();
      expect(c.showError, isFalse);

      expect(c.validate(), isFalse);
      expect(c.showError, isTrue);

      c.add([_photo(1)]);
      expect(c.showError, isFalse);
      expect(c.validate(), isTrue);

      c.removeAt(0);
      expect(c.showError, isTrue);
    });

    test('when optional, never errors and always validates', () {
      final c = ProductPhotosController(isRequired: false);
      expect(c.validate(), isTrue);
      expect(c.showError, isFalse);
    });

    test('notifies only when something changed', () {
      final c = ProductPhotosController();
      var notifications = 0;
      c.addListener(() => notifications++);

      c.add(const []);
      c.removeAt(0);
      expect(notifications, 0);

      c.validate(); // error appears
      c.validate(); // unchanged
      expect(notifications, 1);

      c.add([_photo(1)]);
      expect(notifications, 2);
    });
  });

  group('AddProductScreen', () {
    late _FakeAddProductBloc bloc;
    late List<XFile> Function() nextPick;
    late int pickCalls;

    setUp(() async {
      await initPrefs({CacheKeys.vendorId: 'vendor-1'});
      bloc = _FakeAddProductBloc();
      nextPick = () => [];
      pickCalls = 0;

      if (sl.isRegistered<AddProductBloc>()) sl.unregister<AddProductBloc>();
      if (sl.isRegistered<OnboardingCubit>()) sl.unregister<OnboardingCubit>();
      sl.registerFactory<AddProductBloc>(() => bloc);
      sl.registerFactory<OnboardingCubit>(() => _FakeOnboardingCubit());
    });

    tearDown(() {
      if (sl.isRegistered<AddProductBloc>()) sl.unregister<AddProductBloc>();
      if (sl.isRegistered<OnboardingCubit>()) sl.unregister<OnboardingCubit>();
    });

    Future<List<XFile>> pickPhotos() async {
      pickCalls++;
      return nextPick();
    }

    Future<void> pump(
      WidgetTester tester, {
      String locale = 'en',
      ProductModel? product,
    }) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        localizedApp(
          AddProductScreen(product: product, pickPhotos: pickPhotos),
          locale: locale,
        ),
      );
      await tester.pump();
    }

    Future<void> addPhotos(WidgetTester tester, List<XFile> photos) async {
      nextPick = () => photos;
      await tester.tap(find.text('Add photos'));
      await tester.pump();
    }

    Future<void> enter(WidgetTester tester, int field, String text) async {
      await tester.enterText(find.byType(TextFormField).at(field), text);
    }

    Future<void> pickSector(WidgetTester tester, String name) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    Future<void> fillValidForm(
      WidgetTester tester, {
      String price = '12.5',
    }) async {
      await addPhotos(tester, [_photo(1), _photo(2)]);
      await enter(tester, 0, '  Tea  ');
      await pickSector(tester, 'Bakery');
      await enter(tester, 1, price);
      await enter(tester, 2, ' 5 ');
      await enter(tester, 3, ' Black tea ');
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.tap(find.byType(GradientButton));
      await tester.pump();
    }

    group('validation', () {
      testWidgets('an empty form shows every error and sends nothing', (
        tester,
      ) async {
        await pump(tester);
        await submit(tester);

        // name, price, delivery time, description (the category is reported
        // with a snackbar instead of an inline error).
        expect(find.text('This field is required'), findsNWidgets(4));
        expect(find.text('Add at least one product photo'), findsOneWidget);
        expect(bloc.submits, isEmpty);
      });

      testWidgets('rejects empty, zero, negative and non-numeric prices', (
        tester,
      ) async {
        await pump(tester);
        await fillValidForm(tester);

        for (final bad in ['', '0', '-5', 'abc', 'NaN', 'Infinity']) {
          await enter(tester, 1, bad);
          await submit(tester);
          expect(
            find.text('This field is required'),
            findsOneWidget,
            reason: 'price "$bad"',
          );
          expect(bloc.submits, isEmpty, reason: 'price "$bad"');
        }
      });

      testWidgets('requires a category', (tester) async {
        await pump(tester);
        await fillValidForm(tester);
        // A fresh screen has no category chosen: rebuild without picking one.
        await tester.pumpWidget(const SizedBox());
        await pump(tester);
        await addPhotos(tester, [_photo(1)]);
        await enter(tester, 0, 'Tea');
        await enter(tester, 1, '5');
        await enter(tester, 2, '2');
        await enter(tester, 3, 'x');
        await submit(tester);
        await tester.pump(const Duration(milliseconds: 100));

        // No inline errors: the missing category is shown in a snackbar.
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text('This field is required'),
          ),
          findsOneWidget,
        );
        expect(bloc.submits, isEmpty);
      });

      testWidgets('requires at least one photo', (tester) async {
        await pump(tester);
        await fillValidForm(tester);
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pump();

        await submit(tester);
        expect(find.text('Add at least one product photo'), findsOneWidget);
        expect(bloc.submits, isEmpty);
      });

      testWidgets('a missing vendor id is reported, not sent', (tester) async {
        await initPrefs();
        await pump(tester);
        await fillValidForm(tester);
        await submit(tester);

        expect(find.text('User ID is missing'), findsOneWidget);
        expect(bloc.submits, isEmpty);
      });
    });

    group('submitting', () {
      testWidgets('sends the trimmed values, sector, vendor and photos', (
        tester,
      ) async {
        await pump(tester);
        await fillValidForm(tester);
        await submit(tester);

        final request = bloc.submits.single.request;
        expect(request.name, 'Tea');
        expect(request.price, 12.5);
        expect(request.deliveryTime, '5');
        expect(request.note, 'Black tea');
        expect(request.sectorId, 's2');
        expect(request.vendorId, 'vendor-1');
        expect(request.photoPaths, [_photo(1).path, _photo(2).path]);
      });

      testWidgets('a quick double tap sends only once', (tester) async {
        await pump(tester);
        await fillValidForm(tester);

        await tester.tap(find.byType(GradientButton));
        await tester.tap(find.byType(GradientButton));
        await tester.pump();

        expect(bloc.submits, hasLength(1));
      });

      testWidgets('while loading the button shows a spinner and is inert', (
        tester,
      ) async {
        await pump(tester);
        await fillValidForm(tester);
        await submit(tester);

        bloc.show(const AddProductLoading());
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(GradientButton),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byType(GradientButton));
        await tester.pump();
        expect(bloc.submits, hasLength(1));
      });

      testWidgets('an error shows its message and allows retrying', (
        tester,
      ) async {
        await pump(tester);
        await fillValidForm(tester);
        await submit(tester);

        bloc.show(const AddProductLoading());
        await tester.pump();
        bloc.show(const AddProductError('something_went_wrong'));
        await tester.pump();

        expect(
          find.text('Something went wrong. Please try again.'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await submit(tester);
        expect(bloc.submits, hasLength(2));
      });

      testWidgets('an offline error also allows retrying', (tester) async {
        await pump(tester);
        await fillValidForm(tester);
        await submit(tester);

        // The Bloc reports offline without ever emitting Loading.
        bloc.show(const AddProductError('no_internet'));
        await tester.pump();

        await submit(tester);
        expect(bloc.submits, hasLength(2));
      });

      testWidgets('success pops with true and confirms', (tester) async {
        bool? result;
        useTallScreen(tester);
        await tester.pumpWidget(
          localizedApp(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(pickPhotos: pickPhotos),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await fillValidForm(tester);
        await submit(tester);
        bloc.show(const AddProductSuccess('product_added_successfully'));
        await tester.pumpAndSettle();

        expect(result, isTrue);
        expect(find.text('open'), findsOneWidget);
        expect(find.text('Product added successfully'), findsOneWidget);
      });
    });

    group('photos', () {
      testWidgets('shows the picked photos, the first one is the cover', (
        tester,
      ) async {
        await pump(tester);
        await addPhotos(tester, [_photo(1), _photo(2), _photo(3)]);

        expect(find.byType(Image), findsNWidgets(3));
        expect(find.text('Cover'), findsOneWidget);
      });

      testWidgets('removing the cover promotes the next photo', (tester) async {
        await pump(tester);
        await addPhotos(tester, [_photo(1), _photo(2)]);

        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Cover'), findsOneWidget);
      });

      testWidgets('never exceeds 8 photos and hides the add tile', (
        tester,
      ) async {
        await pump(tester);
        await addPhotos(tester, [for (var i = 0; i < 5; i++) _photo(i)]);
        await addPhotos(tester, [for (var i = 10; i < 20; i++) _photo(i)]);

        expect(find.byType(Image), findsNWidgets(8));
        expect(find.text('Add photos'), findsNothing);

        // Removing one makes room again.
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pump();
        expect(find.text('Add photos'), findsOneWidget);
      });

      testWidgets('cancelling the picker changes nothing', (tester) async {
        await pump(tester);
        await addPhotos(tester, const []);

        expect(pickCalls, 1);
        expect(find.byType(Image), findsNothing);
        expect(find.text('Add photos'), findsOneWidget);
      });

      testWidgets('a picker failure shows an error instead of crashing', (
        tester,
      ) async {
        await pump(tester);
        nextPick = () => throw Exception('permission denied');
        await tester.tap(find.text('Add photos'));
        await tester.pump();

        expect(
          find.text('Something went wrong. Please try again.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // And the picker works again afterwards.
        await addPhotos(tester, [_photo(1)]);
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('the photo error follows the list after a failed submit', (
        tester,
      ) async {
        await pump(tester);
        expect(find.text('Add at least one product photo'), findsNothing);

        await submit(tester);
        expect(find.text('Add at least one product photo'), findsOneWidget);

        await addPhotos(tester, [_photo(1)]);
        expect(find.text('Add at least one product photo'), findsNothing);
        expect(find.textContaining('Up to 8 photos'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pump();
        expect(find.text('Add at least one product photo'), findsOneWidget);
      });
    });

    group('editing', () {
      const product = ProductModel(
        id: 'prod-9',
        name: 'Tea',
        price: 50,
        deliveryTime: '5',
        note: 'Black tea',
        sectorId: 's2',
        sectorName: 'Bakery',
      );

      testWidgets('is titled and labelled for editing', (tester) async {
        await pump(tester, product: product);

        expect(find.text('Edit product'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
        expect(find.text('Publish product'), findsNothing);
      });

      testWidgets('adding keeps its own title and button', (tester) async {
        await pump(tester);

        expect(find.text('Add new product'), findsOneWidget);
        expect(find.text('Publish product'), findsOneWidget);
      });

      testWidgets('fills the fields from the product', (tester) async {
        await pump(tester, product: product);

        String text(int field) => tester
            .widget<TextFormField>(find.byType(TextFormField).at(field))
            .controller!
            .text;
        expect(text(0), 'Tea');
        expect(text(1), '50');
        expect(text(2), '5');
        expect(text(3), 'Black tea');
      });

      testWidgets('keeps a fractional price as is', (tester) async {
        await pump(
          tester,
          product: const ProductModel(
            id: 'p',
            name: 'n',
            price: 12.5,
            deliveryTime: '1',
            note: 'x',
            sectorId: 's1',
            sectorName: 'Supermarket',
          ),
        );

        final price = tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text;
        expect(price, '12.5');
      });

      testWidgets('saves without picking photos, keeping id and sector', (
        tester,
      ) async {
        await pump(tester, product: product);
        await submit(tester);

        expect(find.text('Add at least one product photo'), findsNothing);
        expect(bloc.submits, isEmpty, reason: 'it is an update, not an add');

        final update = bloc.events.single as SubmitUpdateProductEvent;
        expect(update.request.id, 'prod-9');
        final sent = update.request.product;
        expect(sent.name, 'Tea');
        expect(sent.price, 50);
        expect(sent.deliveryTime, '5');
        expect(sent.note, 'Black tea');
        expect(sent.sectorId, 's2');
        expect(sent.vendorId, 'vendor-1');
        expect(sent.photoPaths, isEmpty);
      });

      testWidgets('sends the edited values and any new photos', (tester) async {
        await pump(tester, product: product);
        await addPhotos(tester, [_photo(7)]);
        await enter(tester, 0, 'Green tea');
        await enter(tester, 1, '65.5');
        await pickSector(tester, 'Supermarket');
        await submit(tester);

        final sent =
            (bloc.events.single as SubmitUpdateProductEvent).request.product;
        expect(sent.name, 'Green tea');
        expect(sent.price, 65.5);
        expect(sent.sectorId, 's1');
        expect(sent.photoPaths, [_photo(7).path]);
      });

      testWidgets('still validates the other fields', (tester) async {
        await pump(tester, product: product);
        await enter(tester, 0, '');
        await enter(tester, 1, '0');
        await submit(tester);

        expect(find.text('This field is required'), findsNWidgets(2));
        expect(bloc.events, isEmpty);
      });

      testWidgets('a quick double tap saves only once', (tester) async {
        await pump(tester, product: product);
        await tester.tap(find.byType(GradientButton));
        await tester.tap(find.byType(GradientButton));
        await tester.pump();

        expect(bloc.events, hasLength(1));
      });
    });

    testWidgets('lays out in Arabic (RTL) without errors', (tester) async {
      await pump(tester, locale: 'ar');
      await submit(tester);

      expect(
        Directionality.of(tester.element(find.byType(GradientButton))),
        TextDirection.rtl,
      );
      expect(find.text('هذا الحقل مطلوب'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });
}
