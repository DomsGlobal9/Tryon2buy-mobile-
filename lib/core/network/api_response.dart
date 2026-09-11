class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  /// Machine-readable code the backend puts in `error` for business
  /// failures, e.g. `GUEST_LIMIT_REACHED` or `INSUFFICIENT_CREDITS`. Null
  /// for ordinary errors, whose text is in [error].
  final String? errorCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.errorCode,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure(
    String error, {
    int? statusCode,
    String? errorCode,
  }) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  /// The website's two credit gates, checked by every generation caller.
  bool get isGuestLimitReached => errorCode == 'GUEST_LIMIT_REACHED';
  bool get isInsufficientCredits => errorCode == 'INSUFFICIENT_CREDITS';
}
