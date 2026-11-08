import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/logger.dart';

import 'event/delete_product_event.dart';
import 'states/delete_product_state.dart';

class DeleteProductBloc extends Bloc<DeleteProductEvent, DeleteProductState> {
  final NetworkInfo networkInfo;

  DeleteProductBloc(this.networkInfo) : super(const DeleteProductInitial()) {
    on<SubmitDeleteProductEvent>(_onDelete);
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

  Future<void> _onDelete(
    SubmitDeleteProductEvent event,
    Emitter<DeleteProductState> emit,
  ) async {
    if (!await _isOnline()) {
      emit(const DeleteProductError('no_internet'));
      return;
    }

    emit(DeleteProductLoading(event.productId));

    try {
      final result = await BaseRepository(
        'DeleteProductResponse',
      ).getData(event.productId);

      result.fold(
        (failure) => emit(DeleteProductError(failure.message)),
        (_) => emit(const DeleteProductSuccess('product_deleted_successfully')),
      );
    } catch (e, st) {
      logger.e('Delete product failed: $e\n$st');
      emit(const DeleteProductError('something_went_wrong'));
    }
  }
}
