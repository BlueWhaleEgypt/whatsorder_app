import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/orders/data/make_offer_request.dart';
import 'package:whats_order/features/orders/data/order_model.dart';
import 'package:whats_order/features/orders/presentation/bloc/make_offer_event.dart';
import '../../../../base/base_repository.dart';
import '../../../../core/network/network_info.dart';
import '../../data/orders_response.dart';
import 'orders_event.dart';
import 'orders_state.dart';

/*
|--------------------------------------------------------------------------
| OrdersBloc
|--------------------------------------------------------------------------
|
| Same shape as SignInBloc: emits Loading, calls BaseRepository, maps
| Either<Failure, BaseRepository> into Loaded/Error state.
|
|--------------------------------------------------------------------------
*/
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final NetworkInfo networkInfo;

  final List<OrderModel> _orders = [];

  OrdersBloc(this.networkInfo) : super(OrdersInitial()) {
    on<FetchOrdersEvent>(_fetchOrders);
    on<ToggleOrderSelectionEvent>(_toggleOrderSelection);
    on<ViewOrderEvent>(_viewOrder);
    on<MakeOfferEvent>(_makeOffer);
  }

  Future<void> _fetchOrders(
    FetchOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(LoadingOrdersState());
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      emit(const ErrorOrdersState(message: "no_internet"));
      return;
    }
    final result = await BaseRepository('OrdersResponse').getData(event.day);

    result.fold(
      (failure) {
        emit(ErrorOrdersState(message: failure.message));
      },
      (response) {
        final ordersResponse = response as OrdersResponse;

        _orders
          ..clear()
          ..addAll(ordersResponse.orders);

        emit(
          LoadedOrdersState(
            OrdersResponse(orders: List<OrderModel>.from(_orders)),
          ),
        );
      },
    );
  }

  Future<void> _makeOffer(
    MakeOfferEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(MakeOfferLoadingState());

    final result = await BaseRepository("MakeOfferResponse").getData(
      MakeOfferRequest(
        orderId: event.orderId,
        userId: event.userId,
        offerDetails: event.offerDetails,
      ),
    );

    result.fold(
      (failure) {
        emit(MakeOfferErrorState(failure.message));
      },
      (_) {
        emit(MakeOfferSuccessState());

        add(const FetchOrdersEvent());
      },
    );
  }

  void _viewOrder(ViewOrderEvent event, Emitter<OrdersState> emit) {
    final index = _orders.indexWhere((e) => e.id == event.orderId);

    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(view: true);

    emit(
      LoadedOrdersState(OrdersResponse(orders: List<OrderModel>.from(_orders))),
    );
  }

  void _toggleOrderSelection(
    ToggleOrderSelectionEvent event,
    Emitter<OrdersState> emit,
  ) {
    final index = _orders.indexWhere((order) => order.id == event.orderId);

    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(
      isChecked: !_orders[index].isChecked,
    );
    logger.i("Selected Count: ${selectedOrders.length}");

    for (final order in selectedOrders) {
      logger.i("""
ID: ${order.id}
Phone: ${order.phone}
Components: ${order.components}
Sector: ${order.sector}
Price: ${order.price}
Cost: ${order.cost}
Latitude: ${order.latitude}
Longitude: ${order.longitude}
Date: ${order.createdDate}
-------------------------
""");
    }
    emit(
      LoadedOrdersState(OrdersResponse(orders: List<OrderModel>.from(_orders))),
    );
  }

  List<OrderModel> get selectedOrders =>
      _orders.where((e) => e.isChecked).toList();
}
