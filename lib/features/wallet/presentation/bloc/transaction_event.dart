part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class GetTransactionsEvent extends TransactionEvent {
  final bool loadMore;

  const GetTransactionsEvent({this.loadMore = false});

  @override
  List<Object?> get props => [loadMore];
}
