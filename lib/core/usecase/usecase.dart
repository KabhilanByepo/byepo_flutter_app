import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Every use case implements this: one business operation, one entry point
/// (`call`), returning either a [Failure] or the successful [Type].
///
/// [Type] = the success return type.
/// [Params] = the input the use case needs. Use [NoParams] when there's none.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Marker type for use cases that take no arguments (e.g. GetCurrentUser()).
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
