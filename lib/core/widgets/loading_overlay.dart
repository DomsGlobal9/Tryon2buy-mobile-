import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;
  final double? progress;

  const LoadingOverlay({
    super.key,
    this.message = 'Generating AI virtual try-on...',
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aligning fabric drape, lighting & facial preservation',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            if (progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
