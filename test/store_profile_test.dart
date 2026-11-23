import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/settings/data/store_profile/store_profile_response.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/store_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/store_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/store_profile_bloc.dart';
import 'package:whats_order/features/settings/presentation/screens/store_profile_screen.dart';

import 'helpers/harness.dart';

/// Vendor payload as the server returns it: no dedicated address field, only
/// the location parts.
const _vendorJson = {
  'id': 'v1',
  'firstName': 'Ahmed',
  'lastName': 'Ali',
  'companyName': 'Home Appliances',
  'phone': '01012345678',
  'verifiedPhone': true,
  'storeSlug': 'elboray',
  'storeAbout': 'About my store',
  'storeOpensAt': '09:30:00',
  'storeClosesAt': '22:00',
  'storeDeliveryFee': 30,
  'workingDays': ['saturday', 'SUNDAY'],
  'city': 'الحي العاشر',
  'state': 'محافظة القاهرة',
  'street': '',
  'building': '',
  'sectors': [
    {'id': '1', 'name': 'Kitchen'},
    {'id': '2', 'name': 'Electronics'},
  ],
};

class _Adapter implements HttpClientAdapter {
  int getStatus = 200;
  int putStatus = 200;
  Object getBody = _vendorJson;
  Completer<void>? gate;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await gate?.future;
    final isGet = options.method == 'GET';
    final status = isGet ? getStatus : putStatus;
    final body = status >= 400
        ? {'message': 'server says no'}
        : (isGet ? getBody : _vendorJson);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Network implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
}

Map<String, List<String>> _fields(RequestOptions r) {
  final out = <String, List<String>>{};
  for (final e in (r.data as FormData).fields) {
    out.putIfAbsent(e.key, () => []).add(e.value);
  }
  return out;
}

