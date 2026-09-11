import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Filter chip in the app's style: ink when selected, outlined otherwise.
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: AppTypography.bodyMedium.copyWith(
        fontSize: 13,
        color: selected ? AppColors.textWhite : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
