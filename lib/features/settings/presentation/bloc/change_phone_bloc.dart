import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/phone/change_phone_response.dart';

import 'event/change_phone_event.dart';
import 'change_phone_state.dart';

class ChangePhoneBloc extends Bloc<ChangePhoneEvent, ChangePhoneState> {
  final NetworkInfo networkInfo;

  ChangePhoneBloc(this.networkInfo) : super(const ChangePhoneInitial()) {
    on<SubmitChangePhoneEvent>(_onSubmitChangePhone);
  }

  Future<void> _onSubmitChangePhone(
    SubmitChangePhoneEvent event,
    Emitter<ChangePhoneState> emit,
  ) async {
    emit(const ChangePhoneLoading());

    final result = await BaseRepository(
      'ChangePhoneResponse',
    ).getData({'userId': event.userId, 'phone': event.phone});
    logger.i(event.userId);
    logger.i(event.phone);
    result.fold(
      (failure) {
        emit(ChangePhoneError(failure.message));
      },
      (response) {
        if (response is ChangePhoneResponse) {
          emit(ChangePhoneSuccess(response));
        } else {
          emit(const ChangePhoneError('invalid_response'));
        }
      },
    );
  }
}
