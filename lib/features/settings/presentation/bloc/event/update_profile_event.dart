
import 'package:equatable/equatable.dart';

import 'package:whats_order/features/settings/data/profile/update_profile_request.dart';

abstract class UpdateProfileEvent extends Equatable {
  const UpdateProfileEvent();

  @override
  List<Object?> get props => [];
}

class SubmitUpdateProfileEvent extends UpdateProfileEvent {
  final UpdateProfileRequest request;

  const SubmitUpdateProfileEvent({
    required this.request,
  });

  @override
  List<Object?> get props => [request.userId, request.fields, request.files];
}
