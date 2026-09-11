import 'package:tryon2buy/core/constants/preset_data.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';
import '../repositories/i_tryon_repository.dart';

/// Validates the modification type against known sleeve/neck presets, then delegates.
class ModifyOutfitStyleUseCase {
  final ITryonRepository _repository;

  const ModifyOutfitStyleUseCase(this._repository);

  Future<Result<String>> call({
    required String currentImageUrl,
    required String modificationType,
    String? generationId,
  }) async {
    if (currentImageUrl.trim().isEmpty) {
      return const Fail(
        ImageProcessingFailure('Generate a try-on look first before modifying sleeves/neck.'),
      );
    }

    // Validate against known preset IDs.
    final allMods = <PresetModification>[
      ...PresetData.blouseSleeves,
      ...PresetData.necklines,
    ];
    final isValid = allMods.any((m) => m.id == modificationType);
    if (!isValid) {
      return Fail(
        ImageProcessingFailure('Unknown modification type: $modificationType'),
      );
    }

    return _repository.modifyOutfitStyle(
      currentImageUrl: currentImageUrl,
      modificationType: modificationType,
      generationId: generationId,
    );
  }
}
