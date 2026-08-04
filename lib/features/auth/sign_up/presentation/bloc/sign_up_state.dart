import 'package:equatable/equatable.dart';
import '../../data/sign_up_response.dart';

abstract class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

class SignUpInitial extends SignUpState {}

class LoadingSignUpState extends SignUpState {}

class LoadedSignUpState extends SignUpState {
  final SignupResponse response;

  const LoadedSignUpState({required this.response});

  @override
  List<Object?> get props => [response];
}

class ErrorSignUpState extends SignUpState {
  final String message;

  const ErrorSignUpState({required this.message});

  @override
  List<Object?> get props => [message];
}
