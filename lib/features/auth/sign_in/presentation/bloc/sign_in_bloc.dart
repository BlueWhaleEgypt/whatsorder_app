import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:whats_order/core/utils/logger.dart';
import '../../../../../base/base_repository.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/utils/constants.dart';
import '../../data/sign_in_response.dart';
import 'sign_in_event.dart';
import 'sign_in_state.dart';

/*
|--------------------------------------------------------------------------
| SignInBloc
|--------------------------------------------------------------------------
|
| Manages the login flow using Bloc. Calls BaseRepository('SignInResponse')
| and maps Either<Failure, BaseRepository> to UI state.
|
|--------------------------------------------------------------------------
*/

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final NetworkInfo networkInfo;

  SignInBloc(this.networkInfo) : super(SignInInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(LoadingSignInState());

      final failureOrResult = await BaseRepository(
        'SignInResponse',
      ).getData(event.request);

      logger.w("${event.request.password}===============");
      logger.w("${event.request.phone}===============");
      debugPrint(">>>>>>>>>>>before$failureOrResult");
      emit(_mapFailureOrPostsToSigInState(failureOrResult));
      debugPrint(">>>>>>>>>>>after");
    });
  }

  SignInState _mapFailureOrPostsToSigInState(
    Either<Failure, BaseRepository> result,
  ) {
    return result.fold(
      (failure) => ErrorSignInState(message: _mapFailureToMessage(failure)),
      (response) =>
          LoadedSignInState(getSignInResponse: response as SignInResponse),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case EmptyCacheFailure:
        return EMPTY_CACHE_FAILURE_MESSAGE;
      case OfflineFailure:
        return OFFLINE_FAILURE_MESSAGE;
      default:
        return UNEXPECTED_ERROR_MESSAGE;
    }
  }
}
