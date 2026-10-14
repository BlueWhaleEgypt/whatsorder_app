import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/error/failures.dart';

import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';

import '../../../../core/utils/logger.dart';

class ChangePasswordResponse extends Equatable implements BaseRepository {
  final String? message;

  const ChangePasswordResponse({this.message});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(message: json['message']?.toString());
  }

  @override
  List<Object?> get props => [message];

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final body = {
        'plainPassword': request['plainPassword'],
        'newPassword': request['newPassword'],
        'userId': request['userId'],
      };
      logger.w(body);
      final response = await DioHelper.postData(
        url: '${EndPoints.baseUrl}${EndPoints.epSaveNewPassword}',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        await CacheHelper.removeData(key: CacheKeys.rememberMe);
        logger.i(data);
        return const Right(
          ChangePasswordResponse(message: 'password_changed_successfully'),
        );
      }

      return const Left(ServerFailure('request_failed'));
    } on DioException catch (e) {
      logger.e('Change Password URL: ${e.requestOptions.uri}');
      logger.e('Change Password METHOD: ${e.requestOptions.method}');
      logger.e('Change Password STATUS: ${e.response?.statusCode}');
      logger.e('Change Password RESPONSE: ${e.response?.data}');

      final data = e.response?.data;

      final message = data is Map ? data['message']?.toString() : null;

      return Left(ServerFailure(message ?? 'password_change_failed'));
    } catch (e) {
      logger.e('Change Password Error: $e');

      return const Left(ServerFailure('something_went_wrong'));
    }
  }
}
