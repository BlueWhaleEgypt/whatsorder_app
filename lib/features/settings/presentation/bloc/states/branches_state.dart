import 'package:equatable/equatable.dart';
import '../../../data/branch/branch_model.dart';

abstract class BranchesState extends Equatable {
  const BranchesState();

  @override
  List<Object?> get props => [];
}

class BranchesInitialState extends BranchesState {
  const BranchesInitialState();
}

class BranchesLoadingState extends BranchesState {
  const BranchesLoadingState();
}

class BranchesLoadedState extends BranchesState {
  final List<BranchModel> branches;

  const BranchesLoadedState(this.branches);

  @override
  List<Object?> get props => [branches];
}

class BranchesActionLoadingState extends BranchesState {
  final List<BranchModel> branches;

  const BranchesActionLoadingState(this.branches);

  @override
  List<Object?> get props => [branches];
}

class BranchesErrorState extends BranchesState {
  final String message;
  final List<BranchModel> branches;

  const BranchesErrorState(this.message, {this.branches = const []});

  // Every error is its own event: repeating the same failure (e.g. offline
  // twice in a row) must still reach the UI, so equality is by identity.
  @override
  List<Object?> get props => [identityHashCode(this)];
}

class BranchesActionSuccessState extends BranchesState {
  final String message;
  final List<BranchModel> branches;

  const BranchesActionSuccessState({
    required this.message,
    required this.branches,
  });

  @override
  List<Object?> get props => [message, branches];
}
