
import 'package:equatable/equatable.dart';

abstract class SectorsEvent extends Equatable {
  const SectorsEvent();

  @override
  List<Object?> get props => [];
}

class AddSectorEvent extends SectorsEvent {
  final String userId;
  final String sectorId;

  const AddSectorEvent({
    required this.userId,
    required this.sectorId,
  });

  @override
  List<Object?> get props => [userId, sectorId];
}

class DeleteSectorEvent extends SectorsEvent {
  final String userId;
  final String sectorId;

  @override
  List<Object?> get props => [userId, sectorId];

  const DeleteSectorEvent({
    required this.userId,
    required this.sectorId,
  });
}
