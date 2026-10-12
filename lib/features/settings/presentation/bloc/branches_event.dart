import 'package:equatable/equatable.dart';
import '../../data/branch/branch_model.dart';

abstract class BranchesEvent extends Equatable {
  const BranchesEvent();

  @override
  List<Object?> get props => [];
}

class FetchBranchesEvent extends BranchesEvent {
  final String userId;

  const FetchBranchesEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AddBranchEvent extends BranchesEvent {
  final String userId;
  final BranchModel branch;

  const AddBranchEvent({
    required this.userId,
    required this.branch,
  });

  @override
  List<Object?> get props => [userId, branch];
}

class UpdateBranchEvent extends BranchesEvent {
  final String userId;
  final String branchId;
  final BranchModel branch;

  const UpdateBranchEvent({
    required this.userId,
    required this.branchId,
    required this.branch,
  });

  @override
  List<Object?> get props => [userId, branchId, branch];
}

class DeleteBranchEvent extends BranchesEvent {
  final String userId;
  final String branchId;

  const DeleteBranchEvent({
    required this.userId,
    required this.branchId,
  });

  @override
  List<Object?> get props => [userId, branchId];
}
