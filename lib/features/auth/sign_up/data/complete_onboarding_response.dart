import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../base/base_repository.dart';
import '../../../../core/error/failures.dart';

/*
|--------------------------------------------------------------------------
| CompleteOnboardingResponse  (LEGACY — no longer used)
|--------------------------------------------------------------------------
|
| The separate onboarding profile-update call has been replaced by the
| unified single POST /api/auth/signup in SignupResponse. This class is
| kept as a registered stub so the BaseRepository factory doesn't throw,
| but its getData() is a no-op that always returns success.
|--------------------------------------------------------------------------
*/

class CompleteOnboardingResponse extends Equatable implements BaseRepository {
  const CompleteOnboardingResponse();

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    // No-op: the real signup call is now handled by SignupResponse.
    return const Right(CompleteOnboardingResponse());
  }

  @override
  List<Object?> get props => [];
}
