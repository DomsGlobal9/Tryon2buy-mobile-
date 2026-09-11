import '../errors/failures.dart';

/// A functional Result type modeled after Rust's `Result<T, E>`.
///
/// Forces callers to handle both success and failure paths explicitly
/// via [fold], [when], or Dart 3 pattern matching:
///
/// ```dart
/// final result = await generateTryon(...);
/// switch (result) {
///   case Success(:final data): print(data);
///   case Fail(:final failure):  showError(failure.message);
/// }
/// ```
sealed class Result<S> {
  const Result();

  bool get isSuccess => this is Success<S>;
  bool get isFailure => this is Fail<S>;

  /// Fold the result into a single value.
  R fold<R>({
    required R Function(Failure failure) onFailure,
    required R Function(S data) onSuccess,
  }) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Fail(:final failure) => onFailure(failure),
    };
  }

  /// Convenience: get data or null.
  S? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Fail() => null,
  };
}

/// Represents a successful operation with [data].
final class Success<S> extends Result<S> {
  final S data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed operation with a typed [Failure].
final class Fail<S> extends Result<S> {
  final Failure failure;
  const Fail(this.failure);

  @override
  String toString() => 'Fail(${failure.message})';
}
