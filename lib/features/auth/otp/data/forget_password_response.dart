import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';

class ForgetPasswordResponse extends Equatable implements BaseRepository {
  const ForgetPasswordResponse();

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final response = await DioHelper.postData(
        url: "${EndPoints.baseUrl}${EndPoints.epForgetPassword}",
        body: request,
      );

      logger.i("Forget Password => ${response.statusCode}");
      logger.i("Body => ${response.data}");

      if (response.statusCode == 200) {
        return const Right(ForgetPasswordResponse());
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } catch (e) {
      logger.e(e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  List<Object?> get props => [];
}
// @JsonSerializable()
// class ForgetPasswordResponse extends Equatable implements BaseRepository {
//   final String? message;

//   const ForgetPasswordResponse({this.message});

//   factory ForgetPasswordResponse.fromJson(Map<String, dynamic> json) =>
//       _$ForgetPasswordResponseFromJson(json);

//   Map<String, dynamic> toJson() => _$ForgetPasswordResponseToJson(this);

//   @override
//   Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
//     try {
//       logger.d("<<<<<<< Forget Password Request >>>>>>>>>> $request");
//       final response = await DioHelper.postData(
//         url: "${EndPoints.baseUrl}${EndPoints.epForgetPassword}",
//         body: request,
//         // "userId": request["userId"],
//         // "newPassword": request["newPassword"],
//         //},
//       );

//       logger.i("<<<<<< Send OTP >>>>>> ${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return Right(ForgetPasswordResponse.fromJson(response.data));
//       }

//       return Left(ServerFailure("Error ${response.statusCode}"));
//     } catch (e) {
//       logger.e(e);
//       return Left(ServerFailure(e.toString()));
//     }
//   }

//   @override
//   List<Object?> get props => [message];
// }
