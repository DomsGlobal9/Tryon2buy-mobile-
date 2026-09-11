import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/preset_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class BackgroundSelectorSheet extends StatelessWidget {
  final String? selectedBackgroundId;
  final ValueChanged<PresetBackground> onSelectBackground;

  const BackgroundSelectorSheet({
    super.key,
    this.selectedBackgroundId,
    required this.onSelectBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wallpaper, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('AI Background Environments', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Composites you seamlessly into luxury venues with realistic lighting & shadows.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PresetData.backgrounds.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final bg = PresetData.backgrounds[index];
                final isSelected = selectedBackgroundId == bg.id;

                return GestureDetector(
                  onTap: () => onSelectBackground(bg),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accentGold : AppColors.border,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: bg.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.borderLight),
                            errorWidget: (context, url, error) => const Icon(Icons.image),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 76,
                        child: Text(
                          bg.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
