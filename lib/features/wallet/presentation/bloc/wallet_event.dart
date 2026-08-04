import 'package:equatable/equatable.dart';
import 'package:whats_order/features/wallet/data/payment_checkout_request.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class GetWalletEvent extends WalletEvent {
  @override
  List<Object?> get props => [];
}

// wallet_event.dart
class StartCheckoutEvent extends WalletEvent {
  final PaymentCheckoutRequest request;
  const StartCheckoutEvent(this.request);
}

class ConfirmPaymentEvent extends WalletEvent {
  final String sessionId;
  final String walletId;
  const ConfirmPaymentEvent({required this.sessionId, required this.walletId});
}
