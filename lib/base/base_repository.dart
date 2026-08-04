import 'package:dartz/dartz.dart';
import 'package:whats_order/features/auth/otp/data/forget_password_response.dart';
import 'package:whats_order/features/auth/otp/data/send_otp_response.dart';
import 'package:whats_order/features/auth/otp/data/verify_otp_response.dart';
import 'package:whats_order/features/orders/data/makeofferresponse.dart';
import 'package:whats_order/features/orders/notification/data/PressNotificationResponse.dart';
import 'package:whats_order/features/orders/notification/data/notification_response.dart';
import 'package:whats_order/features/orders/notification/data/press_sms_response.dart';
import 'package:whats_order/features/orders/notification/data/sms_messages_response.dart';
import 'package:whats_order/features/wallet/data/transaction_response.dart';
import 'package:whats_order/features/wallet/data/wallet_response.dart';
import '../core/error/failures.dart';
import '../features/auth/sign_in/data/sign_in_response.dart';
import '../features/auth/sign_up/data/complete_onboarding_response.dart';
import '../features/auth/sign_up/data/sector_response.dart';
import '../features/auth/sign_up/data/sign_up_response.dart';
import '../features/orders/data/orders_response.dart';

/*
|--------------------------------------------------------------------------
| BaseRepository - Dynamic Response Factory
|--------------------------------------------------------------------------
|
| Generic base for all API response models. The factory returns the
| right response model based on a `responseType` string key.
|
| Register every new feature's response model here (one line each) as
| you build it out — this is the single source of truth for response
| mapping, exactly like the original project.
|
| A Map-based lookup is included below (commented) as a cleaner
| alternative once the list of `if` branches grows large.
|--------------------------------------------------------------------------
*/

abstract class BaseRepository {
  factory BaseRepository(String responseType) {
    if (responseType == 'SignInResponse') return SignInResponse();
    if (responseType == 'OrdersResponse') return const OrdersResponse();
    if (responseType == 'SignupResponse') return const SignupResponse();
    if (responseType == 'SectorResponse') return const SectorResponse();
    if (responseType == 'CompleteOnboardingResponse')
      return const CompleteOnboardingResponse();
    if (responseType == 'SendOtpResponse') return const SendOtpResponse();
    if (responseType == 'VerifyOtpResponse') return const VerifyOtpResponse();
    if (responseType == 'ForgetPasswordResponse')
      return const ForgetPasswordResponse();
    if (responseType == 'WalletResponse') return const WalletResponse();
    if (responseType == 'TransactionResponse')
      return const TransactionResponse();
    if (responseType == 'MakeOfferResponse') return const MakeOfferResponse();
    if (responseType == 'NotificationResponse')
      return const NotificationResponse();
    if (responseType == 'SmsMessagesResponse')
      return const SmsMessagesResponse();
    if (responseType == 'PressNotificationResponse')
      return const PressNotificationResponse();
    if (responseType == 'PressSmsResponse') return const PressSmsResponse();
    // Add new feature responses above this line, e.g.:
    // if (responseType == 'WalletResponse') return const WalletResponse();

    throw 'Can\'t create $responseType.';
  }

  Future<Either<Failure, BaseRepository>> getData(dynamic request);
}

/*
|--------------------------------------------------------------------------
| OPTIONAL: cleaner Map-based version (swap in when the if-chain grows)
|--------------------------------------------------------------------------
|
| abstract class BaseRepository {
|   static final Map<String, BaseRepository Function()> _registry = {
|     'SignInResponse': () => SignInResponse(),
|     'OrdersResponse': () => const OrdersResponse(),
|   };
|
|   factory BaseRepository(String responseType) {
|     final builder = _registry[responseType];
|     if (builder == null) throw 'Can\'t create $responseType.';
|     return builder();
|   }
|
|   Future<Either<Failure, BaseRepository>> getData(dynamic request);
| }
|--------------------------------------------------------------------------
*/
