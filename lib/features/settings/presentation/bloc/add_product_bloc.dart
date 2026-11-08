import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/product/add_product_response.dart';

import 'event/add_product_event.dart';
import 'states/add_product_state.dart';

class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  final NetworkInfo networkInfo;

  AddProductBloc(this.networkInfo) : super(const AddProductInitial()) {
    on<SubmitAddProductEvent>(_onSubmit);
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

  Future<void> _onSubmit(
    SubmitAddProductEvent event,
    Emitter<AddProductState> emit,
  ) async {
    if (!await _isOnline()) {
      emit(const AddProductError('no_internet'));
      return;
    }

    emit(const AddProductLoading());

    try {
      final result = await BaseRepository(
        'AddProductResponse',
      ).getData(event.request);

      result.fold(
        (failure) => emit(AddProductError(failure.message)),
        (response) => emit(
          AddProductSuccess(
            'product_added_successfully',
            product: (response as AddProductResponse).product,
          ),
        ),
      );
    } catch (e, st) {
      logger.e('Add product failed: $e\n$st');
      emit(const AddProductError('something_went_wrong'));
    }
  }
}
