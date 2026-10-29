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
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_bloc.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_event.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_state.dart';
import 'package:whats_order/features/orders/sms/presentation/sms_messages_screen.dart';
import 'package:whats_order/features/orders/sms/presentation/sms_phone.dart';

import 'helpers/harness.dart';

class _FakeBackend implements HttpClientAdapter {
  List<Map<String, dynamic>> messages = [];
  int pressStatus = 200;
  Completer<void>? pressGate;
  final pressed = <String>[];
  final days = <String>[];
  int fetches = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body = {};
    var status = 200;
    if (options.path.endsWith('/isPressed')) {
      pressed.add('${options.queryParameters['id']}');
      await pressGate?.future;
      status = pressStatus;
    } else {
      fetches++;
      days.add('${options.queryParameters['day']}');
      body = {'smsMessages': messages};
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

const _arabic =
    'العميل اختارك 👌 📞 كلمه فورًا على: 01551610944 و أكد الأوردر رقم 6777';

Map<String, dynamic> _m(
  String id, {
  bool pressed = false,
  String body = _arabic,
  int order = 6777,
}) => {
  'id': id,
  'title': 'SMS $id',
  'components': body,
  'orderId': order,
  'pressed': pressed,
};

String _en(String k) => kTranslations['en']![k]!;

void main() {
  late _FakeBackend backend;
  late _Net net;
  late NotificationBloc bloc;
  late List<Uri> launched;
  late bool canLaunch;

  setUp(() async {
    await initPrefs({
      CacheKeys.userModel: jsonEncode({'id': 'vendor-9'}),
    });
    backend = _FakeBackend();
    net = _Net();
    DioHelper.dio = Dio()..httpClientAdapter = backend;
    bloc = NotificationBloc(net);
    launched = [];
    canLaunch = true;
  });

  tearDown(() => bloc.close());

  List<dynamic> loaded() => (bloc.state as SmsLoadedState).response.smsMessages;
  bool pressedOf(String id) =>
      loaded().firstWhere((m) => m.id == id).pressed as bool;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      final s = bloc.state;
      if (s is! NotificationInitial && s is! SmsLoadingState) break;
    }
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, {
    String locale = 'en',
    Size? size,
  }) async {
    useTallScreen(tester);
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
    }
    await tester.pumpWidget(
      localizedApp(
        BlocProvider<NotificationBloc>.value(
          value: bloc,
          child: SmsMessagesScreen(
            launcher: (uri) async {
              launched.add(uri);
              return canLaunch;
            },
          ),
        ),
        locale: locale,
      ),
    );
    await tester.pump();
    await settle(tester);
  }

  int newBadges(WidgetTester t) =>
      find.byKey(const ValueKey('sms-status-new')).evaluate().length;
  int readBadges(WidgetTester t) =>
      find.byKey(const ValueKey('sms-status-read')).evaluate().length;

  group('extractPhoneNumber', () {
    test('finds the number and ignores the order number', () {
      expect(extractPhoneNumber(_arabic), '01551610944');
    });
    test('handles +20 prefix and Arabic-Indic digits', () {
      expect(extractPhoneNumber('call +201551610944 now'), '01551610944');
      expect(extractPhoneNumber('رقم ٠١٥٥١٦١٠٩٤٤ مهم'), '01551610944');
    });
    test('rejects missing, short and over-long numbers', () {
      expect(extractPhoneNumber('order 6777'), isNull);
      expect(extractPhoneNumber('0155161094'), isNull);
      expect(extractPhoneNumber('015516109441234'), isNull);
      expect(extractPhoneNumber(''), isNull);
    });
  });

  group('bloc', () {
    Future<void> fetch([DateTime? day]) async {
      bloc.add(FetchSmsEvent(day: day));
      await bloc.stream.firstWhere((s) => s is SmsLoadedState);
    }

    test('press shows read at once and persists once (double tap)', () async {
      backend.messages = [_m('a'), _m('b')];
      await fetch();
      backend.pressGate = Completer<void>();
      bloc.add(const PressSmsEvent('a'));
      bloc.add(const PressSmsEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(pressedOf('a'), isTrue);
      expect(pressedOf('b'), isFalse);
      backend.pressGate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(backend.pressed, ['a']);
    });

    test('already read: no request', () async {
      backend.messages = [_m('a', pressed: true)];
      await fetch();
      bloc.add(const PressSmsEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(backend.pressed, isEmpty);
    });

    test('stale fetch cannot revert a read message', () async {
      backend.messages = [_m('a')];
      await fetch();
      bloc.add(const PressSmsEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await fetch();
      expect(pressedOf('a'), isTrue);
    });

    test('failed save restores unread and allows retry', () async {
      backend.messages = [_m('a')];
      await fetch();
      backend.pressStatus = 500;
      bloc.add(const PressSmsEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(pressedOf('a'), isFalse);
      backend.pressStatus = 200;
      bloc.add(const PressSmsEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(pressedOf('a'), isTrue);
      expect(backend.pressed, ['a', 'a']);
    });

    test('offline: nothing sent, stays unread', () async {
      backend.messages = [_m('a')];
      await fetch();
      net.online = false;
      bloc.add(const PressSmsEvent('a'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(backend.pressed, isEmpty);
      expect(pressedOf('a'), isFalse);
    });

    test('date filter sends the chosen day', () async {
      backend.messages = [];
      await fetch(DateTime(2026, 3, 5));
      expect(backend.days.last, '2026-03-05');
    });
  });

  group('screen', () {
    testWidgets('card separates title, body, phone and order chip', (
      tester,
    ) async {
      backend.messages = [_m('a')];
      await pump(tester);

      expect(find.text('SMS a'), findsOneWidget);
      expect(find.byKey(const ValueKey('sms-body')), findsOneWidget);
      expect(find.text('01551610944'), findsOneWidget);
      expect(find.text(_en('call_customer')), findsOneWidget);
      expect(find.text('${_en('order_id_label')}  #6777'), findsOneWidget);
      expect(find.text(_en('status_new')), findsOneWidget);
    });

    testWidgets('no phone section when the message has no number', (
      tester,
    ) async {
      backend.messages = [_m('a', body: 'no number here')];
      await pump(tester);
      expect(find.byKey(const ValueKey('sms-phone')), findsNothing);
    });

    testWidgets('unread/read styling differs', (tester) async {
      backend.messages = [_m('a'), _m('b', pressed: true)];
      await pump(tester);
      expect(newBadges(tester), 1);
      expect(readBadges(tester), 1);
    });

    testWidgets('tapping the card turns it read immediately, once', (
      tester,
    ) async {
      backend.messages = [_m('a')];
      backend.pressGate = Completer<void>();
      await pump(tester);

      await tester.tap(find.text('SMS a'));
      await tester.tap(find.text('SMS a'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      // Server has not answered yet, UI is already read.
      expect(newBadges(tester), 0);
      expect(readBadges(tester), 1);

      backend.pressGate!.complete();
      await settle(tester);
      expect(backend.pressed, ['a']);
      expect(launched, isEmpty); // card tap never dials
    });

    testWidgets('failed save shows unread again', (tester) async {
      backend.messages = [_m('a')];
      backend.pressStatus = 500;
      await pump(tester);
      await tester.tap(find.text('SMS a'));
      await settle(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(newBadges(tester), 1);
    });

    testWidgets('phone tap dials and marks read; stays read on rebuild', (
      tester,
    ) async {
      backend.messages = [_m('a')];
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('sms-phone')));
      await settle(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(launched.single.toString(), 'tel:01551610944');
      expect(backend.pressed, ['a']);
      expect(readBadges(tester), 1);

      // Rebuild (as when returning from the dialer): state lives in the bloc.
      tester.view.physicalSize = const Size(500, 1800);
      await tester.pumpAndSettle();
      expect(readBadges(tester), 1);
      expect(backend.fetches, 1);
    });

    testWidgets('dialer failure: stays unread, nothing sent, feedback shown', (
      tester,
    ) async {
      backend.messages = [_m('a')];
      canLaunch = false;
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('sms-phone')));
      await tester.pump();
      await tester.pump();

      expect(backend.pressed, isEmpty);
      expect(newBadges(tester), 1);
      expect(find.text(_en('cannot_open_dialer')), findsOneWidget);
    });

    testWidgets('long Arabic message on a narrow screen does not overflow', (
      tester,
    ) async {
      backend.messages = [_m('a', body: '$_arabic ${'نص طويل جدا ' * 30}')];
      await pump(tester, locale: 'ar', size: const Size(280, 1200));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('sms-body')), findsOneWidget);
    });

    testWidgets('empty state is localized', (tester) async {
      backend.messages = [];
      await pump(tester);
      expect(find.text(_en('no_sms_messages')), findsOneWidget);
      expect(find.text('No Messages'), findsNothing);
    });
  });
}
