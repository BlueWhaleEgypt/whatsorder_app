import 'package:equatable/equatable.dart';
import 'package:whats_order/features/settings/data/phone/change_phone_response.dart';

abstract class ChangePhoneState extends Equatable {
  const ChangePhoneState();

  @override
  List<Object?> get props => [];
}

class ChangePhoneInitial extends ChangePhoneState {
  const ChangePhoneInitial();
}

class ChangePhoneLoading extends ChangePhoneState {
  const ChangePhoneLoading();
}

class ChangePhoneSuccess extends ChangePhoneState {
  final ChangePhoneResponse response;

  const ChangePhoneSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class ChangePhoneError extends ChangePhoneState {
  final String message;

  const ChangePhoneError(this.message);

  @override
  List<Object?> get props => [message];
}
