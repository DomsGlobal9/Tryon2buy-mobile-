import 'package:flutter/material.dart';
import '../../../../core/constants/preset_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class OutfitModifierTabs extends StatefulWidget {
  final ValueChanged<PresetModification> onSelectModification;

  const OutfitModifierTabs({
    super.key,
    required this.onSelectModification,
  });

  @override
  State<OutfitModifierTabs> createState() => _OutfitModifierTabsState();
}

class _OutfitModifierTabsState extends State<OutfitModifierTabs> {
  int _activeTabIndex = 0; // 0 = Sleeves, 1 = Neckline
  String? _selectedModId;

  @override
  Widget build(BuildContext context) {
    final activeList = _activeTabIndex == 0
        ? PresetData.blouseSleeves
        : PresetData.necklines;

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
              const Icon(Icons.style_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Outfit & Sleeve Retoucher', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Customizes sleeves & neck cuts with Gemini Vision while freezing model identity.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 14),

          // Sub tabs: Sleeves vs Neckline
          Row(
            children: [
              ChoiceChip(
                label: const Text('Blouse Sleeves'),
                selected: _activeTabIndex == 0,
                onSelected: (_) => setState(() => _activeTabIndex = 0),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _activeTabIndex == 0 ? AppColors.textWhite : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Neckline Styles'),
                selected: _activeTabIndex == 1,
                onSelected: (_) => setState(() => _activeTabIndex = 1),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _activeTabIndex == 1 ? AppColors.textWhite : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Options Row
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = activeList[index];
                final isSelected = _selectedModId == item.id;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedModId = item.id);
                    widget.onSelectModification(item);
                  },
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.backgroundLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.accentGold : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeTabIndex == 0 ? Icons.accessibility_new : Icons.cut,
                          size: 24,
                          color: isSelected ? AppColors.accentGold : AppColors.primary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
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
