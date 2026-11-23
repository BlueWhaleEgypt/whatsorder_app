import 'dart:io';

import 'package:equatable/equatable.dart';
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
