import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/default_model.dart';

class DefaultModelPicker extends StatelessWidget {
  final List<DefaultModel> models;
  final DefaultModel? selectedModel;
  final ValueChanged<DefaultModel> onModelSelected;

  const DefaultModelPicker({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
  });

  @override
  Widget build(BuildContext context) {
    // The parent shows its own spinner while loading, so an empty list here
    // means the request finished with nothing. A spinner would never end.
    if (models.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_off_outlined, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No studio models are available right now. Pull to refresh or try again later.',
                style: AppTypography.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: models.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final model = models[index];
          final isSelected = selectedModel?.name == model.name;

          return GestureDetector(
            onTap: () => onModelSelected(model),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accentGold : AppColors.border,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: model.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.borderLight),
                      errorWidget: (context, url, error) => const Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  model.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
