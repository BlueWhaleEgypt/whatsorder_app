import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';

part 'verify_otp_response.g.dart';

@JsonSerializable()
class VerifyOtpResponse extends Equatable implements BaseRepository {
  final String? message;
  final String? userId;

  const VerifyOtpResponse({this.message, this.userId});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      logger.w(request);
      final response = await DioHelper.postData(
        url: "${EndPoints.baseUrl}${EndPoints.epVerifyPhone}",
        query: request,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i(response.data);
        return Right(VerifyOtpResponse.fromJson(response.data));
      }

      return Left(ServerFailure(response.data.toString()));
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
