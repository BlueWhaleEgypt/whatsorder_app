import 'package:equatable/equatable.dart';
import 'package:whats_order/features/auth/otp/data/forget_password_response.dart';
import 'package:whats_order/features/auth/otp/data/send_otp_response.dart';
import 'package:whats_order/features/auth/otp/data/verify_otp_response.dart';

abstract class OtpState extends Equatable {
  const OtpState();

  @override
  List<Object?> get props => [];
}

class OtpInitial extends OtpState {}

class LoadingOtpState extends OtpState {}

class LoadedOtpState extends OtpState {
  final SendOtpResponse response;

  const LoadedOtpState(this.response);

  @override
  List<Object?> get props => [response];
}

class ErrorOtpState extends OtpState {
  final String message;

  const ErrorOtpState(this.message);

  @override
  List<Object?> get props => [message];
}

/// verified otp state
class VerifiedOtpState extends OtpState {
  final VerifyOtpResponse response;

  const VerifiedOtpState(this.response);

  @override
  List<Object?> get props => [response];
}

class VerifiedOtpErrorState extends OtpState {
  final String message;

  const VerifiedOtpErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// forget password state
class ForgetPasswordSuccessState extends OtpState {
  final ForgetPasswordResponse response;

  const ForgetPasswordSuccessState(this.response);

  @override
  List<Object?> get props => [response];
}

class ForgetPasswordErrorState extends OtpState {
  final String message;

  const ForgetPasswordErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
