import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/orders/notification/data/notification_response.dart';
import 'package:whats_order/features/orders/notification/data/sms_messages_response.dart';

import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NetworkInfo networkInfo;
  // final List<NotificationModel> _notifications = [];

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
        (response) => NotificationLoadedState(response as NotificationResponse),
      ),
    );
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
        (response) => SmsLoadedState(response as SmsMessagesResponse),
      ),
    );
  }
}

Future<void> _pressNotification(
  PressNotificationEvent event,
  Emitter<NotificationState> emit,
) async {
  final result = await BaseRepository(
    "PressNotificationResponse",
  ).getData(event.id);

  result.fold(
    (failure) {
      // Optional: logger.e(failure.message);
    },
    (_) {
      // API executed successfully.
    },
  );
}

Future<void> _pressSms(
  PressSmsEvent event,
  Emitter<NotificationState> emit,
) async {
  final result = await BaseRepository("PressSmsResponse").getData(event.id);

  result.fold(
    (failure) {
      // Optional: logger.e(failure.message);
    },
    (_) {
      // API executed successfully.
    },
  );
}
