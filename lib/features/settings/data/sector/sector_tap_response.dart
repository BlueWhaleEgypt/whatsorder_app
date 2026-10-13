

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/auth/sign_up/data/sector_model.dart';

import 'sector_request.dart';

class SectorTapResponse implements BaseRepository {
  const SectorTapResponse();

  @override
  Future<Either<Failure, BaseRepository>> getData(
    dynamic request,
  ) async {
    if (request is! SectorRequest) {
      logger.e(
        '[SECTORS] Invalid request type: ${request.runtimeType}',
      );
      return const Left(ServerFailure('Invalid sector request'));
    }

    try {
      switch (request.action) {


        case 'add':
          const url =
              '${EndPoints.baseUrl}/api/auth/sector/addSectorToUser';

          final query = {
            'userId': request.userId,
            'sectorId': request.sectorId,
          };

          logger.i('[SECTORS][ADD] REQUEST');
          logger.i('URL: $url');
          logger.i('QUERY: $query');

          final response = await DioHelper.postData(
            url: url,
            query: query,
          );

          logger.i('[SECTORS][ADD] RESPONSE');
          logger.i('STATUS: ${response.statusCode}');
          logger.i('BODY: ${response.data}');

          if (response.statusCode == 200 ||
              response.statusCode == 201) {
            return Right(
              SectorMutationResult(
                'sector_added_successfully',
                response.data,
              ),
            );
          }

          return const Left(
            ServerFailure('Failed to add sector'),
          );

        case 'delete':
          const url =
              '${EndPoints.baseUrl}/api/auth/sector/removeSectorForUser';

          final query = {
            'userId': request.userId,
            'sectorId': request.sectorId,
          };

          logger.i('[SECTORS][DELETE] REQUEST');
          logger.i('URL: $url');
          logger.i('QUERY: $query');

          final response = await DioHelper.deleteData(
            url: url,
            query: query,
          );

          logger.i('[SECTORS][DELETE] RESPONSE');
          logger.i('STATUS: ${response.statusCode}');
          logger.i('BODY: ${response.data}');

          if (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204) {
            return Right(
              SectorMutationResult(
                'sector_removed_successfully',
                response.data,
              ),
            );
          }

          return const Left(
            ServerFailure('Failed to remove sector'),
          );

        default:
          logger.e(
            '[SECTORS] Unknown action: ${request.action}',
          );
          return const Left(
            ServerFailure('Unknown sector action'),
          );
      }
    } on DioException catch (e, stackTrace) {
      logger.e(
        '[SECTORS][DIO ERROR]\n'
        'Action: ${request.action}\n'
        'URL: ${e.requestOptions.uri}\n'
        'Method: ${e.requestOptions.method}\n'
        'Status: ${e.response?.statusCode}\n'
        'Response: ${e.response?.data}\n'
        'Message: ${e.message}\n'
        'StackTrace: $stackTrace',
      );

      return Left(
        ServerFailure(
          e.response?.data?.toString() ??
              e.message ??
              'Sector request failed',
        ),
      );
    } catch (e, stackTrace) {
      logger.e(
        '[SECTORS][UNEXPECTED ERROR]\n'
        'Action: ${request.action}\n'
        'Error: $e\n'
        'StackTrace: $stackTrace',
      );

      return Left(ServerFailure(e.toString()));
    }
  }
}

class SectorListHolder implements BaseRepository {
  final List<SectorModel> sectors;

  const SectorListHolder(this.sectors);

  @override
  Future<Either<Failure, BaseRepository>> getData(
    dynamic request,
  ) async {
    return Right(this);
  }
}

class SectorMutationResult implements BaseRepository {
  final String message;
  final dynamic responseData;

  const SectorMutationResult(
    this.message, [
    this.responseData,
  ]);

  @override
  Future<Either<Failure, BaseRepository>> getData(
    dynamic request,
  ) async {
    return Right(this);
  }
}
