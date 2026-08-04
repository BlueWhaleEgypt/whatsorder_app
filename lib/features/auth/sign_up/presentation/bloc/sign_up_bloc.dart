import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../base/base_repository.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/utils/constants.dart';
import '../../data/sign_up_response.dart';
import 'sign_up_event.dart';
import 'sign_up_state.dart';

/*
|--------------------------------------------------------------------------
| SignUpBloc — same shape as SignInBloc: calls
| BaseRepository('SignupResponse').getData(request) and maps the result.
|--------------------------------------------------------------------------
*/

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final NetworkInfo networkInfo;

  SignUpBloc(this.networkInfo) : super(SignUpInitial()) {
    on<SubmitSignUpEvent>((event, emit) async {
      emit(LoadingSignUpState());

      final failureOrResult =
          await BaseRepository('SignupResponse').getData(event.request);

      emit(failureOrResult.fold(
        (failure) => ErrorSignUpState(message: _mapFailureToMessage(failure)),
        (response) => LoadedSignUpState(response: response as SignupResponse),
      ));
    });
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
