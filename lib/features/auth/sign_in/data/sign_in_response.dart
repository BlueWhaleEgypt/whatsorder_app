import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dartz/dartz.dart';
import '../../../../base/base_repository.dart';
import '../../../../core/cache/cache_helper.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_helper.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/utils/logger.dart';
import 'sign_in_request.dart';
import 'user_model.dart';

part 'sign_in_response.g.dart';

/*
|--------------------------------------------------------------------------
| SignInResponse
|--------------------------------------------------------------------------
|
| Data model representing the response from a login API call. Contains
| authentication tokens, user information, and optional metadata.
|
| Implements BaseRepository, supports json_serializable and Equatable.
|
|--------------------------------------------------------------------------
*/

@JsonSerializable()
// ignore: must_be_immutable
class SignInResponse extends Equatable implements BaseRepository {
  final String? name;
  final String? sectorId;
  final String? code;
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;

  const SignInResponse({
    this.name,
    this.sectorId,
    this.code,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory SignInResponse.fromJson(Map<String, dynamic> json) =>
      _$SignInResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SignInResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    final signInRequest = request as SignInRequest;
    logger.w("${request.password}===============");
    logger.w("${request.phone}===============");

    try {
      final response = await DioHelper.postData(
        url: "${EndPoints.baseUrl}${EndPoints.epLogin}",
        body: signInRequest.toJson(),
      );

      logger.i("<<<<<<<<<<< SignIn >>>>>>>>> ${response.data}");

      if (response.data is Map<String, dynamic> &&
          response.data['message'] != null &&
          (response.statusCode != 200 && response.statusCode != 201)) {
        return Left(ServerFailure(response.data['message']));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final signInResponse = SignInResponse.fromJson(response.data);
        logger.i(
          'Verification Status: ${signInResponse.user?.verificationStatus}',
        );
        await CacheHelper.saveDataSharedPreference(
          key: CacheKeys.accessToken,
          value: signInResponse.accessToken,
        );
        logger.e('<<<<<<<<<<< token >>>>>>>>> ${signInResponse.accessToken}');
        await CacheHelper.saveDataSharedPreference(
          key: CacheKeys.refreshToken,
          value: signInResponse.refreshToken,
        );
        logger.w(
          "<<<<<<<<<<< refreshToken >>>>>>>>> ${signInResponse.refreshToken}",
        );

        await CacheHelper.saveDataSharedPreference(
          key: CacheKeys.userId,
          value: signInResponse.code,
        );

        if (signInResponse.user != null) {
          await CacheHelper.saveDataSharedPreference(
            key: CacheKeys.userModel,
            value: jsonEncode(signInResponse.user!.toJson()),
          );
          await CacheHelper.saveDataSharedPreference(
            key: CacheKeys.verificationStatus,
            value: signInResponse.user!.verificationStatus ?? '',
          );
          // final userPhoto = signInResponse.user!.photo;
          // await CacheHelper.saveDataSharedPreference(
          //   key: CacheKeys.photo,
          //   value: (userPhoto != null && userPhoto.isNotEmpty) ? userPhoto : '',
          // );
        }

        final usernameToSave =
            signInResponse.user?.username ?? signInResponse.name ?? '';
        await CacheHelper.saveDataSharedPreference(
          key: CacheKeys.userName,
          value: usernameToSave,
        );

        final phoneToSave = signInResponse.user?.phone?.toString() ?? '';
        await CacheHelper.saveDataSharedPreference(
          key: CacheKeys.userPhone,
          value: phoneToSave,
        );

        return Right(signInResponse);
      } else {
        return Left(ServerFailure("Error: $response"));
      }
    } on DioException catch (e) {
      logger.e("Status Code: ${e.response?.statusCode}");
      logger.e("Response: ${e.response?.data.toString()}");

      String message = 'Something went wrong';

      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;

        message = data['detail'] ?? data['message'] ?? data['title'] ?? message;
      }

      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [
    name,
    sectorId,
    code,
    userId,
    accessToken,
    refreshToken,
    user,
  ];
}
