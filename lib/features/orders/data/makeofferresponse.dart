import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/orders/data/make_offer_request.dart';

part 'makeofferresponse.g.dart';

@JsonSerializable()
class MakeOfferResponse extends Equatable implements BaseRepository {
  const MakeOfferResponse();

  factory MakeOfferResponse.fromJson(Map<String, dynamic> json) =>
      _$MakeOfferResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MakeOfferResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      logger.i("========== MAKE OFFER REQUEST ==========");
      logger.i("URL: ${EndPoints.baseUrl}${EndPoints.epMakeOffer}");
      logger.i("BODY: ${request.toJson()}");
      final body = request as MakeOfferRequest;

      final response = await DioHelper.postData(
        url: "${EndPoints.baseUrl}${EndPoints.epMakeOffer}",
        body: body.toJson(),
      );
      logger.i("========== MAKE OFFER RESPONSE ==========");
      logger.i("Status Code: ${response.statusCode}");
      logger.i("Status Message: ${response.statusMessage}");
      logger.i("Response Data: ${response.data}");

      if (response.statusCode == 200) {
        return const Right(MakeOfferResponse());
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } on DioException catch (e) {
      String message = "Something went wrong";
      logger.e("========== DIO EXCEPTION ==========");
      logger.e("Message: ${e.message}");
      logger.e("Status Code: ${e.response?.statusCode}");
      logger.e("Response: ${e.response?.data}");
      if (e.response?.data is Map<String, dynamic>) {
        message =
            e.response!.data["message"] ??
            e.response!.data["detail"] ??
            message;
      }

      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [];
}
