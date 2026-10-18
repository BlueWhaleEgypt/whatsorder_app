import 'package:equatable/equatable.dart';

abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object?> get props => [];
}

class SubmitChangePasswordEvent extends ChangePasswordEvent {
  final String userId;
  final String plainPassword;
  final String newPassword;

  const SubmitChangePasswordEvent({
    required this.userId,
    required this.plainPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [userId, plainPassword, newPassword];
}
