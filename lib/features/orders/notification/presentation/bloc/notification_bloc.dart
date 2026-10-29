import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/orders/notification/data/notification_response.dart';
import 'package:whats_order/features/orders/sms/data/sms_messages_response.dart';

import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NetworkInfo networkInfo;

  /// Ids the user has opened in this session (optimistic + confirmed). Used
  /// to keep them read when a fetch returns a response that predates the
  /// press. An id is removed again if persisting it fails.
  final Set<String> _locallyPressed = {};

  /// Same as [_locallyPressed], for SMS messages.
  final Set<String> _locallyPressedSms = {};

  NotificationBloc(this.networkInfo) : super(NotificationInitial()) {
    on<FetchNotificationEvent>(_fetchNotifications);
    on<FetchSmsEvent>(_fetchSms);
    on<PressNotificationEvent>(_pressNotification);
    on<PressSmsEvent>(_pressSms);
  }

  Future<void> _fetchNotifications(
    FetchNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoadingState());
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      emit(const NotificationErrorState(message: "no_internet"));
      return;
    }

    final result = await BaseRepository(
      'NotificationResponse',
    ).getData(event.day);

    emit(
      result.fold(
        (failure) => NotificationErrorState(message: failure.message),
        (response) => NotificationLoadedState(
          _reconcile(response as NotificationResponse),
        ),
      ),
    );
  }

  /// Server data wins, except that a notification pressed locally never goes
  /// back to unread because of a stale response.
  NotificationResponse _reconcile(NotificationResponse response) {
    if (_locallyPressed.isEmpty) return response;
    return NotificationResponse(
      notifications: [
        for (final n in response.notifications)
          (n.id != null && _locallyPressed.contains(n.id) && !n.isRead)
              ? n.copyWith(pressed: true)
              : n,
      ],
    );
  }

  NotificationResponse? _withPressed(
    NotificationResponse response,
    String id,
    bool pressed,
  ) {
    var changed = false;
    final updated = [
      for (final n in response.notifications)
        if (n.id == id && n.isRead != pressed)
          () {
            changed = true;
            return n.copyWith(pressed: pressed);
          }()
        else
          n,
    ];
    return changed ? NotificationResponse(notifications: updated) : null;
  }

  Future<void> _pressNotification(
    PressNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! NotificationLoadedState) return;

    // Already read (or unknown): nothing to show and nothing to persist.
    final target = current.response.notifications
        .where((n) => n.id == event.id)
        .firstOrNull;
    if (target == null || target.isRead || _locallyPressed.contains(event.id)) {
      return;
    }

    // Claim the id before any await so concurrent taps send one request.
    _locallyPressed.add(event.id);
    if (!await networkInfo.isConnected) {
      _locallyPressed.remove(event.id);
      return;
    }

    // 1) Show it as read immediately (immutable update of the list).
    final optimistic = _withPressed(current.response, event.id, true);
    if (optimistic != null) emit(NotificationLoadedState(optimistic));

    // 2) Persist through the existing endpoint.
    final result = await BaseRepository(
      "PressNotificationResponse",
    ).getData(event.id);

    // 3) On failure, do not pretend it was saved: back to unread.
    if (result.isLeft()) {
      _locallyPressed.remove(event.id);
      final latest = state;
      if (latest is NotificationLoadedState) {
        final reverted = _withPressed(latest.response, event.id, false);
        if (reverted != null) emit(NotificationLoadedState(reverted));
      }
    }
  }

  Future<void> _fetchSms(
    FetchSmsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(SmsLoadingState());
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      emit(const SmsErrorState(message: "no_internet"));
      return;
    }

    final result = await BaseRepository(
      "SmsMessagesResponse",
    ).getData(event.day);

    emit(
      result.fold(
        (failure) => SmsErrorState(message: failure.message),
        (response) =>
            SmsLoadedState(_reconcileSms(response as SmsMessagesResponse)),
      ),
    );
  }

  /// Same idea as [_reconcile], for SMS messages.
  SmsMessagesResponse _reconcileSms(SmsMessagesResponse response) {
    if (_locallyPressedSms.isEmpty) return response;
    return SmsMessagesResponse(
      smsMessages: [
        for (final m in response.smsMessages)
          (_locallyPressedSms.contains(m.id) && !m.pressed)
              ? m.copyWith(pressed: true)
              : m,
      ],
    );
  }

  SmsMessagesResponse? _withSmsPressed(
    SmsMessagesResponse response,
    String id,
    bool pressed,
  ) {
    var changed = false;
    final updated = [
      for (final m in response.smsMessages)
        if (m.id == id && m.pressed != pressed)
          () {
            changed = true;
            return m.copyWith(pressed: pressed);
          }()
        else
          m,
    ];
    return changed ? SmsMessagesResponse(smsMessages: updated) : null;
  }

  Future<void> _pressSms(
    PressSmsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is! SmsLoadedState) return;

    final target = current.response.smsMessages
        .where((m) => m.id == event.id)
        .firstOrNull;
    if (target == null ||
        target.pressed ||
        _locallyPressedSms.contains(event.id)) {
      return;
    }

    // Claim the id before any await so concurrent taps send one request.
    _locallyPressedSms.add(event.id);
    if (!await networkInfo.isConnected) {
      _locallyPressedSms.remove(event.id);
      return;
    }

    // 1) Show it as read immediately.
    final optimistic = _withSmsPressed(current.response, event.id, true);
    if (optimistic != null) emit(SmsLoadedState(optimistic));

    // 2) Persist through the existing endpoint.
    final result = await BaseRepository("PressSmsResponse").getData(event.id);

    // 3) On failure, back to unread so the UI never claims a save that failed.
    if (result.isLeft()) {
      _locallyPressedSms.remove(event.id);
      final latest = state;
      if (latest is SmsLoadedState) {
        final reverted = _withSmsPressed(latest.response, event.id, false);
        if (reverted != null) emit(SmsLoadedState(reverted));
      }
    }
  }
}
