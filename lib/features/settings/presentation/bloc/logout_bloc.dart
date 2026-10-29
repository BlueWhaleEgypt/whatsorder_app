import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/cache/session_cleaner.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'event/logout_event.dart';
import 'states/logout_state.dart';

/// Logout policy: the local session is always cleared, even when the server
/// call fails, so a network problem never leaves the user signed in. A server
/// failure is still reported as [LogoutFailure] (never as success) because the
/// refresh token was not revoked on the server.
class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final NetworkInfo networkInfo;
  final SessionCleaner sessionCleaner;

  LogoutBloc(
    this.networkInfo,
    this.sessionCleaner, 
   
  ):
       super(const LogoutInitial()) {
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<LogoutState> emit,
  ) async {
    if (state is LogoutLoading) return;

    emit(const LogoutLoading());

    final result = await BaseRepository('LogoutResponse').getData(null);

    try {
      await sessionCleaner.clear();
    } catch (_) {
      emit(const LogoutFailure('logout_local_failed', sessionCleared: false));
      return;
    }

    result.fold(
      (_) => emit(
        const LogoutFailure('logout_server_failed', sessionCleared: true),
      ),
      (_) => emit(const LogoutSuccess()),
    );
  }
}
