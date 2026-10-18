import 'package:equatable/equatable.dart';

abstract class ChangePhoneEvent extends Equatable {
  const ChangePhoneEvent();

  @override
  List<Object?> get props => [];
}

class SubmitChangePhoneEvent extends ChangePhoneEvent {
  final String userId;
  final String phone;

  const SubmitChangePhoneEvent({required this.userId, required this.phone});

  @override
  List<Object?> get props => [userId, phone];
}
