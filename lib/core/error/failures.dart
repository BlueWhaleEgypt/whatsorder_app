import 'package:equatable/equatable.dart';

/*
|--------------------------------------------------------------------------
| Failure
|--------------------------------------------------------------------------
|
| Base class for every failure returned from the data layer. Every
| repository's getData() returns Either<Failure, BaseRepository>, so
| this hierarchy is what the Bloc layer maps to user-facing messages.
|
|--------------------------------------------------------------------------
*/

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class OfflineFailure extends Failure {
  const OfflineFailure(String message) : super(message);
}

class EmptyCacheFailure extends Failure {
  const EmptyCacheFailure(String message) : super(message);
}
