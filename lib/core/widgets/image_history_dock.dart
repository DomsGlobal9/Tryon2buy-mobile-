import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/customer_tryon/domain/entities/selfie_record.dart';
import '../theme/app_colors.dart';

class ImageHistoryDock extends StatelessWidget {
  final List<SelfieRecord> history;
  final String? activeImageId;
  final ValueChanged<SelfieRecord> onSelectImage;
  final VoidCallback onAddImage;

  const ImageHistoryDock({
    super.key,
    required this.history,
    this.activeImageId,
    required this.onSelectImage,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // The dock fills the width it is given and lets the thumbnail strip
      // scroll inside what is left. A shrink-wrapped strip in a min-width
      // row grew with every photo (ten thumbnails is ~500 px) and overflowed
      // the screen once the history held six or more.
      child: Row(
        children: [
          // Add Photo button
          InkWell(
            onTap: onAddImage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: AppColors.border),
          const SizedBox(width: 8),
          // History thumbnails
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: history.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final isSelected = item.id == activeImageId;

                  return GestureDetector(
                    onTap: () => onSelectImage(item),
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.accentGold : AppColors.border,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.borderLight),
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppColors.accentGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
