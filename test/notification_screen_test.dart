import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_translations.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_bloc.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_event.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_state.dart';
import 'package:whats_order/features/orders/notification/presentation/screens/notification_screen.dart';

import 'helpers/harness.dart';

/// Fake backend for the two notification endpoints (no network).
class _FakeBackend implements HttpClientAdapter {
  /// What GET /api/notification returns.
  List<Map<String, dynamic>> notifications = [];

  /// Status for GET /api/notification/isPressed.
  int pressStatus = 200;
  Completer<void>? pressGate;

  final pressed = <String>[];
  int fetches = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body;
    int status = 200;
    if (options.path.endsWith('/isPressed')) {
      pressed.add('${options.queryParameters['id']}');
      await pressGate?.future;
      status = pressStatus;
      body = {};
    } else {
      fetches++;
      body = {'notifications': notifications};
    }
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

class _Net implements NetworkInfo {
  bool online = true;
  @override
  Future<bool> get isConnected async => online;
}

Map<String, dynamic> _n(String id, {bool? pressed, int order = 100}) => {
  'id': id,
  'title': 'Order $id',
  'components': 'Two chairs $id',
  'orderId': order,
  'pressed': pressed,
};

String _en(String k) => kTranslations['en']![k]!;

void main() {
  late _FakeBackend backend;
  late _Net net;
  late NotificationBloc bloc;
  late List<RouteSettings> pushed;

  setUp(() async {
    await initPrefs({
      CacheKeys.userModel: jsonEncode({'id': 'vendor-9'}),
    });
    backend = _FakeBackend();
    net = _Net();
    DioHelper.dio = Dio()..httpClientAdapter = backend;
    bloc = NotificationBloc(net);
    pushed = [];
  });

  tearDown(() => bloc.close());

  List<dynamic> loaded() =>
      (bloc.state as NotificationLoadedState).response.notifications;

  bool? pressedOf(String id) =>
      loaded().firstWhere((n) => n.id == id).pressed as bool?;

  /// Gives the bloc's fake-backend I/O real time, then renders the result.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      final s = bloc.state;
      if (s is! NotificationInitial && s is! NotificationLoadingState) break;
    }
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> pump(WidgetTester tester, {String locale = 'en'}) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      localizedApp(
        BlocProvider<NotificationBloc>.value(
          value: bloc,
          child: const NotificationScreen(),
        ),
        locale: locale,
        onGenerateRoute: (s) {
          pushed.add(s);
          return MaterialPageRoute(
            settings: s,
            builder: (c) => Scaffold(
              appBar: AppBar(),
              body: Text('details:${(s.arguments as Map)['orderId']}'),
            ),
          );
        },
      ),
    );
    await tester.pump(); // localization delegates finish loading
    await settle(tester);
  }

  group('bloc', () {
    Future<void> fetch() async {
      bloc.add(const FetchNotificationEvent());
      await bloc.stream.firstWhere((s) => s is NotificationLoadedState);
    }

    test('pressing marks it read immediately and persists once', () async {
      backend.notifications = [
        _n('a', pressed: false),
        _n('b', pressed: false),
      ];
      await fetch();

      backend.pressGate = Completer<void>();
      bloc.add(const PressNotificationEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Before the server answered: already read locally.
      expect(pressedOf('a'), isTrue);
      expect(pressedOf('b'), isFalse);

      backend.pressGate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pressedOf('a'), isTrue);
      expect(backend.pressed, ['a']);
    });

    test('already-read notifications trigger no request', () async {
      backend.notifications = [_n('a', pressed: true)];
      await fetch();

      bloc.add(const PressNotificationEvent('a'));
      bloc.add(const PressNotificationEvent('unknown'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(backend.pressed, isEmpty);
    });

    test('a double tap sends only one request', () async {
      backend.notifications = [_n('a', pressed: false)];
      await fetch();

      backend.pressGate = Completer<void>();
      bloc.add(const PressNotificationEvent('a'));
      bloc.add(const PressNotificationEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      backend.pressGate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(backend.pressed, ['a']);
    });

    test('a stale fetch cannot make it unread again', () async {
      backend.notifications = [_n('a', pressed: false)];
      await fetch();
      bloc.add(const PressNotificationEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pressedOf('a'), isTrue);

      // Server still reports the old state (response predates the press).
      backend.notifications = [_n('a', pressed: false)];
      await fetch();

      expect(pressedOf('a'), isTrue);
    });

    test('server data wins for everything else', () async {
      backend.notifications = [
        _n('a', pressed: false),
        _n('b', pressed: false),
      ];
      await fetch();
      backend.notifications = [_n('a', pressed: true), _n('b', pressed: false)];
      await fetch();

      expect(pressedOf('a'), isTrue);
      expect(pressedOf('b'), isFalse);
    });

    test('a failed save goes back to unread (not claimed as saved)', () async {
      backend.notifications = [_n('a', pressed: false)];
      await fetch();

      backend.pressStatus = 500;
      bloc.add(const PressNotificationEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(backend.pressed, ['a']);
      expect(pressedOf('a'), isFalse);

      // And a later fetch also reports the server's truth (unread).
      await fetch();
      expect(pressedOf('a'), isFalse);

      // A retry is possible.
      backend.pressStatus = 200;
      bloc.add(const PressNotificationEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(pressedOf('a'), isTrue);
      expect(backend.pressed, ['a', 'a']);
    });

    test('offline: no request and no fake read state', () async {
      backend.notifications = [_n('a', pressed: false)];
      await fetch();

      net.online = false;
      bloc.add(const PressNotificationEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(backend.pressed, isEmpty);
      expect(pressedOf('a'), isFalse);
    });

    test('a missing pressed flag counts as unread', () async {
      backend.notifications = [_n('a')];
      await fetch();
      expect(pressedOf('a'), isNull);

      bloc.add(const PressNotificationEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pressedOf('a'), isTrue);
    });
  });

  group('screen', () {
    int dots(WidgetTester tester) =>
        find.byKey(const ValueKey('unread-dot')).evaluate().length;

    testWidgets('unread and read cards look different', (tester) async {
      backend.notifications = [
        _n('a', pressed: false, order: 1),
        _n('b', pressed: true, order: 2),
      ];
      await pump(tester);

      expect(dots(tester), 1);
      expect(find.textContaining('#1'), findsOneWidget);
      expect(find.textContaining('#2'), findsOneWidget);
      expect(find.text(_en('order_id_label')), findsNothing);
    });

    testWidgets('tapping updates the card at once and opens details', (
      tester,
    ) async {
      backend.notifications = [_n('a', pressed: false, order: 7)];
      await pump(tester);
      expect(dots(tester), 1);

      await tester.tap(find.text('Order a'));
      await settle(tester);

      expect(pushed.last.name, NamedRoutes.orderDetail);
      expect(pushed.last.arguments, {
        'orderId': 7,
        'userId': 'vendor-9',
        'latitude': null,
        'longitude': null,
        'components': 'Two chairs a',
      });
      expect(backend.pressed, ['a']);

      // Back from the details: still read, and no refetch was needed.
      final fetchesBefore = backend.fetches;
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Order a'), findsOneWidget);
      expect(dots(tester), 0);
      expect(backend.fetches, fetchesBefore);
    });

    testWidgets('rebuilding the screen keeps the read state', (tester) async {
      backend.notifications = [_n('a', pressed: false)];
      await pump(tester);
      await tester.tap(find.text('Order a'));
      await settle(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Force rebuilds (rotate-like resize and a re-pump of the same tree).
      tester.view.physicalSize = const Size(500, 1800);
      await tester.pumpAndSettle();
      expect(dots(tester), 0);
    });

    testWidgets('a failed save shows the card as unread again', (tester) async {
      backend.notifications = [_n('a', pressed: false)];
      backend.pressStatus = 500;
      await pump(tester);

      await tester.tap(find.text('Order a'));
      await settle(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(dots(tester), 1);
    });

    testWidgets('tapping an already-read card sends nothing', (tester) async {
      backend.notifications = [_n('a', pressed: true)];
      await pump(tester);
      await tester.tap(find.text('Order a'));
      await settle(tester);

      expect(backend.pressed, isEmpty);
      expect(pushed.last.name, NamedRoutes.orderDetail);
    });

    testWidgets('long titles and messages wrap without overflow', (
      tester,
    ) async {
      final long = List.filled(40, 'Abdelrahman').join(' ');
      backend.notifications = [
        {
          'id': 'a',
          'title': long,
          'components': long,
          'orderId': 1,
          'pressed': false,
        },
      ];
      tester.view.physicalSize = const Size(280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(tester, locale: 'ar');
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty list shows the empty state', (tester) async {
      await pump(tester);
      expect(find.text(_en('no_Notifications')), findsOneWidget);
    });
  });
}
