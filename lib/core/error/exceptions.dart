/// Exceptions are the vocabulary of the DATA layer only.
///
/// They are thrown at the point of I/O (HTTP call, JSON decode, DB call) and
/// are always caught inside a RepositoryImpl, which maps them to a [Failure].
/// Nothing above the repository should ever see one of these.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
}
