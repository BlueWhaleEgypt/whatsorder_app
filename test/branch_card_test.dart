import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';
import 'package:whats_order/features/settings/presentation/widgets/branch_card.dart';

import 'helpers/harness.dart';

String _tr(String l, String k) => kTranslations[l]![k]!;

class _FakeGeocoding extends GeocodingPlatform with MockPlatformInterfaceMixin {
  List<Placemark> result = const [];
  Object? error;
  int calls = 0;

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    String? localeIdentifier,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  late _FakeGeocoding geo;

  setUp(() {
    geo = _FakeGeocoding();
    GeocodingPlatform.instance = geo;
    BranchCard.clearGeoCache();
  });

  Future<void> pump(
    WidgetTester tester,
    BranchModel branch, {
    String locale = 'en',
    bool isBusy = false,
    double width = 360,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      localizedApp(
        SingleChildScrollView(
          child: BranchCard(
            branch: branch,
            isBusy: isBusy,
            onEdit: onEdit ?? () {},
            onDelete: onDelete ?? () {},
          ),
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows city and area as labelled chips, address without them', (
    tester,
  ) async {
    await pump(
      tester,
      const BranchModel(
        id: '1',
        name: 'الفرع',
        nameEn: 'Main',
        address: '12 Nile St, Dokki, Giza',
        city: 'Giza',
        area: 'Dokki',
      ),
    );

    expect(find.text(_tr('en', 'city')), findsOneWidget);
    expect(find.text(_tr('en', 'area')), findsOneWidget);
    expect(find.text('Giza'), findsOneWidget);
    expect(find.text('Dokki'), findsOneWidget);
    expect(find.text('12 Nile St'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides empty or blank city/area; full address stays', (
    tester,
  ) async {
    await pump(
      tester,
      const BranchModel(
        id: '1',
        name: 'Main',
        nameEn: '',
        address: '12 Nile St, Giza',
        city: '   ',
        area: null,
      ),
    );

    expect(find.text(_tr('en', 'city')), findsNothing);
    expect(find.text(_tr('en', 'area')), findsNothing);
    expect(find.text('12 Nile St, Giza'), findsOneWidget);
  });

  testWidgets('English name is a secondary label only when it differs', (
    tester,
  ) async {
    await pump(
      tester,
      const BranchModel(id: '1', name: 'Main', nameEn: 'Main', address: ''),
    );
    expect(find.text('Main'), findsOneWidget);

    await pump(
      tester,
      const BranchModel(id: '1', name: 'الفرع', nameEn: 'Main', address: ''),
    );
    expect(find.text('الفرع'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);

    await pump(
      tester,
      const BranchModel(id: '1', name: '', nameEn: 'Only English', address: ''),
    );
    expect(find.text('Only English'), findsOneWidget);
  });

  testWidgets('Edit and Delete call back; Delete is disabled when busy', (
    tester,
  ) async {
    var edits = 0, deletes = 0;
    const branch = BranchModel(id: '1', name: 'A', nameEn: '', address: '');
    await pump(
      tester,
      branch,
      onEdit: () => edits++,
      onDelete: () => deletes++,
    );
    await tester.tap(find.text(_tr('en', 'edit')));
    await tester.tap(find.text(_tr('en', 'delete')));
    expect((edits, deletes), (1, 1));

    await pump(tester, branch, isBusy: true, onDelete: () => deletes++);
    await tester.tap(find.text(_tr('en', 'delete')), warnIfMissed: false);
    expect(deletes, 1);
    await tester.tap(find.text(_tr('en', 'edit')));
  });

  for (final locale in ['en', 'ar']) {
    testWidgets('narrow screen, long text, no overflow ($locale)', (
      tester,
    ) async {
      final long = List.filled(8, 'Abdelrahman').join(' ');
      await pump(
        tester,
        BranchModel(
          id: '1',
          name: long,
          nameEn: '$long en',
          address: '$long, street',
          city: long,
          area: long,
        ),
        locale: locale,
        width: 280,
      );
      expect(tester.takeException(), isNull);
    });
  }

  test('city and area are read from JSON but never sent back', () {
    final b = BranchModel.fromJson({
      'id': 1,
      'name': 'A',
      'nameEn': 'B',
      'address': 'x',
      'city': 'Cairo',
      'area': 'Nasr City',
    });
    expect((b.city, b.area), ('Cairo', 'Nasr City'));
    expect(b.toJson().containsKey('city'), isFalse);
    expect(b.toJson().containsKey('area'), isFalse);
    expect(BranchModel.fromJson({'id': 1}).city, isNull);
  });

  group('reverse geocoding', () {
    const located = BranchModel(
      id: '1',
      name: 'Main',
      nameEn: '',
      latitude: 30.04,
      longitude: 31.23,
      address: '12 Nile St, Dokki, Giza',
    );

    testWidgets('fills city and area from the placemark, once', (tester) async {
      geo.result = const [
        Placemark(locality: 'Giza', subLocality: 'Dokki', street: 'x'),
      ];
      await pump(tester, located);

      expect(find.text('Giza'), findsOneWidget);
      expect(find.text('Dokki'), findsOneWidget);
      expect(find.text('12 Nile St'), findsOneWidget); // no repeats
      expect(geo.calls, 1);

      // Rebuilds (e.g. busy toggling) do not look it up again.
      await pump(tester, located, isBusy: true);
      expect(geo.calls, 1, reason: 'cached per coordinate pair');
      expect(find.text('Giza'), findsOneWidget);
    });

    testWidgets('falls back through sub/administrative areas', (tester) async {
      geo.result = const [
        Placemark(
          subAdministrativeArea: 'New Cairo',
          administrativeArea: 'Cairo',
        ),
      ];
      await pump(tester, located);
      expect(find.text('New Cairo'), findsOneWidget);
      // Area would equal the city, so it is dropped.
      expect(find.text(_tr('en', 'area')), findsNothing);
    });

    testWidgets('API values win and skip the lookup when complete', (
      tester,
    ) async {
      geo.result = const [Placemark(locality: 'Other', subLocality: 'Zone')];
      await pump(
        tester,
        const BranchModel(
          id: '1',
          name: 'M',
          nameEn: '',
          latitude: 1,
          longitude: 2,
          address: '',
          city: 'Alex',
          area: 'Smouha',
        ),
      );
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Smouha'), findsOneWidget);
      expect(geo.calls, 0);
    });

    testWidgets('only the missing part comes from geocoding', (tester) async {
      geo.result = const [
        Placemark(locality: 'Geo City', subLocality: 'Geo Area'),
      ];
      await pump(
        tester,
        const BranchModel(
          id: '1',
          name: 'M',
          nameEn: '',
          latitude: 1,
          longitude: 2,
          address: '',
          city: 'Alex',
        ),
      );
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Geo City'), findsNothing);
      expect(find.text('Geo Area'), findsOneWidget);
    });

    testWidgets('missing or invalid coordinates do not look anything up', (
      tester,
    ) async {
      await pump(
        tester,
        const BranchModel(id: '1', name: 'M', nameEn: '', address: 'A'),
      );
      await pump(
        tester,
        const BranchModel(
          id: '2',
          name: 'M',
          nameEn: '',
          latitude: 999,
          longitude: 31,
          address: 'A',
        ),
      );
      expect(geo.calls, 0);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('a geocoding failure leaves the card fully usable', (
      tester,
    ) async {
      geo.error = Exception('no service');
      var deletes = 0;
      await pump(tester, located, onDelete: () => deletes++);

      expect(tester.takeException(), isNull);
      expect(find.text(_tr('en', 'city')), findsNothing);
      expect(find.text('Main'), findsOneWidget);
      expect(find.text('12 Nile St, Dokki, Giza'), findsOneWidget);
      await tester.tap(find.text(_tr('en', 'delete')));
      expect(deletes, 1);
    });

    testWidgets('an empty result shows no chips', (tester) async {
      geo.result = const [];
      await pump(tester, located);
      expect(find.text(_tr('en', 'city')), findsNothing);
    });
  });
}
