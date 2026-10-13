
import 'package:equatable/equatable.dart';

abstract class UpdateProfileState extends Equatable {
  const UpdateProfileState();

  @override
  List<Object?> get props => [];
}

class UpdateProfileInitial extends UpdateProfileState {
  const UpdateProfileInitial();
}

class UpdateProfileLoading extends UpdateProfileState {
  const UpdateProfileLoading();
}

class UpdateProfileSuccess extends UpdateProfileState {
  final String message;

  const UpdateProfileSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UpdateProfileError extends UpdateProfileState {
  final String message;

  const UpdateProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
