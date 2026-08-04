import 'package:equatable/equatable.dart';
import '../../data/sign_up_request.dart';

abstract class SignUpEvent extends Equatable {
  const SignUpEvent();

  @override
  List<Object?> get props => [];
}

class SubmitSignUpEvent extends SignUpEvent {
  final SignUpRequest request;

  const SubmitSignUpEvent({required this.request});

  @override
  List<Object?> get props => [request];
}
