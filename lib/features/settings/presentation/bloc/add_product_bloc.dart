import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/product/add_product_response.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/data/product/update_product_response.dart';

import 'event/add_product_event.dart';
import 'states/add_product_state.dart';

class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  final NetworkInfo networkInfo;

  AddProductBloc(this.networkInfo) : super(const AddProductInitial()) {
    on<SubmitAddProductEvent>(_onSubmit);
    on<SubmitUpdateProductEvent>(_onUpdate);
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
    await _run(
      emit: emit,
      responseType: 'AddProductResponse',
      request: event.request,
      successMessage: 'product_added_successfully',
      productOf: (response) => (response as AddProductResponse).product,
    );
  }

  Future<void> _onUpdate(
    SubmitUpdateProductEvent event,
    Emitter<AddProductState> emit,
  ) async {
    await _run(
      emit: emit,
      responseType: 'UpdateProductResponse',
      request: event.request,
      successMessage: 'product_updated_successfully',
      productOf: (response) => (response as UpdateProductResponse).product,
    );
  }

  Future<void> _run({
    required Emitter<AddProductState> emit,
    required String responseType,
    required Object request,
    required String successMessage,
    required ProductModel? Function(BaseRepository response) productOf,
  }) async {
    if (!await _isOnline()) {
      emit(const AddProductError('no_internet'));
      return;
    }

    emit(const AddProductLoading());

    try {
      final result = await BaseRepository(responseType).getData(request);

      result.fold(
        (failure) => emit(AddProductError(failure.message)),
        (response) => emit(
          AddProductSuccess(successMessage, product: productOf(response)),
        ),
      );
    } catch (e, st) {
      logger.e('Product submit ($responseType) failed: $e\n$st');
      emit(const AddProductError('something_went_wrong'));
    }
  }
}
