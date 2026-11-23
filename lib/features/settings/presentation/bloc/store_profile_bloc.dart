import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/settings/data/store_profile/store_profile_response.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/store_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/store_profile_state.dart';

class StoreProfileBloc extends Bloc<StoreProfileEvent, StoreProfileState> {
  final NetworkInfo networkInfo;

  StoreProfileBloc(this.networkInfo) : super(const StoreProfileInitial()) {
    on<LoadStoreProfileEvent>((event, emit) async {
      emit(const StoreProfileLoading());
      final r = await _call(const LoadStoreProfileRequest());
      emit(r.fold((m) => StoreProfileError(m), (p) => StoreProfileLoaded(p)));
    });

    on<SaveStoreProfileEvent>((event, emit) async {
      emit(const StoreProfileSaving());
      final r = await _call(
        SaveStoreProfileRequest(event.profile, newPhoto: event.newPhoto),
      );
      emit(
        r.fold(
          (m) => StoreProfileError(m, whileSaving: true),
          (p) => StoreProfileSaved(p),
        ),
      );
    });
  }

  Future<Either<String, StoreProfile>> _call(
    StoreProfileRequest request,
  ) async {
    if (!await networkInfo.isConnected) return const Left('no_internet');
    final result = await BaseRepository(
      'StoreProfileResponse',
    ).getData(request);
    return result.fold(
      (f) => Left(f.message),
      (res) => (res as StoreProfileResponse).profile != null
          ? Right(res.profile!)
          : const Left('something_went_wrong'),
    );
  }
}
