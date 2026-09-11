import 'package:flutter/material.dart';

import '../../../../core/animations/pressable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A search pill that looks like a text field but acts as a button.
///
/// Tapping it jumps to the Discover tab, which owns the real filtering. A
/// live field here would open the keyboard on a screen that has nothing to
/// filter yet.
class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.985,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  size: 22, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search sarees, lehengas, kurtis…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppColors.borderLight,
              ),
              const Icon(Icons.tune_rounded,
                  size: 20, color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
