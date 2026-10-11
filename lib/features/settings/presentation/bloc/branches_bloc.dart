// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:whats_order/features/settings/data/branch_request.dart';

// import '../../data/branch_model.dart';
// import '../../data/branches_response.dart';
// import 'branches_event.dart';
// import 'branches_state.dart';

// class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
//   final BranchesResponse repository;

//   List<BranchModel> _branches = [];

//   BranchesBloc({BranchesResponse? repository})
//       : repository = repository ?? const BranchesResponse(),
//         super(const BranchesInitialState()) {
//     on<FetchBranchesEvent>(_onFetch);
//     on<AddBranchEvent>(_onAdd);
//     on<UpdateBranchEvent>(_onUpdate);
//     on<DeleteBranchEvent>(_onDelete);
//   }

//   Future<void> _onFetch(
//     FetchBranchesEvent event,
//     Emitter<BranchesState> emit,
//   ) async {
//     emit(const BranchesLoadingState());

//     final result = await repository.getData(
//       BranchRequest.fetch(userId: event.userId),
//     );

//     result.fold(
//       (failure) => emit(
//         BranchesErrorState(
//           failure.message,
//           branches: _branches,
//         ),
//       ),
//       (response) {
//         _branches = (response as BranchesResponse).branches;
//         emit(BranchesLoadedState(_branches));
//       },
//     );
//   }

//   Future<void> _onAdd(
//     AddBranchEvent event,
//     Emitter<BranchesState> emit,
//   ) async {
//     await _performMutation(
//       emit: emit,
//       request: BranchRequest.add(
//         userId: event.userId,
//         branch: event.branch,
//       ),
//       userId: event.userId,
//       successMessage: 'branch_added_successfully',
//     );
//   }

//   Future<void> _onUpdate(
//     UpdateBranchEvent event,
//     Emitter<BranchesState> emit,
//   ) async {
//     await _performMutation(
//       emit: emit,
//       request: BranchRequest.update(
//         userId: event.userId,
//         branchId: event.branchId,
//         branch: event.branch,
//       ),
//       userId: event.userId,
//       successMessage: 'branch_updated_successfully',
//     );
//   }

//   Future<void> _onDelete(
//     DeleteBranchEvent event,
//     Emitter<BranchesState> emit,
//   ) async {
//     await _performMutation(
//       emit: emit,
//       request: BranchRequest.delete(
//         userId: event.userId,
//         branchId: event.branchId,
//       ),
//       userId: event.userId,
//       successMessage: 'branch_deleted_successfully',
//     );
//   }

//   Future<void> _performMutation({
//     required Emitter<BranchesState> emit,
//     required BranchRequest request,
//     required String userId,
//     required String successMessage,
//   }) async {
//     emit(BranchesActionLoadingState(_branches));

//     final result = await repository.getData(request);

//     await result.fold<Future<void>>(
//       (failure) async {
//         emit(
//           BranchesErrorState(
//             failure.message,
//             branches: _branches,
//           ),
//         );
//       },
//       (_) async {
//         final refreshResult = await repository.getData(
//           BranchRequest.fetch(userId: userId),
//         );

//         refreshResult.fold(
//           (failure) {
//             emit(
//               BranchesErrorState(
//                 failure.message,
//                 branches: _branches,
//               ),
//             );
//           },
//           (response) {
//             _branches = (response as BranchesResponse).branches;

//             emit(
//               BranchesActionSuccessState(
//                 message: successMessage,
//                 branches: _branches,
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/settings/data/branch_request.dart';

import '../../data/branch_model.dart';
import '../../data/branches_response.dart';
import 'branches_event.dart';
import 'branches_state.dart';

class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
  final NetworkInfo networkInfo;

  List<BranchModel> _branches = [];

  BranchesBloc(this.networkInfo) : super(const BranchesInitialState()) {
    on<FetchBranchesEvent>(_onFetch);
    on<AddBranchEvent>(_onAdd);
    on<UpdateBranchEvent>(_onUpdate);
    on<DeleteBranchEvent>(_onDelete);
  }

  Future<void> _onFetch(
    FetchBranchesEvent event,
    Emitter<BranchesState> emit,
  ) async {
    emit(const BranchesLoadingState());

    final result = await BaseRepository(
      'BranchesResponse',
    ).getData(BranchRequest.fetch(userId: event.userId));

    result.fold(
      (failure) =>
          emit(BranchesErrorState(failure.message, branches: _branches)),
      (response) {
        _branches = (response as BranchesResponse).branches;
        emit(BranchesLoadedState(_branches));
      },
    );
  }

  Future<void> _onAdd(AddBranchEvent event, Emitter<BranchesState> emit) async {
    await _performMutation(
      emit: emit,
      request: BranchRequest.add(userId: event.userId, branch: event.branch),
      userId: event.userId,
      successMessage: 'branch_added_successfully',
    );
  }

  Future<void> _onUpdate(
    UpdateBranchEvent event,
    Emitter<BranchesState> emit,
  ) async {
    await _performMutation(
      emit: emit,
      request: BranchRequest.update(
        userId: event.userId,
        branchId: event.branchId,
        branch: event.branch,
      ),
      userId: event.userId,
      successMessage: 'branch_updated_successfully',
    );
  }

  Future<void> _onDelete(
    DeleteBranchEvent event,
    Emitter<BranchesState> emit,
  ) async {
    await _performMutation(
      emit: emit,
      request: BranchRequest.delete(
        userId: event.userId,
        branchId: event.branchId,
      ),
      userId: event.userId,
      successMessage: 'branch_deleted_successfully',
    );
  }

  Future<void> _performMutation({
    required Emitter<BranchesState> emit,
    required BranchRequest request,
    required String userId,
    required String successMessage,
  }) async {
    emit(BranchesActionLoadingState(_branches));

    final result = await BaseRepository('BranchesResponse').getData(request);

    await result.fold<Future<void>>(
      (failure) async {
        emit(BranchesErrorState(failure.message, branches: _branches));
      },
      (_) async {
        final refreshResult = await BaseRepository(
          'BranchesResponse',
        ).getData(BranchRequest.fetch(userId: userId));

        refreshResult.fold(
          (failure) {
            emit(BranchesErrorState(failure.message, branches: _branches));
          },
          (response) {
            _branches = (response as BranchesResponse).branches;

            emit(
              BranchesActionSuccessState(
                message: successMessage,
                branches: _branches,
              ),
            );
          },
        );
      },
    );
  }
}