void main() {
  late _Adapter adapter;
  late _Network network;

  setUp(() async {
    await initPrefs({CacheKeys.userModel: '{"id":"v1"}'});
    adapter = _Adapter();
    network = _Network();
    DioHelper.dio = Dio(BaseOptions(baseUrl: EndPoints.baseUrl))
      ..httpClientAdapter = adapter;
  });

  group('StoreProfile.fromJson', () {
    test('maps the store fields and trims times to HH:mm', () {
      final p = StoreProfile.fromJson(_vendorJson);

      expect(p.name, 'Home Appliances');
      expect(p.slug, 'elboray');
      expect(p.about, 'About my store');
      expect(p.opensAt, '09:30');
      expect(p.closesAt, '22:00');
      expect(p.deliveryFee, 30);
      expect(p.verifiedPhone, isTrue);
      expect(p.workingDays, ['SATURDAY', 'SUNDAY']);
      expect(p.sectors, ['Kitchen', 'Electronics']);
    });

    test('builds the address from the location parts, skipping empties', () {
      expect(
        StoreProfile.fromJson(_vendorJson).address,
        'الحي العاشر، محافظة القاهرة',
      );
    });

    test('prefers a dedicated storeAddress when the server sends one', () {
      final p = StoreProfile.fromJson(const {
        ..._vendorJson,
        'storeAddress': '12 Tahrir St',
      });

      expect(p.address, '12 Tahrir St');
    });

    test('uses safe defaults for an empty payload', () {
      final p = StoreProfile.fromJson(const {});

      expect(p.address, '');
      expect(p.opensAt, '10:00');
      expect(p.sectors, isEmpty);
      expect(p.workingDays, isEmpty);
    });
  });

  group('StoreProfileBloc', () {
    late StoreProfileBloc bloc;
    late List<StoreProfileState> emitted;

    setUp(() {
      bloc = StoreProfileBloc(network);
      emitted = [];
      bloc.stream.listen(emitted.add);
    });

    tearDown(() => bloc.close());

    Future<void> run(StoreProfileEvent e) async {
      bloc.add(e);
      await bloc.stream
          .firstWhere(
            (s) => s is! StoreProfileLoading && s is! StoreProfileSaving,
          )
          .timeout(const Duration(seconds: 5));
    }

    test('load fetches the vendor by the cached id', () async {
      await run(const LoadStoreProfileEvent());

      expect(emitted.first, const StoreProfileLoading());
      expect(emitted.last, isA<StoreProfileLoaded>());
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.uri.path, endsWith('/vendors/v1'));
    });

    test('load failure is reported, not as a save failure', () async {
      adapter.getStatus = 500;

      await run(const LoadStoreProfileEvent());

      final s = emitted.last as StoreProfileError;
      expect(s.message, 'server says no');
      expect(s.whileSaving, isFalse);
    });

    test('load while offline makes no request', () async {
      network.connected = false;

      await run(const LoadStoreProfileEvent());

      expect(emitted.last, const StoreProfileError('no_internet'));
      expect(adapter.requests, isEmpty);
    });

    test('save PUTs only storeProfile with every required field', () async {
      final profile = StoreProfile.fromJson(_vendorJson);

      await run(SaveStoreProfileEvent(profile));

      expect(emitted, [const StoreProfileSaving(), isA<StoreProfileSaved>()]);
      expect(adapter.requests, hasLength(1));
      final r = adapter.requests.single;
      expect(r.method, 'PUT');
      expect(r.uri.path, endsWith('/api/auth/storeProfile/v1'));

      final f = _fields(r);
      expect(f['name'], ['Home Appliances']);
      expect(f['slug'], ['elboray']);
      expect(f['about'], ['About my store']);
      expect(f['address'], ['الحي العاشر، محافظة القاهرة']);
      expect(f['opensAt'], ['09:30']);
      expect(f['closesAt'], ['22:00']);
      expect(f['deliveryFee'], ['30']);
      expect(f['workingDays'], ['SATURDAY', 'SUNDAY']);
      expect((r.data as FormData).files, isEmpty);
    });

    test('save failure keeps the whileSaving flag for the form', () async {
      adapter.putStatus = 400;

      await run(SaveStoreProfileEvent(StoreProfile.fromJson(_vendorJson)));

      final s = emitted.last as StoreProfileError;
      expect(s.whileSaving, isTrue);
      expect(s.message, 'server says no');
    });

    test('save without a cached user is rejected before any request', () async {
      await initPrefs();

      await run(SaveStoreProfileEvent(StoreProfile.fromJson(_vendorJson)));

      expect(
        (emitted.last as StoreProfileError).message,
        'current_user_not_identified',
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('StoreProfileScreen', () {
    Future<void> open(WidgetTester tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        localizedApp(
          BlocProvider(
            create: (_) => StoreProfileBloc(network),
            child: const StoreProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows a spinner until the data arrives', (tester) async {
      adapter.gate = Completer<void>();
      useTallScreen(tester);
      await tester.pumpWidget(
        localizedApp(
          BlocProvider(
            create: (_) => StoreProfileBloc(network),
            child: const StoreProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AppTextField), findsNothing);

      adapter.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Home Appliances'), findsOneWidget);
    });

    testWidgets('fills the form from the vendor, address included', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Home Appliances'), findsOneWidget);
      expect(find.text('About my store'), findsOneWidget);
      expect(find.text('01012345678'), findsOneWidget);
      expect(find.text('الحي العاشر، محافظة القاهرة'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('shows the vendor sectors', (tester) async {
      await open(tester);

      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
    });

    testWidgets('hides the sectors row when there are none', (tester) async {
      adapter.getBody = {..._vendorJson, 'sectors': []};
      await open(tester);

      expect(find.text('Sectors'), findsNothing);
    });

    testWidgets('phone and address are not editable', (tester) async {
      await open(tester);

      bool enabledFor(String text) => tester
          .widget<AppTextField>(
            find.ancestor(
              of: find.text(text),
              matching: find.byType(AppTextField),
            ),
          )
          .enabled;

      expect(enabledFor('01012345678'), isFalse);
      expect(enabledFor('الحي العاشر، محافظة القاهرة'), isFalse);
      expect(enabledFor('Home Appliances'), isTrue);
    });

    testWidgets('save sends the edited name and the address', (tester) async {
      await open(tester);

      await tester.enterText(find.text('Home Appliances'), 'New Name');
      final save = find.byType(GradientButton);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final put = adapter.requests.singleWhere((r) => r.method == 'PUT');
      final f = _fields(put);
      expect(f['name'], ['New Name']);
      expect(f['address'], ['الحي العاشر، محافظة القاهرة']);
      expect(find.text('Changes saved'), findsOneWidget);
    });

    testWidgets('an empty store name blocks the save', (tester) async {
      await open(tester);

      await tester.enterText(find.text('Home Appliances'), '');
      final save = find.byType(GradientButton);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('a failed save shows the server message', (tester) async {
      adapter.putStatus = 400;
      await open(tester);

      final save = find.byType(GradientButton);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('server says no'), findsOneWidget);
      expect(find.text('Home Appliances'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      adapter.getStatus = 500;
      await open(tester);

      expect(find.text('server says no'), findsOneWidget);

      adapter.getStatus = 200;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Home Appliances'), findsOneWidget);
    });
  });
}
