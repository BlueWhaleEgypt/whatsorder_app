import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../base/base_repository.dart';
import '../../../../core/cache/cache_helper.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_helper.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/utils/logger.dart';
import 'sign_up_request.dart';

/*
|--------------------------------------------------------------------------
| SignupResponse
|--------------------------------------------------------------------------
|
| Response for the unified POST /api/auth/signup multipart call.
| Real response body: { "message": "...", "userId": "..." }
|
| On success, the userId is cached in SharedPreferences for use in
| subsequent authenticated requests (e.g. phone verify).
|--------------------------------------------------------------------------
*/

class SignupResponse extends Equatable implements BaseRepository {
  final String? message;
  final String? userId;

  const SignupResponse({this.message, this.userId});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      message: json['message'] as String?,
      userId: json['userId'] as String?,
    );
  }

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    final signUpRequest = request as SignUpRequest;
    try {
      final formData = await signUpRequest.toFormData();
      logger.i('<<<<<<<<<< SignUp >>>>>>>>>> ${formData.fields}');
      final response = await DioHelper.postData(
        url: '${EndPoints.baseUrl}${EndPoints.epSignup}',
        body: null,
        isForm: false,
        formDataOverride: formData,
      );

      logger.i('<<<<<<<<<< SignUp >>>>>>>>>> ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final signupResponse = SignupResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (signupResponse.userId != null) {
          await CacheHelper.saveDataSharedPreference(
            key: CacheKeys.userId,
            value: signupResponse.userId,
          );
        }

        return Right(signupResponse);
      } else {
        logger.i('<<<<<<<<<< error >>>>>>>>>> ${response.data}');

        return Left(ServerFailure('Error: ${response.data}'));
      }
    } on DioException catch (e) {
      logger.e("Status Code: ${e.response?.statusCode}");
      logger.e("Response: ${e.response?.data}");

      String message = 'Something went wrong';

      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;

        message = data['detail'] ?? data['message'] ?? data['title'] ?? message;
      }

      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [message, userId];
}
