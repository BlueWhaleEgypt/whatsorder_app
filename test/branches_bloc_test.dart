import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/branches_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/branches_state.dart';

class _OfflineNetwork implements NetworkInfo {
  int checks = 0;

  @override
  Future<bool> get isConnected async {
    checks++;
    return false;
  }
}

const _branch = BranchModel(
  id: 'b1',
  name: 'Main',
  nameEn: 'Main',
  latitude: 1,
  longitude: 2,
  address: 'A',
);

void main() {
  late _OfflineNetwork network;
  late BranchesBloc bloc;
  late List<BranchesState> emitted;

  setUp(() {
    network = _OfflineNetwork();
    bloc = BranchesBloc(network);
    emitted = [];
    bloc.stream.listen(emitted.add);
  });

  tearDown(() => bloc.close());

  final events = <String, BranchesEvent>{
    'fetch': const FetchBranchesEvent(userId: 'u'),
    'add': const AddBranchEvent(userId: 'u', branch: _branch),
    'update': const UpdateBranchEvent(
      userId: 'u',
      branchId: 'b1',
      branch: _branch,
    ),
    'delete': const DeleteBranchEvent(userId: 'u', branchId: 'b1'),
  };

  for (final entry in events.entries) {
    test('${entry.key} offline: no request, no loading, no_internet', () async {
      bloc.add(entry.value);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted, hasLength(1), reason: 'no loading state is emitted');
      final state = emitted.single as BranchesErrorState;
      expect(state.message, 'no_internet');
      expect(state.branches, isEmpty);
      expect(network.checks, 1, reason: 'connectivity checked once');
    });
  }

  test('a second offline attempt works the same (no stuck state)', () async {
    bloc.add(const FetchBranchesEvent(userId: 'u'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(const DeleteBranchEvent(userId: 'u', branchId: 'b1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(emitted.whereType<BranchesErrorState>(), hasLength(2));
    expect(emitted.whereType<BranchesActionSuccessState>(), isEmpty);
  });
}
