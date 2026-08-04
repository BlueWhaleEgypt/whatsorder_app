import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/payment_session_storage.dart';
import 'package:whats_order/features/wallet/data/confirm_payment_response.dart';
import 'package:whats_order/features/wallet/data/payment_checkout_response.dart';
import 'package:whats_order/features/wallet/data/wallet_response.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:whats_order/features/wallet/presentation/bloc/wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  bool _confirming = false;
  final NetworkInfo networkInfo;

  WalletBloc(this.networkInfo) : super(WalletInitial()) {
    on<GetWalletEvent>(_getWallet);
    on<StartCheckoutEvent>(_startCheckout);
    on<ConfirmPaymentEvent>(_confirmPayment);
  }

  Future<void> _startCheckout(
    StartCheckoutEvent event,
    Emitter<WalletState> emit,
  ) async {
    // مهم: لازم نقرأ الـ walletId قبل أي emit، لأن بعد الـ emit
    // الـ `state` هيبقى WalletLoadingState مش WalletLoadedState.
    String? walletId;
    if (state is WalletLoadedState) {
      walletId = (state as WalletLoadedState).response.id?.toString();
    }

    emit(WalletLoadingState());

    final result = await const PaymentCheckoutResponse().getData(event.request);

    await result.fold(
      (failure) async {
        emit(PaymentFailedState(failure.message));
      },
      (data) async {
        final checkout = data as PaymentCheckoutResponse;

        if (checkout.sessionId == null) {
          emit(const PaymentFailedState("Missing sessionId from checkout"));
          return;
        }

        if (walletId == null) {
          emit(const PaymentFailedState("Wallet not loaded yet"));
          return;
        }

        await PaymentSessionStorage.save(
          sessionId: checkout.sessionId!,
          walletId: walletId,
        );

        if (checkout.paymentUrl == null) {
          emit(const PaymentFailedState("Missing payment URL"));
          return;
        }

        emit(CheckoutUrlReadyState(checkout.paymentUrl!));
      },
    );
  }

  Future<void> _confirmPayment(
    ConfirmPaymentEvent event,
    Emitter<WalletState> emit,
  ) async {
    if (_confirming) return;
    _confirming = true;

    try {
      emit(PaymentConfirmingState());

      final result = await const ConfirmPaymentResponse().getData({
        "sessionId": event.sessionId,
        "walletId": event.walletId,
      });

      await result.fold(
        (failure) async {
          emit(PaymentFailedState(failure.message));
        },
        (data) async {
          await PaymentSessionStorage.clear();
          emit(PaymentConfirmedState());
          add(GetWalletEvent());
        },
      );
    } finally {
      // نضمن إن الـ flag يترجع false حتى لو حصل استثناء غير متوقع،
      // عشان الـ bloc ميفضلش "stuck" ومايقبلش تأكيدات جديدة.
      _confirming = false;
    }
  }

  Future<void> _getWallet(
    GetWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoadingState());
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      emit(const WalletErrorState(message: "no_internet"));
      return;
    }

    final result = await BaseRepository("WalletResponse").getData(event);

    emit(
      result.fold(
        (failure) => WalletErrorState(message: failure.message),
        (response) => WalletLoadedState(response as WalletResponse),
      ),
    );
  }
}
