import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';

part 'send_otp_response.g.dart';

@JsonSerializable()
class SendOtpResponse extends Equatable implements BaseRepository {
  final String? message;

  const SendOtpResponse({this.message});

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$SendOtpResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendOtpResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      logger.i("<<<<<< Send OTP ${request}");

      final response = await DioHelper.postData(
        url: "${EndPoints.baseUrl}${EndPoints.epSendOtp}",
        query: {"phone": request},
      );

      logger.i("<<<<<< Send OTP >>>>>> ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(SendOtpResponse.fromJson(response.data));
      }

      return Left(ServerFailure("Error ${response.statusCode}"));
    } catch (e) {
      logger.e(e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  List<Object?> get props => [message];
}
