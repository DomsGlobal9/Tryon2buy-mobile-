/// Exceptions thrown ONLY inside `data/datasources/`.
/// The repository layer catches these and maps them to Failure types.
/// UI code never sees these.
library;

/// Thrown when the device has no network connectivity.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection.']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when the backend responds with a non-2xx HTTP status.
class ServerException implements Exception {
  final int statusCode;
  final String message;
  final String? rawBody;

  const ServerException({
    required this.statusCode,
    required this.message,
    this.rawBody,
  });

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when an HTTP request exceeds the configured timeout.
class RequestTimeoutException implements Exception {
  final String message;
  const RequestTimeoutException([this.message = 'Request timed out.']);

  @override
  String toString() => 'RequestTimeoutException: $message';
}

/// Thrown when image data is malformed, too large, or missing.
class ImageException implements Exception {
  final String message;
  const ImageException(this.message);

  @override
  String toString() => 'ImageException: $message';
}
