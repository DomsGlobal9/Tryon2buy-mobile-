class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'Please check your internet connection.'});
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = 'Unauthorized. Please login again.'})
      : super(statusCode: 401);
}

class ServerException extends ApiException {
  ServerException({super.message = 'Internal Server Error. Please try again later.'})
      : super(statusCode: 500);
}
