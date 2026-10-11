import 'package:equatable/equatable.dart';
import '../../data/branch_model.dart';

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

  const BranchesErrorState(
    this.message, {
    this.branches = const [],
  });

  @override
  List<Object?> get props => [message, branches];
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
