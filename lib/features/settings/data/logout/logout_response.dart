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

/// Result of `POST /api/auth/logout`, which invalidates the refresh token.
class LogoutResponse extends Equatable implements BaseRepository {
  const LogoutResponse();

  @override
  List<Object?> get props => [];

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final response = await DioHelper.postData(
        url: EndPoints.epLogout,
        body: {
          'refreshToken':
              CacheHelper.getDataFromSharedPreference(
                key: CacheKeys.accessToken,
              ) ??
              '',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i(response.data);

        return const Right(LogoutResponse());
      }

      return const Left(ServerFailure('request_failed'));
    } on DioException catch (e) {
      logger.e('Logout STATUS: ${e.response?.statusCode}');
      logger.e('Logout RESPONSE: ${e.response?.data}');

      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;

      return Left(ServerFailure(message ?? 'logout_server_failed'));
    } catch (e) {
      logger.e('Logout Error: $e');

      return const Left(ServerFailure('something_went_wrong'));
    }
  }
}
