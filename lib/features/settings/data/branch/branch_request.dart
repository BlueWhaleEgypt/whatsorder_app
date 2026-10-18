import 'package:whats_order/features/settings/data/branch/branch_action.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';

class BranchRequest {
  final BranchAction action;
  final String userId;
  final String? branchId;
  final BranchModel? branch;

  const BranchRequest.fetch({required this.userId})
    : action = BranchAction.fetch,
      branchId = null,
      branch = null;

  const BranchRequest.add({required this.userId, required this.branch})
    : action = BranchAction.add,
      branchId = null;

  const BranchRequest.update({
    required this.userId,
    required this.branchId,
    required this.branch,
  }) : action = BranchAction.update;

  const BranchRequest.delete({required this.userId, required this.branchId})
    : action = BranchAction.delete,
      branch = null;
}
