part of 'transaction_bloc.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoadingState extends TransactionState {}

class TransactionLoadedState extends TransactionState {
  final TransactionResponse response;
  final bool hasReachedEnd;

  const TransactionLoadedState(this.response, {required this.hasReachedEnd});

  @override
  List<Object?> get props => [response, hasReachedEnd];
}

class TransactionErrorState extends TransactionState {
  final String message;

  const TransactionErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
