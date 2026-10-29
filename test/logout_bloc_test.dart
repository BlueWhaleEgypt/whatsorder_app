import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/cache/session_cleaner.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/logout_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/logout_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/logout_state.dart';

import 'helpers/harness.dart';

/// Stands in for the network: records requests and answers with a canned
/// status, a connection error, or whatever the test releases via [gate].
class _FakeAdapter implements HttpClientAdapter {
  int status = 200;
  bool offline = false;
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
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      '{"message":"x"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingCleaner implements SessionCleaner {
  int calls = 0;

  @override
  Future<void> clear() async {
    calls++;
    throw StateError('disk failure');
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 100));

void main() {
  late _FakeAdapter adapter;
  late LogoutBloc bloc;
  late List<LogoutState> emitted;

  Object? cached(String key) =>
      CacheHelper.getDataFromSharedPreference(key: key);

  LogoutBloc build([SessionCleaner? cleaner]) {
    final b = LogoutBloc(FakeNetwork(), cleaner ?? const LocalSessionCleaner());
    emitted = [];
    b.stream.listen(emitted.add);
    return b;
  }

  /// Sends a logout and waits until the bloc reaches a final state.
  Future<void> logout() async {
    bloc.add(const LogoutRequested());
    await bloc.stream
        .firstWhere((s) => s is! LogoutLoading)
        .timeout(const Duration(seconds: 5));
    await _settle();
  }

  setUp(() async {
    await initPrefs({
      CacheKeys.userModel: '{"id":"v1"}',
      CacheKeys.accessToken: 'access',
      CacheKeys.refreshToken: 'refresh',
      CacheKeys.firstName: 'Ahmed',
      CacheKeys.lastName: 'Ali',
      CacheKeys.appLang: 'ar',
      CacheKeys.onboardingSeen: true,
    });
    ProfileName.fullName.value = 'Ahmed Ali';
    ProfileName.firstName.value = 'Ahmed';

    adapter = _FakeAdapter();
    DioHelper.dio = Dio(BaseOptions(baseUrl: EndPoints.baseUrl))
      ..httpClientAdapter = adapter;
    bloc = build();
  });

  tearDown(() => bloc.close());

  test('starts in LogoutInitial', () {
    expect(bloc.state, const LogoutInitial());
  });

  group('success', () {
    test('emits loading then success', () async {
      await logout();

      expect(emitted, [const LogoutLoading(), const LogoutSuccess()]);
    });

    test('posts to the logout endpoint with the stored token', () async {
      await logout();

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, EndPoints.epLogout);
      // LogoutResponse currently fills `refreshToken` from the cached
      // *access* token.
      expect(request.data, {'refreshToken': 'access'});
    });

    test('clears the session but keeps language and app settings', () async {
      await logout();

      for (final key in [
        CacheKeys.userModel,
        CacheKeys.accessToken,
        CacheKeys.refreshToken,
        CacheKeys.firstName,
        CacheKeys.lastName,
      ]) {
        expect(cached(key), isNull, reason: key);
      }
      expect(ProfileName.fullName.value, '');
      expect(ProfileName.firstName.value, '');
      expect(cached(CacheKeys.appLang), 'ar');
      expect(cached(CacheKeys.onboardingSeen), true);
    });
  });

  group('server or network failure', () {
    test(
      'HTTP error: failure (not success) with the session cleared',
      () async {
        adapter.status = 500;
        await logout();

        expect(emitted, [
          const LogoutLoading(),
          const LogoutFailure('logout_server_failed', sessionCleared: true),
        ]);
        expect(cached(CacheKeys.accessToken), isNull);
        expect(cached(CacheKeys.refreshToken), isNull);
        expect(cached(CacheKeys.userModel), isNull);
        expect(ProfileName.fullName.value, '');
      },
    );

    test('expired token (401) still signs out locally', () async {
      adapter.status = 401;
      await logout();

      expect(
        emitted.last,
        const LogoutFailure('logout_server_failed', sessionCleared: true),
      );
      expect(cached(CacheKeys.accessToken), isNull);
    });

    test('no connection: failure with the session cleared', () async {
      adapter.offline = true;
      await logout();

      expect(emitted, [
        const LogoutLoading(),
        const LogoutFailure('logout_server_failed', sessionCleared: true),
      ]);
      expect(cached(CacheKeys.accessToken), isNull);
      expect(cached(CacheKeys.refreshToken), isNull);
      expect(cached(CacheKeys.appLang), 'ar');
    });
  });

  group('local cleanup failure', () {
    test('reports the session as not cleared', () async {
      final cleaner = _ThrowingCleaner();
      await bloc.close();
      bloc = build(cleaner);

      await logout();

      expect(emitted, [
        const LogoutLoading(),
        const LogoutFailure('logout_local_failed', sessionCleared: false),
      ]);
      expect(cleaner.calls, 1);
    });

    test('takes priority over a server failure', () async {
      adapter.status = 500;
      await bloc.close();
      bloc = build(_ThrowingCleaner());

      await logout();

      expect(
        emitted.last,
        const LogoutFailure('logout_local_failed', sessionCleared: false),
      );
    });
  });

  group('duplicate requests', () {
    test('are ignored while a logout is in flight', () async {
      adapter.gate = Completer<void>();

      bloc.add(const LogoutRequested());
      await _settle();
      bloc.add(const LogoutRequested());
      bloc.add(const LogoutRequested());
      await _settle();
      expect(bloc.state, const LogoutLoading());

      adapter.gate!.complete();
      await _settle();

      expect(adapter.requests, hasLength(1));
      expect(emitted, [const LogoutLoading(), const LogoutSuccess()]);
    });

    test('a new logout is accepted after the previous one finished', () async {
      adapter.status = 500;
      await logout();
      await logout();

      expect(adapter.requests, hasLength(2));
      expect(emitted.whereType<LogoutLoading>(), hasLength(2));
    });
  });

  group('LocalSessionCleaner', () {
    test('removes only the session keys', () async {
      await const LocalSessionCleaner().clear();

      expect(cached(CacheKeys.userModel), isNull);
      expect(cached(CacheKeys.accessToken), isNull);
      expect(cached(CacheKeys.refreshToken), isNull);
      expect(cached(CacheKeys.firstName), isNull);
      expect(cached(CacheKeys.appLang), 'ar');
      expect(ProfileName.fullName.value, '');
    });

    test('is safe to run on an already empty session', () async {
      await const LocalSessionCleaner().clear();
      await const LocalSessionCleaner().clear();

      expect(cached(CacheKeys.accessToken), isNull);
    });
  });
}
