import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/settings/data/store_profile/store_profile_response.dart';

abstract class StoreProfileEvent extends Equatable {
  const StoreProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadStoreProfileEvent extends StoreProfileEvent {
  const LoadStoreProfileEvent();
}

class SaveStoreProfileEvent extends StoreProfileEvent {
  final StoreProfile profile;
  final File? newPhoto;
  const SaveStoreProfileEvent(this.profile, {this.newPhoto});
  @override
  List<Object?> get props => [profile, newPhoto?.path];
}

abstract class StoreProfileState extends Equatable {
  const StoreProfileState();
  @override
  List<Object?> get props => [];
}

class StoreProfileInitial extends StoreProfileState {
  const StoreProfileInitial();
}

class StoreProfileLoading extends StoreProfileState {
  const StoreProfileLoading();
}

class StoreProfileLoaded extends StoreProfileState {
  final StoreProfile profile;
  const StoreProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class StoreProfileSaving extends StoreProfileState {
  const StoreProfileSaving();
}

class StoreProfileSaved extends StoreProfileState {
  final StoreProfile profile;
  const StoreProfileSaved(this.profile);
  @override
  List<Object?> get props => [profile];
}

class StoreProfileError extends StoreProfileState {
  final String message;

  /// True when the failure happened while saving (the form must stay as is).
  final bool whileSaving;
  const StoreProfileError(this.message, {this.whileSaving = false});
  @override
  List<Object?> get props => [message, whileSaving];
}

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
