import 'package:whats_order/features/orders/presentation/bloc/orders_event.dart';

class MakeOfferEvent extends OrdersEvent {
  final int orderId;
  final String userId;
  final String offerDetails;

  const MakeOfferEvent({
    required this.orderId,
    required this.userId,
    required this.offerDetails,
  });

  @override
  List<Object?> get props => [
        orderId,
        userId,
        offerDetails,
      ];
}
