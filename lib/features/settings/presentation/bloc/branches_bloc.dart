import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/branch/branch_request.dart';

import '../../data/branch/branch_model.dart';
import '../../data/branch/branches_response.dart';
import 'event/branches_event.dart';
import 'states/branches_state.dart';

class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
  final NetworkInfo networkInfo;

  List<BranchModel> _branches = [];

  BranchesBloc(this.networkInfo) : super(const BranchesInitialState()) {
    on<FetchBranchesEvent>(_onFetch);
    on<AddBranchEvent>(_onAdd);
    on<UpdateBranchEvent>(_onUpdate);
    on<DeleteBranchEvent>(_onDelete);
  }

  /// A failed connectivity check must never block a request, so treat an
  /// error while checking as "connected" and let the request itself decide.
  Future<bool> _isOnline() async {
    try {
      return await networkInfo.isConnected;
    } catch (e) {
      logger.e('Connectivity check failed: $e');
      return true;
    }
  }

  /// After a failed request, report `no_internet` if the connection is gone.
  Future<String> _failureMessage(String message) async =>
      await _isOnline() ? message : 'no_internet';

  Future<void> _onFetch(
    FetchBranchesEvent event,
    Emitter<BranchesState> emit,
  ) async {
    if (!await _isOnline()) {
      emit(BranchesErrorState('no_internet', branches: _branches));
      return;
    }

    emit(const BranchesLoadingState());

    try {
      final result = await BaseRepository(
        'BranchesResponse',
      ).getData(BranchRequest.fetch(userId: event.userId));

      switch (result) {
        case Left(value: final failure):
          emit(
            BranchesErrorState(
              await _failureMessage(failure.message),
              branches: _branches,
            ),
          );
        case Right(value: final response):
          _branches = (response as BranchesResponse).branches;
          emit(BranchesLoadedState(_branches));
      }
    } catch (e, st) {
      logger.e('Fetch branches failed: $e\n$st');
      emit(
        BranchesErrorState(
          await _failureMessage('something_went_wrong'),
          branches: _branches,
        ),
      );
    }
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
    if (!await _isOnline()) {
      emit(BranchesErrorState('no_internet', branches: _branches));
      return;
    }

    emit(BranchesActionLoadingState(_branches));

    // 1) The mutation itself. Never retried here: a failure is reported
    //    as such and the user decides whether to try again.
    try {
      final mutation = await BaseRepository(
        'BranchesResponse',
      ).getData(request);

      if (mutation.isLeft()) {
        final message = mutation.fold((f) => f.message, (_) => '');
        emit(
          BranchesErrorState(
            await _failureMessage(message),
            branches: _branches,
          ),
        );
        return;
      }
    } catch (e, st) {
      logger.e('Branch mutation failed: $e\n$st');
      emit(
        BranchesErrorState(
          await _failureMessage('something_went_wrong'),
          branches: _branches,
        ),
      );
      return;
    }

    // 2) The mutation succeeded: refresh the list. If that fails the change
    //    is still saved, so say so instead of reporting a plain failure.
    try {
      final refresh = await BaseRepository(
        'BranchesResponse',
      ).getData(BranchRequest.fetch(userId: userId));

      switch (refresh) {
        case Left():
          emit(
            BranchesErrorState(
              'branch_saved_refresh_failed',
              branches: _branches,
            ),
          );
        case Right(value: final response):
          _branches = (response as BranchesResponse).branches;
          emit(
            BranchesActionSuccessState(
              message: successMessage,
              branches: _branches,
            ),
          );
      }
    } catch (e, st) {
      logger.e('Branch list refresh failed: $e\n$st');
      emit(
        BranchesErrorState('branch_saved_refresh_failed', branches: _branches),
      );
    }
  }
}
