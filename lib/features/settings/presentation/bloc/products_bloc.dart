import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/product/products_request.dart';
import 'package:whats_order/features/settings/data/product/products_response.dart';

import 'event/products_event.dart';
import 'states/products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final NetworkInfo networkInfo;

  ProductsBloc(this.networkInfo) : super(const ProductsInitialState()) {
    on<FetchProductsEvent>(_onFetch);
  }

  /// A failed connectivity check must never block a request.
  Future<bool> _isOnline() async {
    try {
      return await networkInfo.isConnected;
    } catch (e) {
      logger.e('Connectivity check failed: $e');
      return true;
    }
  }

  Future<void> _onFetch(
    FetchProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    if (!await _isOnline()) {
      emit(const ProductsErrorState('no_internet'));
      return;
    }

    emit(const ProductsLoadingState());

    try {
      final result = await BaseRepository(
        'ProductsResponse',
      ).getData(ProductsRequest(vendorId: event.vendorId));

      result.fold(
        (failure) => emit(ProductsErrorState(failure.message)),
        (response) =>
            emit(ProductsLoadedState((response as ProductsResponse).products)),
      );
    } catch (e, st) {
      logger.e('Fetch products failed: $e\n$st');
      emit(const ProductsErrorState('something_went_wrong'));
    }
  }
}
