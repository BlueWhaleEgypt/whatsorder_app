import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';

/// DELETE /api/auth/vendor-services/{id}. The request is the product id.
class DeleteProductResponse extends Equatable implements BaseRepository {
  const DeleteProductResponse();

  @override
  List<Object?> get props => [];

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    if (request is! String || request.isEmpty) {
      return const Left(ServerFailure('invalid_request'));
    }

    try {
      final response = await DioHelper.deleteData(
        url: '${EndPoints.baseUrl}${EndPoints.epAddProduct}/$request',
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return const Right(DeleteProductResponse());
      }

      return const Left(ServerFailure('request_failed'));
    } on DioException catch (e) {
      logger.e('Delete product API error: ${e.response?.data ?? e.message}');

      final data = e.response?.data;
      var message = 'product_delete_failed';
      if (data is Map) {
        message =
            (data['detail'] ?? data['message'] ?? data['title'] ?? message)
                .toString();
      }
      return Left(ServerFailure(message));
    } catch (e, stackTrace) {
      logger.e('Delete product error: $e\n$stackTrace');
      return const Left(ServerFailure('something_went_wrong'));
    }
  }
}
