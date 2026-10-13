
import 'package:equatable/equatable.dart';
import 'package:whats_order/features/auth/sign_up/data/sector_model.dart';

abstract class SectorsState extends Equatable {
  final List<SectorModel> sectors;
  final List<String> assignedSectorIds;

  const SectorsState({
    this.sectors = const [],
    this.assignedSectorIds = const [],
  });

  @override
  List<Object?> get props => [sectors, assignedSectorIds];
}

class SectorsInitial extends SectorsState {
  const SectorsInitial();
}

class SectorsLoading extends SectorsState {
  const SectorsLoading({
    super.sectors,
    super.assignedSectorIds,
  });
}

class SectorsLoaded extends SectorsState {
  const SectorsLoaded({
    required super.sectors,
    super.assignedSectorIds,
  });
}

class SectorsActionLoading extends SectorsState {
  const SectorsActionLoading({
    super.sectors,
    super.assignedSectorIds,
  });
}

class SectorsActionSuccess extends SectorsState {
  final String messageKey;

  const SectorsActionSuccess({
    required this.messageKey,
    required super.sectors,
    required super.assignedSectorIds,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        messageKey,
      ];
}

class SectorsError extends SectorsState {
  final String messageKey;

  const SectorsError({
    required this.messageKey,
    super.sectors,
    super.assignedSectorIds,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        messageKey,
      ];
}
