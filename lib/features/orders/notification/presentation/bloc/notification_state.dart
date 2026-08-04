import 'package:equatable/equatable.dart';
import 'package:whats_order/features/orders/notification/data/notification_response.dart';
import 'package:whats_order/features/orders/notification/data/sms_messages_response.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoadingState extends NotificationState {}

class NotificationLoadedState extends NotificationState {
  final NotificationResponse response;

  const NotificationLoadedState(this.response);

  @override
  List<Object?> get props => [response];
}

class NotificationErrorState extends NotificationState {
  final String message;

  const NotificationErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class SmsLoadingState extends NotificationState {}

class SmsLoadedState extends NotificationState {
  final SmsMessagesResponse response;

  const SmsLoadedState(this.response);

  @override
  List<Object?> get props => [response];
}

class SmsErrorState extends NotificationState {
  final String message;

  const SmsErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
