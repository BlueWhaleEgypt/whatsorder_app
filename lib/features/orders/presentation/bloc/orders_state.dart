import 'package:equatable/equatable.dart';
import '../../data/orders_response.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class LoadingOrdersState extends OrdersState {}

class LoadedOrdersState extends OrdersState {
  final OrdersResponse response;

  const LoadedOrdersState(this.response);

  @override
  List<Object?> get props => [response];
}

class ErrorOrdersState extends OrdersState {
  final String message;

  const ErrorOrdersState({required this.message});

  @override
  List<Object?> get props => [message];
}

class MakeOfferLoadingState extends OrdersState {}

class MakeOfferSuccessState extends OrdersState {}

class MakeOfferErrorState extends OrdersState {
  final String message;

  MakeOfferErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
