import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_response.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';

class UpdateProfileBloc extends Bloc<UpdateProfileEvent, UpdateProfileState> {
  final NetworkInfo networkInfo;

  UpdateProfileBloc(this.networkInfo) : super(const UpdateProfileInitial()) {
    on<SubmitUpdateProfileEvent>(_onSubmitUpdateProfile);
  }

  Future<void> _onSubmitUpdateProfile(
    SubmitUpdateProfileEvent event,
    Emitter<UpdateProfileState> emit,
  ) async {
    emit(const UpdateProfileLoading());

    try {
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        emit(const UpdateProfileError('no_internet'));
        return;
      }

      final result = await BaseRepository(
        'UpdateProfileResponse',
      ).getData(event.request);

      result.fold(
        (failure) {
          emit(UpdateProfileError(failure.message));
        },
        (repository) {
          if (repository is UpdateProfileResult) {
            emit(UpdateProfileSuccess(repository.message));
          } else {
            emit(const UpdateProfileSuccess('profile_updated_successfully'));
          }
        },
      );
    } catch (e, s) {
      logger.e('Update profile failed: $e\n$s');
      emit(const UpdateProfileError('something_went_wrong'));
    }
  }
}
