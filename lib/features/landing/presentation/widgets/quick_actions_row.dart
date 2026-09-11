import 'package:flutter/material.dart';

import '../../../../core/animations/pressable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Four round shortcut buttons under the hero, the way shopping apps surface
/// their top destinations without making the user hunt in the tab bar.
class QuickActionsRow extends StatelessWidget {
  final VoidCallback onTryOn;
  final VoidCallback onCatalog;
  final VoidCallback onMyLooks;
  final VoidCallback onMerchant;

  const QuickActionsRow({
    super.key,
    required this.onTryOn,
    required this.onCatalog,
    required this.onMyLooks,
    required this.onMerchant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.camera_alt_outlined,
              label: 'Try On',
              accent: true,
              onTap: onTryOn,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.grid_view_rounded,
              label: 'Catalog',
              onTap: onCatalog,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.collections_bookmark_outlined,
              label: 'My Looks',
              onTap: onMyLooks,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.storefront_outlined,
              label: 'Merchant',
              onTap: onMerchant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: accent ? AppColors.primary : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: accent ? 0.16 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: accent ? AppColors.brandOrange : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
