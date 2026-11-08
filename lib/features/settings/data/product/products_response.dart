import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/data/product/products_request.dart';

class ProductsResponse extends Equatable implements BaseRepository {
  final List<ProductModel> products;

  const ProductsResponse({this.products = const []});

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    return ProductsResponse(
      products: services is List
          ? services
                .whereType<Map>()
                .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [products.map((p) => p.id).toList()];

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    if (request is! ProductsRequest) {
      return const Left(ServerFailure('invalid_request'));
    }

    try {
      final response = await DioHelper.postData(
        url: '${EndPoints.baseUrl}${EndPoints.epVendorProducts}',
        query: {'vendorId': request.vendorId},
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300 && response.data is Map) {
        return Right(
          ProductsResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      }

      return const Left(ServerFailure('request_failed'));
    } on DioException catch (e) {
      logger.e('Products API error: ${e.response?.data ?? e.message}');

      final data = e.response?.data;
      var message = 'something_went_wrong';
      if (data is Map) {
        message =
            (data['detail'] ?? data['message'] ?? data['title'] ?? message)
                .toString();
      }
      return Left(ServerFailure(message));
    } catch (e, stackTrace) {
      logger.e('Products error: $e\n$stackTrace');
      return const Left(ServerFailure('something_went_wrong'));
    }
  }
}
