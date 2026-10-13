
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/settings/data/sector/sector_request.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/sectors_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/sectors_state.dart';

class SectorsBloc extends Bloc<SectorsEvent, SectorsState> {
  final NetworkInfo networkInfo;

  SectorsBloc(this.networkInfo) : super(const SectorsInitial()) {
    on<AddSectorEvent>(_onAdd);
    on<DeleteSectorEvent>(_onDelete);
  }

  Future<void> _onAdd(
    AddSectorEvent event,
    Emitter<SectorsState> emit,
  ) async {
    await _performMutation(
      emit: emit,
      userId: event.userId,
      sectorId: event.sectorId,
      action: 'add',
      successMessage: 'sector added successfully',
    );
  }

  Future<void> _onDelete(
    DeleteSectorEvent event,
    Emitter<SectorsState> emit,
  ) async {
    await _performMutation(
      emit: emit,
      userId: event.userId,
      sectorId: event.sectorId,
      action: 'delete',
      successMessage: 'sector removed successfully',
    );
  }

  Future<void> _performMutation({
    required Emitter<SectorsState> emit,
    required String userId,
    required String sectorId,
    required String action,
    required String successMessage,
  }) async {
    final previousState = state;

    final sectors = previousState.sectors;
    final assignedIds = previousState.assignedSectorIds;

    emit(
      SectorsActionLoading(
        sectors: sectors,
        assignedSectorIds: assignedIds,
      ),
    );

    try {
      final hasConnection = await networkInfo.isConnected;

      if (!hasConnection) {
        emit(
          SectorsError(
            messageKey: 'no_internet',
            sectors: sectors,
            assignedSectorIds: assignedIds,
          ),
        );
        return;
      }

      final request = action == 'add'
          ? SectorRequest.add(
              userId: userId,
              sectorId: sectorId,
            )
          : SectorRequest.delete(
              userId: userId,
              sectorId: sectorId,
            );

      final result = await BaseRepository(
        'SectorTapResponse',
      ).getData(request);

      result.fold(
        (failure) {
          emit(
            SectorsError(
              messageKey: failure.message,
              sectors: sectors,
              assignedSectorIds: assignedIds,
            ),
          );
        },
        (_) {
          final updatedIds = action == 'add'
              ? <String>{...assignedIds, sectorId}.toList()
              : assignedIds
                  .where((id) => id != sectorId)
                  .toList();

          emit(
            SectorsActionSuccess(
              messageKey: successMessage,
              sectors: sectors,
              assignedSectorIds: updatedIds,
            ),
          );
        },
      );
    } catch (_) {
      emit(
        SectorsError(
          messageKey: 'something_went_wrong',
          sectors: sectors,
          assignedSectorIds: assignedIds,
        ),
      );
    }
  }
}
