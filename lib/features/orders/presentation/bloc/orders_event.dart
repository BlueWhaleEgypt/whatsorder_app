import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrdersEvent extends OrdersEvent {
  final bool loadMore;
  final Map<String, dynamic>? query;
  final DateTime? day;

  const FetchOrdersEvent({this.query, this.loadMore = false, this.day});

  @override
  List<Object?> get props => [query, loadMore, day];
}

class ToggleOrderSelectionEvent extends OrdersEvent {
  final String orderId;

  const ToggleOrderSelectionEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class ViewOrderEvent extends OrdersEvent {
  final String orderId;

  const ViewOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
