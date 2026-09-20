import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';

import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/orders/notification/data/notification_model.dart';

part 'notification_response.g.dart';

@JsonSerializable()
class NotificationResponse extends Equatable implements BaseRepository {
  final List<NotificationModel> notifications;

  const NotificationResponse({this.notifications = const []});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      // final body = request as NotificationRequest;
      final user = UserModel.fromJson(
        jsonDecode(
          CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
              '{}',
        ),
      );
      logger.i("<<<<<<<<<<< User ID >>>>>>>>> ${user.id}");
      final selectedDate = request is DateTime ? request : DateTime.now();

      final today = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await DioHelper.getData(
        url: "${EndPoints.baseUrl}${EndPoints.epNotification}",
        query: {"vendorId": "${user.id}", "day": "$today"},
      );

      if (response.statusCode == 200) {
        logger.i("<<<<<<<<<<<<<<<<<<< ${response.data}");
        logger.i("today ${response.statusCode}");

        return Right(NotificationResponse.fromJson(response.data));
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } on DioException catch (e) {
      String message = "Something went wrong";

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
  List<Object?> get props => [notifications];
}
