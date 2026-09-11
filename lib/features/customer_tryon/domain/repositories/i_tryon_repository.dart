import 'dart:io';

import 'package:tryon2buy/core/utils/result.dart';
import '../entities/tryon_result.dart';

/// Abstract contract for all try-on data operations.
///
/// The domain layer and use cases depend ONLY on this interface.
/// The concrete implementation lives in `data/repositories/`.
/// This allows unit testing with mock implementations.
abstract interface class ITryonRepository {
  /// Upload a selfie [File] to the server and return the hosted URL.
  Future<Result<String>> uploadSelfie(File imageFile);

  /// Execute the AI virtual try-on pipeline.
  ///
  /// [parentGenerationId] links a shopper's try-on to the merchant drape it
  /// was started from (the website's `/tryon/:id`); the server derives the
  /// owning vendor and the phase from it. [targetFolder] is where the result
  /// is stored, e.g. `results/tryon-results`.
  Future<Result<TryonResult>> executeTryon({
    required String garmentUrl,
    required String humanImageUrl,
    String mode = 'with_garment',
    String? parentGenerationId,
    String? category,
    String? targetFolder,
  });

  /// Swap the background of an existing try-on result.
  /// Returns the new image URL.
  Future<Result<String>> changeBackground({
    required String currentImageUrl,
    required String backgroundId,
    String? generationId,
  });

  /// Modify the outfit (sleeve style or neckline) of an existing result.
  /// Returns the new image URL.
  Future<Result<String>> modifyOutfitStyle({
    required String currentImageUrl,
    required String modificationType,
    String? generationId,
  });

  /// Fetch a single generation by ID.
  Future<Result<TryonResult>> fetchGeneration(String id);
}
