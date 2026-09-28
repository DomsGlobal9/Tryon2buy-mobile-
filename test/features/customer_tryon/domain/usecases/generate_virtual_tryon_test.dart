import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/selfie_record.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/tryon_result.dart';
import 'package:tryon2buy/features/customer_tryon/domain/repositories/i_tryon_repository.dart';
import 'package:tryon2buy/features/customer_tryon/domain/usecases/generate_virtual_tryon.dart';
import 'dart:io';

class FakeTryonRepository implements ITryonRepository {
  TryonResult? resultToReturn;
  Failure? failureToReturn;

  @override
  Future<Result<String>> uploadSelfie(File imageFile) async {
    return const Success('https://fake-hosted-url.com/selfie.jpg');
  }

  @override
  Future<Result<TryonResult>> executeTryon({
    required String garmentUrl,
    required String humanImageUrl,
    String mode = 'with_garment',
    String? parentGenerationId,
    String? category,
    String? targetFolder,
    String? dupattaStyleUrl,
    String? dockPhotoId,
  }) async {
    if (failureToReturn != null) {
      return Fail(failureToReturn!);
    }
    return Success(resultToReturn ??
        TryonResult(
          generationId: 'gen-123',
          resultImageUrl: 'https://fake-result.com/out.jpg',
          garmentImageUrl: garmentUrl,
          humanImageUrl: humanImageUrl,
          mode: mode,
          phase: 1,
          status: 'COMPLETED',
        ));
  }

  @override
  Future<Result<String>> changeBackground({
    required String currentImageUrl,
    required String backgroundId,
    String? generationId,
  }) async =>
      const Success('https://fake-bg-swapped.jpg');

  @override
  Future<Result<String>> modifyOutfitStyle({
    required String currentImageUrl,
    required String modificationType,
    String? generationId,
  }) async =>
      const Success('https://fake-outfit-mod.jpg');

  @override
  Future<Result<TryonResult>> fetchGeneration(String id) async =>
      throw UnimplementedError();
}

void main() {
  group('SelfieRecord Domain Entity', () {
    test('isExpired is false when created recently', () {
      final record = SelfieRecord(
        id: '1',
        imageUrl: 'https://example.com/photo.jpg',
        lastUsedAt: DateTime.now(),
      );

      expect(record.isExpired, isFalse);
      expect(record.remainingSeconds, greaterThan(0));
    });

    test('isExpired is true when last used > 20 minutes ago', () {
      final record = SelfieRecord(
        id: '2',
        imageUrl: 'https://example.com/old.jpg',
        lastUsedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      );

      expect(record.isExpired, isTrue);
      expect(record.remainingSeconds, equals(0));
    });
  });

  group('GenerateVirtualTryonUseCase', () {
    late FakeTryonRepository fakeRepo;
    late GenerateVirtualTryonUseCase useCase;

    setUp(() {
      fakeRepo = FakeTryonRepository();
      useCase = GenerateVirtualTryonUseCase(fakeRepo);
    });

    test('returns failure when garmentUrl is empty', () async {
      final result = await useCase(
        garmentUrl: '',
        humanImageUrl: 'https://example.com/human.jpg',
      );

      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('returns failure when humanImageUrl is invalid blob URL and no file', () async {
      final result = await useCase(
        garmentUrl: 'https://example.com/garment.jpg',
        humanImageUrl: 'blob:http://localhost/1234',
      );

      expect(result.isFailure, isTrue);
    });

    test('executes tryon and returns success result', () async {
      final result = await useCase(
        garmentUrl: 'https://example.com/garment.jpg',
        humanImageUrl: 'https://example.com/human.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.generationId, equals('gen-123'));
      expect(result.dataOrNull?.resultImageUrl, equals('https://fake-result.com/out.jpg'));
    });
  });
}
