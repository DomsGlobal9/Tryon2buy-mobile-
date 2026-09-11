import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'custom_button.dart';

/// Centered icon + title + message, with an optional action button.
///
/// Used for "nothing here yet", "sign in first" and "could not load" states.
/// One implementation replaces the three private copies that used to live in
/// the library, vendor gallery and B2B catalog screens.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Preset for a failed request.
  const EmptyStateView.error({
    super.key,
    required this.message,
    required this.onAction,
    this.title = 'Something went wrong',
    this.actionLabel = 'Retry',
  }) : icon = Icons.cloud_off_outlined;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: actionLabel!,
                onPressed: onAction,
                width: 220,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
