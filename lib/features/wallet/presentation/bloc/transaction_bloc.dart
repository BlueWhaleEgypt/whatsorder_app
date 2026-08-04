import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/wallet/data/transaction_model.dart';
import 'package:whats_order/features/wallet/data/transaction_requiest.dart';
import 'package:whats_order/features/wallet/data/transaction_response.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final NetworkInfo networkInfo;

  TransactionBloc(this.networkInfo) : super(TransactionInitial()) {
    on<GetTransactionsEvent>(_getTransactions);
  }
  final List<TransactionModel> _transactions = [];

  int _page = 0;
  final int _size = 20;

  bool _hasReachedEnd = false;
  bool _isLoading = false;
  Future<void> _getTransactions(
    GetTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    if (_isLoading) return;

    if (event.loadMore && _hasReachedEnd) return;

    _isLoading = true;

    if (!event.loadMore) {
      _page = 0;
      _hasReachedEnd = false;
      _transactions.clear();

      emit(TransactionLoadingState());
    }

    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      emit(const TransactionErrorState("no_internet"));
      return;
    }
    final result = await BaseRepository(
      "TransactionResponse",
    ).getData(TransactionRequest(page: _page, size: _size));

    result.fold(
      (failure) {
        emit(TransactionErrorState(failure.message));
      },
      (response) {
        final data = response as TransactionResponse;

        if (data.content.length < _size) {
          _hasReachedEnd = true;
        }

        _transactions.addAll(data.content);

        _page++;

        emit(
          TransactionLoadedState(
            TransactionResponse(content: List.from(_transactions)),
            hasReachedEnd: _hasReachedEnd,
          ),
        );
      },
    );

    _isLoading = false;
  }
}
