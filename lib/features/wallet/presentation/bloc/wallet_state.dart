import 'package:equatable/equatable.dart';
import 'package:whats_order/features/wallet/data/wallet_response.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoadingState extends WalletState {}

class WalletLoadedState extends WalletState {
  final WalletResponse response;

  const WalletLoadedState(this.response);

  @override
  List<Object?> get props => [response];
}

class WalletErrorState extends WalletState {
  final String message;

  const WalletErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

// wallet_state.dart
class CheckoutUrlReadyState extends WalletState {
  final String paymentUrl;
  const CheckoutUrlReadyState(this.paymentUrl);
}

class PaymentConfirmingState extends WalletState {}

class PaymentConfirmedState extends WalletState {}

class PaymentFailedState extends WalletState {
  final String message;
  const PaymentFailedState(this.message);
}
