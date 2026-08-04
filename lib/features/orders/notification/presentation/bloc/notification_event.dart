import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotificationEvent extends NotificationEvent {
  // final NotificationRequest request;

  // const FetchNotificationEvent(this.request);
  final DateTime? day;

  const FetchNotificationEvent({this.day});

  @override
  List<Object?> get props => [day];
}

class FetchSmsEvent extends NotificationEvent {
  final DateTime? day;

  const FetchSmsEvent({this.day});
  @override
  List<Object?> get props => [day];
}

class PressNotificationEvent extends NotificationEvent {
  final String id;

  const PressNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class PressSmsEvent extends NotificationEvent {
  final String id;

  const PressSmsEvent(this.id);

  @override
  List<Object?> get props => [id];
}
