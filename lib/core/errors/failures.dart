import 'package:equatable/equatable.dart';

/// Base failure type. All domain-level errors are expressed as [Failure] subtypes.
/// UI code pattern-matches on these — never on raw exceptions.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// No internet or DNS resolution failed.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

/// Backend returned an HTTP error (5xx, 4xx, etc.).
final class ServerFailure extends Failure {
  final int statusCode;
  const ServerFailure({required this.statusCode, required String message}) : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

/// Token expired, invalid, or missing.
final class AuthTokenExpiredFailure extends Failure {
  const AuthTokenExpiredFailure([super.message = 'Session expired. Please log in again.']);
}

/// Guest try-on limit reached — must register.
final class GuestLimitReachedFailure extends Failure {
  const GuestLimitReachedFailure([super.message = 'Guest limit reached. Please create an account.']);
}

/// Monthly AI credit quota exhausted.
final class InsufficientCreditsFailure extends Failure {
  const InsufficientCreditsFailure([super.message = 'Monthly try-on credits exhausted. Upgrade your plan.']);
}

/// Image upload, validation, or processing failed.
final class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure(super.message);
}

/// Request timed out.
final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out. Please try again.']);
}

/// Catch-all for truly unexpected errors.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
