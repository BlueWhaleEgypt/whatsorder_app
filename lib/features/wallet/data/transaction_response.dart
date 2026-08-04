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
import 'package:whats_order/features/wallet/data/transaction_model.dart';
import 'package:whats_order/features/wallet/data/transaction_requiest.dart';

part 'transaction_response.g.dart';

@JsonSerializable()
class TransactionResponse extends Equatable implements BaseRepository {
  final List<TransactionModel> content;

  const TransactionResponse({this.content = const []});

  factory TransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final req = request as TransactionRequest;

      final userId = CacheHelper.getDataFromSharedPreference(
        key: CacheKeys.userId,
      );

      final response = await DioHelper.getData(
        url: "${EndPoints.baseUrl}${EndPoints.epWalletTransactions}/$userId",
        query: {"page": req.page, "size": req.size},
      );

      logger.i(response.data);

      if (response.statusCode == 200) {
        return Right(TransactionResponse.fromJson(response.data));
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response?.data is Map<String, dynamic>) {
        message = e.response!.data["message"] ?? message;
      }

      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [content];
}
