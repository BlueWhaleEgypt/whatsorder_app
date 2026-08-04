import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dartz/dartz.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import '../../../base/base_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/end_points.dart';
import '../../../core/utils/logger.dart';
import 'order_model.dart';

part 'orders_response.g.dart';

/*
|--------------------------------------------------------------------------
| OrdersResponse
|--------------------------------------------------------------------------
|
| Fetches the list of orders shown on the home screen. Same shape as
| SignInResponse: implements BaseRepository, json_serializable + Equatable.
|
|--------------------------------------------------------------------------
*/
@JsonSerializable()
class OrdersResponse extends Equatable implements BaseRepository {
  final List<OrderModel> orders;

  const OrdersResponse({this.orders = const []});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) =>
      _$OrdersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrdersResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final user = UserModel.fromJson(
        jsonDecode(
          CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
              '{}',
        ),
      );
      logger.i("<<<<<<<<<<< User ID >>>>>>>>> ${user.id}");
      // final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      logger.i(
        "<<<<<<<<<<< End Point >>>>>>>>> ${EndPoints.baseUrl}${EndPoints.epFindAllByVendorIdAndOrderDate}",
      );
      final selectedDate = request is DateTime ? request : DateTime.now();

      final today = DateFormat('yyyy-MM-dd').format(selectedDate);
      logger.i("<<<<<<<<<<< Today >>>>>>>>> $today");

      final response = await DioHelper.getData(
        url: "${EndPoints.baseUrl}${EndPoints.epFindAllByVendorIdAndOrderDate}",
        query: {
          // "id": "1196d012-899f-49ae-b26c-ee5682cf434f",
          // "day": "2026-06-16",
          "id": "${user.id}",
          "day": "$today",
        },
      );
      logger.i("<<<<<<<<<<< Response >>>>>>>>> ${response.data}");
      if (response.statusCode == 200) {
        final ordersResponse = OrdersResponse.fromJson(response.data);
        logger.i(response.data);
        if (ordersResponse.orders.isNotEmpty) {
          await CacheHelper.saveDataSharedPreference(
            key: CacheKeys.vendorId,
            value: ordersResponse.orders.first.vendorId ?? '',
          );

          logger.i(
            "Vendor ID Saved => ${ordersResponse.orders.first.vendorId}",
          );
        }

        return Right(ordersResponse);
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
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
  List<Object?> get props => [orders];
}
