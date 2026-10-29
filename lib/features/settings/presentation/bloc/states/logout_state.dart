import 'package:equatable/equatable.dart';

abstract class LogoutState extends Equatable {
  const LogoutState();

  @override
  List<Object?> get props => [];
}

class LogoutInitial extends LogoutState {
  const LogoutInitial();
}

class LogoutLoading extends LogoutState {
  const LogoutLoading();
}

/// Server session revoked and local session cleared.
class LogoutSuccess extends LogoutState {
  const LogoutSuccess();
}

/// [message] is a translation key. [sessionCleared] tells the UI whether the
/// user is already signed out locally (server request failed) or still signed
/// in (local cleanup failed).
class LogoutFailure extends LogoutState {
  final String message;
  final bool sessionCleared;

  const LogoutFailure(this.message, {required this.sessionCleared});

  @override
  List<Object?> get props => [message, sessionCleared];
}
