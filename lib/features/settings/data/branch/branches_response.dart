import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:whats_order/features/settings/data/branch/branch_action.dart';
import 'package:whats_order/features/settings/data/branch/branch_request.dart';

import '../../../../base/base_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_helper.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/utils/logger.dart';
import 'branch_model.dart';

class BranchesResponse implements BaseRepository {
  final List<BranchModel> branches;
  final BranchModel? branch;

  const BranchesResponse({this.branches = const [], this.branch});

  factory BranchesResponse.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];

    if (categories is List) {
      return BranchesResponse(
        branches: categories
            .whereType<Map<String, dynamic>>()
            .map(BranchModel.fromJson)
            .toList(),
      );
    }

    // Add/update responses return a single branch object.
    if (json.containsKey('id')) {
      return BranchesResponse(branch: BranchModel.fromJson(json));
    }

    return const BranchesResponse();
  }

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    if (request is! BranchRequest) {
      return const Left(ServerFailure('invalid_request'));
    }

    try {
      late final Response<dynamic> response;

      switch (request.action) {
        case BranchAction.fetch:
          response = await DioHelper.getData(
            url: '${EndPoints.baseUrl}${EndPoints.epAllBranches}',
            query: {'userId': request.userId},
          );
          break;

        case BranchAction.add:
          final branch = request.branch!;

          response = await DioHelper.postData(
            url: '${EndPoints.baseUrl}${EndPoints.epAddBranch}',
            formDataOverride: _toFormData(branch, request.userId),
          );
          break;

        case BranchAction.update:
          final branch = request.branch!;

          response = await DioHelper.postData(
            url:
                '${EndPoints.baseUrl}${EndPoints.epUpdateBranch}/${request.branchId}',
            formDataOverride: _toFormData(branch, request.userId),
          );
          break;

        case BranchAction.delete:
          response = await DioHelper.deleteData(
            url:
                '${EndPoints.baseUrl}${EndPoints.epDeleteBranch}/${request.branchId}',
            query: {'userId': request.userId},
          );
          break;
      }

      final statusCode = response.statusCode ?? 0;

      if (statusCode >= 200 && statusCode < 300) {
        if (request.action == BranchAction.delete) {
          return const Right(BranchesResponse());
        }

        return Right(
          BranchesResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      }

      return const Left(ServerFailure('request_failed'));
    } on DioException catch (e) {
      logger.e('Branch API error: ${e.response?.data ?? e.message}');

      final data = e.response?.data;
      var message = 'something_went_wrong';

      if (data is Map) {
        message =
            (data['detail'] ?? data['message'] ?? data['title'] ?? message)
                .toString();
      }

      return Left(ServerFailure(message));
    } catch (e, stackTrace) {
      logger.e('Branch error: $e\n$stackTrace');
      return const Left(ServerFailure('something_went_wrong'));
    }
  }

  FormData _toFormData(BranchModel branch, String userId) {
    return FormData.fromMap({
      'name': branch.name,
      'nameEn': branch.nameEn,
      'latitude': branch.latitude,
      'longitude': branch.longitude,
      'address': branch.address,
      'userId': userId,
    });
  }
}
