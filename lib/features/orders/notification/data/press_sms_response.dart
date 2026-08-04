import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';

part 'press_sms_response.g.dart';

@JsonSerializable()
class PressSmsResponse extends Equatable implements BaseRepository {
  const PressSmsResponse();

  factory PressSmsResponse.fromJson(Map<String, dynamic> json) =>
      _$PressSmsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PressSmsResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final response = await DioHelper.getData(
        url: "${EndPoints.baseUrl}${EndPoints.epSmsIsPressed}",
        query: {"id": request},
      );

      if (response.statusCode == 200) {
        return const Right(PressSmsResponse());
      }

      return Left(ServerFailure("Error"));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  List<Object?> get props => [];
}
