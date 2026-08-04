import 'package:equatable/equatable.dart';
import '../../data/sign_in_response.dart';

/*
|--------------------------------------------------------------------------
| SignInState
|--------------------------------------------------------------------------
*/

abstract class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

class SignInInitial extends SignInState {}

class LoadingSignInState extends SignInState {}

class LoadedSignInState extends SignInState {
  final SignInResponse getSignInResponse;

  const LoadedSignInState({required this.getSignInResponse});

  @override
  List<Object?> get props => [getSignInResponse];
}

class ErrorSignInState extends SignInState {
  final String message;

  const ErrorSignInState({required this.message});

  @override
  List<Object?> get props => [message];
}
