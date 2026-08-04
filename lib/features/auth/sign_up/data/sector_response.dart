import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../base/base_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_helper.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/utils/logger.dart';
import 'sector_model.dart';

/*
|--------------------------------------------------------------------------
| SectorResponse
|--------------------------------------------------------------------------
|
| Fetches the paginated list of sectors from:
|   GET /api/auth/sector?isView=true&page=0&size=20
|
| The response wraps the list inside a `content` array. On success,
| getData() returns List<SectorModel> boxed in the Either Right. The
| caller (OnboardingCubit) casts the result back to List<SectorModel>.
|
|--------------------------------------------------------------------------
*/

class SectorResponse extends Equatable implements BaseRepository {
  const SectorResponse();

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    try {
      final response = await DioHelper.getData(
        url: '${EndPoints.baseUrl}${EndPoints.epSector}',
        query: {
          'isView': 'true',
          'page': '0',
          'size': '20',
        },
      );

      logger.i('<<<<<<<<<< Sectors >>>>>>>>>>>> ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> content =
            (response.data as Map<String, dynamic>)['content'] as List<dynamic>;
        final sectors = content
            .map((e) => SectorModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(_SectorListHolder(sectors));
      } else {
        return Left(ServerFailure('Error loading sectors: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  List<Object?> get props => [];
}

/// Internal wrapper so we can return List<SectorModel> through the
/// Either<Failure, BaseRepository> channel.
class _SectorListHolder extends Equatable implements BaseRepository {
  final List<SectorModel> sectors;
  const _SectorListHolder(this.sectors);

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async =>
      Right(this);

  @override
  List<Object?> get props => [sectors];
}

/// Public helper so callers can unbox the list without casting magic.
extension SectorResponseX on BaseRepository {
  List<SectorModel> asSectors() => (this as _SectorListHolder).sectors;
}
