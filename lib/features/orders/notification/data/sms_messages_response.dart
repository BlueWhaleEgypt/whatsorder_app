import 'dart:convert';

import 'package:dartz/dartz.dart';
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

import 'sms_message_model.dart';

part 'sms_messages_response.g.dart';

@JsonSerializable()
class SmsMessagesResponse extends Equatable implements BaseRepository {
  final List<SmsMessageModel> smsMessages;

  const SmsMessagesResponse({this.smsMessages = const []});

  factory SmsMessagesResponse.fromJson(Map<String, dynamic> json) =>
      _$SmsMessagesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SmsMessagesResponseToJson(this);

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
      final selectedDate = request is DateTime ? request : DateTime.now();

      final today = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await DioHelper.getData(
        url: "${EndPoints.baseUrl}${EndPoints.epSmsMessages}",
        query: {"vendorId": user.id, "day": today},
      );

      logger.i(response.data);

      if (response.statusCode == 200) {
        return Right(SmsMessagesResponse.fromJson(response.data));
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } catch (e) {
      logger.e(e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  List<Object?> get props => [smsMessages];
}
