import 'package:equatable/equatable.dart';

abstract class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

class SendOtpEvent extends OtpEvent {
  final String phone;

  const SendOtpEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class VerifyOtpEvent extends OtpEvent {
  final String phone;
  final String otp;

  const VerifyOtpEvent({required this.phone, required this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

class ForgetPasswordEvent extends OtpEvent {
  final String userId;
  final String newPassword;

  const ForgetPasswordEvent({required this.userId, required this.newPassword});

  @override
  List<Object?> get props => [userId, newPassword];
}
