import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/errors/exceptions.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryon2buy/features/customer_tryon/data/models/tryon_generation_dto.dart';
import 'package:tryon2buy/features/customer_tryon/data/repositories/tryon_repository_impl.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/tryon_result.dart';

class _ThrowingRemote extends TryonRemoteDataSource {
  final Exception toThrow;
  _ThrowingRemote(this.toThrow);

  @override
  Future<TryonGenerationDto> generateTryon({
    required String garmentUrl,
    required String humanImageUrl,
    String mode = 'with_garment',
    String? parentGenerationId,
    String? category,
    String? garmentId,
    String? catalogProductId,
    String? frontViewUrl,
    String? targetFolder,
    String? dupattaStyleUrl,
    String? dockPhotoId,
  }) async {
    throw toThrow;
  }
}

Future<Failure> _failureFor(Exception e) async {
  final repo = TryonRepositoryImpl(_ThrowingRemote(e));
  final result = await repo.executeTryon(garmentUrl: 'g', humanImageUrl: 'h');
  expect(result, isA<Fail<TryonResult>>());
  return (result as Fail<TryonResult>).failure;
}

void main() {
  test('a guest-limit 401 maps to GuestLimitReachedFailure', () async {
    final failure = await _failureFor(const ServerException(
      statusCode: 401,
      message: 'Login as Vendor for more credits.',
      rawBody: '{"error":"GUEST_LIMIT_REACHED","message":"Login as Vendor for more credits."}',
    ));
    expect(failure, isA<GuestLimitReachedFailure>());
  });

  test('a plain 401 maps to AuthTokenExpiredFailure', () async {
    final failure = await _failureFor(const ServerException(
      statusCode: 401,
      message: 'Invalid or expired token.',
      rawBody: '{"error":"Invalid or expired token."}',
    ));
    expect(failure, isA<AuthTokenExpiredFailure>());
  });

  test('INSUFFICIENT_CREDITS maps to InsufficientCreditsFailure', () async {
    final failure = await _failureFor(const ServerException(
      statusCode: 403,
      message: 'You have used your 10 free drapes.',
      rawBody: '{"error":"INSUFFICIENT_CREDITS","message":"You have used your 10 free drapes."}',
    ));
    expect(failure, isA<InsufficientCreditsFailure>());
  });

  test('transport errors map to their failures', () async {
    expect(await _failureFor(const NetworkException()), isA<NetworkFailure>());
    expect(await _failureFor(const RequestTimeoutException()), isA<TimeoutFailure>());
    expect(await _failureFor(const ImageException('bad')), isA<ImageProcessingFailure>());
  });
}
