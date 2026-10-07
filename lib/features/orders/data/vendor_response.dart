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
import 'vendor_model.dart';

part 'vendor_response.g.dart';

@JsonSerializable()
class VendorResponse extends Equatable implements BaseRepository {
  final VendorModel? vendor;

  const VendorResponse({this.vendor});

  factory VendorResponse.fromJson(Map<String, dynamic> json) {
    return VendorResponse(vendor: VendorModel.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    return vendor?.toJson() ?? {};
  }

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final user = UserModel.fromJson(
        jsonDecode(
          CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
              '{}',
        ),
      );

      final vendorId = user.id;

      if (vendorId == null || vendorId.isEmpty) {
        return Left(ServerFailure('Vendor ID not found'));
      }

      final response = await DioHelper.getData(
        url: "${EndPoints.baseUrl}${EndPoints.epGetVendorById}/$vendorId",
      );
        logger.w("RAW VENDOR RESPONSE => ${response.data}");

      if (response.statusCode == 200) {
        final vendorResponse = VendorResponse.fromJson(response.data);
        logger.w("RAW VENDOR RESPONSE => ${response.data}");

        final vendor = VendorResponse.fromJson(response.data);

        logger.w("PARSED VENDOR ACTIVATION => ${vendor.vendor?.activation}");

        logger.w(
          "PARSED VENDOR VERIFICATION => ${vendor.vendor?.verificationStatus}",
        );

        return Right(vendorResponse);
      }

      return Left(ServerFailure(response.statusMessage ?? "Unknown Error"));
    } on DioException catch (e) {
      logger.e("Status Code: ${e.response?.statusCode}");
      logger.e("Response: ${e.response?.data}");

      String message = 'Something went wrong';

      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;

        message = data['detail'] ?? data['message'] ?? data['title'] ?? message;
      }

      return Left(ServerFailure(message));
    }
  }

  @override
  List<Object?> get props => [vendor];
}
