import 'package:equatable/equatable.dart';
import 'package:whats_order/features/settings/data/store_profile/store_profile_response.dart';

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
