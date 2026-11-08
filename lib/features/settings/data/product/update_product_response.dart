import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/data/product/update_product_request.dart';

class UpdateProductResponse extends Equatable implements BaseRepository {
  final ProductModel? product;

  const UpdateProductResponse({this.product});

  @override
  List<Object?> get props => [product?.id];

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    if (request is! UpdateProductRequest) {
      return const Left(ServerFailure('invalid_request'));
    }

    try {
      final response = await DioHelper.putData(
        url: '${EndPoints.baseUrl}${EndPoints.epAddProduct}/${request.id}',
        formDataOverride: await request.product.toFormData(),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        final data = response.data;
        return Right(
          UpdateProductResponse(
            product: data is Map && data.containsKey('id')
                ? ProductModel.fromJson(Map<String, dynamic>.from(data))
                : null,
          ),
        );
      }

      return const Left(ServerFailure('request_failed'));
    } on DioException catch (e) {
      logger.e('Update product API error: ${e.response?.data ?? e.message}');

      final data = e.response?.data;
      var message = 'product_update_failed';
      if (data is Map) {
        message =
            (data['detail'] ?? data['message'] ?? data['title'] ?? message)
                .toString();
      }
      return Left(ServerFailure(message));
    } catch (e, stackTrace) {
      logger.e('Update product error: $e\n$stackTrace');
      return const Left(ServerFailure('something_went_wrong'));
    }
  }
}
