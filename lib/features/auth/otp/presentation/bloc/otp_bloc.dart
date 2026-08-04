import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/network_info.dart';
import 'package:whats_order/features/auth/otp/data/forget_password_response.dart';
import 'package:whats_order/features/auth/otp/data/send_otp_response.dart';
import 'package:whats_order/features/auth/otp/data/verify_otp_response.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final NetworkInfo networkInfo;

  OtpBloc(this.networkInfo) : super(OtpInitial()) {
    on<SendOtpEvent>(_sendOtp);
    on<VerifyOtpEvent>(_verifyOtp);
    on<ForgetPasswordEvent>(_forgetPassword);
  }

  Future<void> _sendOtp(SendOtpEvent event, Emitter<OtpState> emit) async {
    emit(LoadingOtpState());

    final result = await BaseRepository("SendOtpResponse").getData(event.phone);

    emit(
      result.fold(
        (failure) => ErrorOtpState((failure as ServerFailure).message),
        (response) => LoadedOtpState(response as SendOtpResponse),
      ),
    );
  }

  Future<void> _verifyOtp(VerifyOtpEvent event, Emitter<OtpState> emit) async {
    emit(LoadingOtpState());

    final result = await BaseRepository(
      "VerifyOtpResponse",
    ).getData({"phone": event.phone, "otp": event.otp});

    emit(
      result.fold(
        (failure) => ErrorOtpState((failure as ServerFailure).message),
        (response) => VerifiedOtpState(response as VerifyOtpResponse),
      ),
    );
  }

  Future<void> _forgetPassword(
    ForgetPasswordEvent event,
    Emitter<OtpState> emit,
  ) async {
    emit(LoadingOtpState());

    final result = await BaseRepository(
      "ForgetPasswordResponse",
    ).getData({"userId": event.userId, "newPassword": event.newPassword});

    emit(
      result.fold(
        (failure) =>
            ForgetPasswordErrorState((failure as ServerFailure).message),
        (response) =>
            ForgetPasswordSuccessState(response as ForgetPasswordResponse),
      ),
    );
  }
}
