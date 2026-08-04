import 'package:equatable/equatable.dart';
import '../../data/sign_in_request.dart';

/*
|--------------------------------------------------------------------------
| SignInEvent
|--------------------------------------------------------------------------
*/

abstract class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends SignInEvent {
  final SignInRequest request;

  const LoginEvent({required this.request});

  @override
  List<Object?> get props => [request];
}
