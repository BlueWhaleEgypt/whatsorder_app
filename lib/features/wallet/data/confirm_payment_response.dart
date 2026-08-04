import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';

part 'confirm_payment_response.g.dart';

@JsonSerializable()
class ConfirmPaymentResponse extends Equatable implements BaseRepository {
  final String? sessionId;
  final String? status;
  final num? amount;
  final String? currency;

  const ConfirmPaymentResponse({
    this.sessionId,
    this.status,
    this.amount,
    this.currency,
  });
  factory ConfirmPaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$ConfirmPaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConfirmPaymentResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final params = request as Map<String, String>; // {sessionId, walletId}
      logger.w(
        "<<<<<<<<< ConfirmPaymentRequest <<<<<<<< sessionId ${params['sessionId']} walletId ${params['walletId']}",
      );

      final url =
          "${EndPoints.baseUrl}${EndPoints.epAddPaymentToMyWallet}/${params['sessionId']}";
      logger.w(url);

      final response = await DioHelper.postData(
        url: url,
        query: {'walletId': params['walletId']},
      );

      if (response.statusCode == 200) {
        logger.i(
          "<<<<<<<<< ConfirmPaymentResponse 200 <<<<<<<< ${response.data}",
        );
        return Right(ConfirmPaymentResponse.fromJson(response.data));
      }
      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } on DioException catch (e) {
      logger.e(e.response?.data);
      logger.e(e.message);

      String message = "Something went wrong";
      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        message = responseData["message"] ?? message;
      }

      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [sessionId, status, amount, currency];
}
