import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';

part 'wallet_response.g.dart';

@JsonSerializable()
class WalletResponse extends Equatable implements BaseRepository {
  final String? id;
  final UserModel? user;
  final num? balance;

  const WalletResponse({this.id, this.user, this.balance});

  factory WalletResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final user = UserModel.fromJson(
        jsonDecode(
          CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
              '{}',
        ),
      );
      final response = await DioHelper.getData(
        url: "${EndPoints.baseUrl}${EndPoints.epWalletByVendor}/${user.id}",
      );

      logger.i("Wallet => ${response.data}");

      if (response.statusCode == 200) {
        logger.i("Wallet => ${response.data}");

        return Right(WalletResponse.fromJson(response.data));
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } on DioException catch (e) {
      logger.e(e.response?.data);

      String message = "Something went wrong";

      if (e.response?.data is Map<String, dynamic>) {
        message = e.response!.data["message"] ?? message;
      }

      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [id, user, balance];
}
