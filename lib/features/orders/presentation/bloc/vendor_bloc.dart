import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/orders/data/vendor_response.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';

class VendorBloc extends Bloc<VendorEvent, VendorState> {
  final NetworkInfo networkInfo;

  VendorBloc(this.networkInfo) : super(VendorInitial()) {
    on<FetchVendorEvent>(_fetchVendor);
  }

  Future<void> _fetchVendor(
    FetchVendorEvent event,
    Emitter<VendorState> emit,
  ) async {
    emit(VendorLoading());

    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      emit(const VendorError(message: 'no_internet'));
      return;
    }

    final result = await BaseRepository('VendorResponse').getData(null);

    result.fold(
      (failure) {
        emit(VendorError(message: failure.message));
      },
      (response) {
        final vendorResponse = response as VendorResponse;

        emit(
          VendorLoaded(
            vendorResponse: vendorResponse,
          ),
        );
      },
    );
  }
}