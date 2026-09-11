import 'package:equatable/equatable.dart';

/// Base type for anything that can go wrong above the data layer.
///
/// Everything from `domain` and `presentation` outward speaks in [Failure],
/// never in raw exceptions. This keeps error handling exhaustive and
/// type-safe (the UI can switch on the concrete Failure type instead of
/// parsing strings).
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// The remote server responded, but with an error (4xx/5xx, malformed body).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server']);
}

/// The request never reached the server (no connectivity, timeout, DNS).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Reading or writing local device storage failed (e.g. shared_preferences).
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read or save local data']);
}
