import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';

part 'change_phone_response.g.dart';

@JsonSerializable()
class ChangePhoneResponse extends Equatable implements BaseRepository {
  final String? user;

  const ChangePhoneResponse({this.user});

  factory ChangePhoneResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangePhoneResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePhoneResponseToJson(this);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final Map<String, dynamic> query = {
        'userId': request['userId'],
        'phone': request['phone'],
      };

      logger.i('<<<<<< Change Phone $query');

      final response = await DioHelper.postData(
        url: '${EndPoints.baseUrl}${EndPoints.epChangePhoneNumber}',
        query: query,
      );

      logger.i('<<<<<< Change Phone >>>>>> ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(
          ChangePhoneResponse.fromJson(
            Map<String, dynamic>.from(response.data),
          ),
        );
      }

      return const Left(ServerFailure('request_failed'));
    } catch (e) {
      logger.e(e);
      return const Left(ServerFailure('something_went_wrong'));
    }
  }

  @override
  List<Object?> get props => [user];
}
