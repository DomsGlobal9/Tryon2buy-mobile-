import 'dart:io';

import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';
import '../entities/tryon_result.dart';
import '../repositories/i_tryon_repository.dart';

/// Orchestrates the full try-on generation flow:
/// 1. Validates inputs
/// 2. Optionally uploads a selfie File → URL
/// 3. Calls the AI pipeline
///
/// Single Responsibility: one public method, one job.
class GenerateVirtualTryonUseCase {
  final ITryonRepository _repository;

  const GenerateVirtualTryonUseCase(this._repository);

  Future<Result<TryonResult>> call({
    required String garmentUrl,
    required String humanImageUrl,
    File? selfieFile,
    String? parentGenerationId,
    String? category,
    String? targetFolder,
  }) async {
    // ── Input validation (pure business rules) ─────────────────────
    if (garmentUrl.trim().isEmpty) {
      return const Fail(ImageProcessingFailure('No garment image selected.'));
    }

    // If a local file is provided, upload it first to get a hosted URL.
    String resolvedHumanUrl = humanImageUrl;
    if (selfieFile != null) {
      final uploadResult = await _repository.uploadSelfie(selfieFile);
      switch (uploadResult) {
        case Success(:final data):
          resolvedHumanUrl = data;
        case Fail(:final failure):
          return Fail(failure);
      }
    }

    if (resolvedHumanUrl.trim().isEmpty || resolvedHumanUrl.startsWith('blob:')) {
      return const Fail(
        ImageProcessingFailure('Invalid photo. Please upload a fresh image.'),
      );
    }

    // ── Delegate to repository ─────────────────────────────────────
    final result = await _repository.executeTryon(
      garmentUrl: garmentUrl,
      humanImageUrl: resolvedHumanUrl,
      parentGenerationId: parentGenerationId,
      category: category,
      targetFolder: targetFolder,
    );

    // The server echoes the human URL it received; make sure the entity the
    // UI keeps carries the *hosted* selfie even if the echo is missing.
    return switch (result) {
      Success(:final data) => Success(
          data.humanImageUrl.isEmpty
              ? data.copyWith(humanImageUrl: resolvedHumanUrl)
              : data,
        ),
      Fail(:final failure) => Fail(failure),
    };
  }
}
