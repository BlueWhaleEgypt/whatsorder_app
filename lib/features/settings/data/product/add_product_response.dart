import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/product/add_product_request.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';

class AddProductResponse extends Equatable implements BaseRepository {
  final ProductModel? product;

  const AddProductResponse({this.product});

  factory AddProductResponse.fromJson(Map<String, dynamic> json) {
    return AddProductResponse(product: ProductModel.fromJson(json));
  }

  @override
  List<Object?> get props => [product?.id];

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    if (request is! AddProductRequest) {
      return const Left(ServerFailure('invalid_request'));
    }

    try {
      final formData = FormData.fromMap({
        'name': request.name,
        'price': request.price,
        'delivaryTime': request.deliveryTime,
        'sectorId': request.sectorId,
        'vendorId': request.vendorId,
        'note': request.note,
        'photos': [
          for (final path in request.photoPaths)
            await MultipartFile.fromFile(path),
        ],
      });

      final response = await DioHelper.postData(
        url: '${EndPoints.baseUrl}${EndPoints.epAddProduct}',
        formDataOverride: formData,
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        final data = response.data;
        return Right(
          data is Map
              ? AddProductResponse.fromJson(Map<String, dynamic>.from(data))
              : const AddProductResponse(),
        );
      }

      return const Left(ServerFailure('request_failed'));
    } on DioException catch (e) {
      logger.e('Add product API error: ${e.response?.data ?? e.message}');

      final data = e.response?.data;
      var message = 'product_add_failed';
      if (data is Map) {
        message =
            (data['detail'] ?? data['message'] ?? data['title'] ?? message)
                .toString();
      }
      return Left(ServerFailure(message));
    } catch (e, stackTrace) {
      logger.e('Add product error: $e\n$stackTrace');
      return const Left(ServerFailure('something_went_wrong'));
    }
  }
}
