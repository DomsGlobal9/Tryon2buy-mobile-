import 'package:tryon2buy/core/constants/preset_data.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';
import '../repositories/i_tryon_repository.dart';

/// Validates the background ID against known presets, then delegates.
class ChangeBackgroundUseCase {
  final ITryonRepository _repository;

  const ChangeBackgroundUseCase(this._repository);

  Future<Result<String>> call({
    required String currentImageUrl,
    required String backgroundId,
    String? generationId,
  }) async {
    if (currentImageUrl.trim().isEmpty) {
      return const Fail(
        ImageProcessingFailure('Generate a try-on look first before changing backgrounds.'),
      );
    }

    final isValid = PresetData.backgrounds.any((bg) => bg.id == backgroundId);
    if (!isValid) {
      return Fail(
        ImageProcessingFailure('Unknown background: $backgroundId'),
      );
    }

    return _repository.changeBackground(
      currentImageUrl: currentImageUrl,
      backgroundId: backgroundId,
      generationId: generationId,
    );
  }
}
