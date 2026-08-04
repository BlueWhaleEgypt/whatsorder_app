import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/wallet/data/payment_checkout_request.dart';

part 'payment_checkout_response.g.dart';

@JsonSerializable()
class PaymentCheckoutResponse extends Equatable implements BaseRepository {
  final String? paymentUrl;

  const PaymentCheckoutResponse({this.paymentUrl});

  factory PaymentCheckoutResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentCheckoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCheckoutResponseToJson(this);

  /// يستخرج sessionId من الجزء اللي بعد /session/ في الرابط
  String? get sessionId {
    final url = paymentUrl;
    if (url == null) return null;
    const marker = '/session/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    final rest = url.substring(idx + marker.length);
    return rest.split('?').first.split('/').first;
  }

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final req = request as PaymentCheckoutRequest;
      logger.w(
        "<<<<<<<<<<<< PaymentCheckoutRequest >>>>>>>>>>>>>>>>>>>>> ${req.toJson()}",
      );
      const url = "${EndPoints.baseUrl}${EndPoints.epPaymentCheckout}";
      logger.i(url);
      final response = await DioHelper.postData(url: url, body: req.toJson());
      logger.i(
        "<<<<<<<<<<<<<< PaymentCheckoutResponse >>>>>>>>>>>>>>>>>>>>> ${response.data}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i(
          "<<<<<<<<<<<<<< PaymentCheckout  200  Response >>>>>>>>>>>>>>>>>>>>> ${response.data}",
        );
        return Right(PaymentCheckoutResponse.fromJson(response.data));
      }
      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } on DioException catch (e) {
      logger.e(e.response?.data);
      logger.e(e.response?.data['message']);
      logger.e(e.message);
      String message = "Something went wrong";
      if (e.response?.data is Map<String, dynamic>) {
        message = e.response!.data["message"] ?? message;
      }
      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [paymentUrl];
}
