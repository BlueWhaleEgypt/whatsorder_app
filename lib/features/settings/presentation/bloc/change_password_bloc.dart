import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/settings/data/password/change_password_response.dart';

import 'event/change_password_event.dart';
import 'change_password_state.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final NetworkInfo networkInfo;

  ChangePasswordBloc(this.networkInfo) : super(const ChangePasswordInitial()) {
    on<SubmitChangePasswordEvent>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitChangePasswordEvent event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordLoading());

    final result = await BaseRepository('ChangePasswordResponse').getData({
      'userId': event.userId,
      'plainPassword': event.plainPassword,
      'newPassword': event.newPassword,
    });

    result.fold(
      (failure) {
        emit(ChangePasswordError(failure.toString()));
      },
      (response) {
        final message = response is ChangePasswordResponse
            ? response.message ?? 'Password changed successfully'
            : 'Password changed successfully';

        emit(ChangePasswordSuccess(message));
      },
    );
  }
}
