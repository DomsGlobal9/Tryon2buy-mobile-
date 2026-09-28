import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The studio's result canvas: a 3:4 stage that shows the generating card,
/// then the drape with the model badge, then REGENERATE / SAVE TO LIBRARY.
class WorkspaceResultPreview extends StatelessWidget {
  final String? resultImageUrl;
  final bool isGenerating;
  final String modelName;
  final bool isSaved;
  final bool isSaving;

  /// No business account signed in. The action still works — it offers to
  /// create one — so the label promises sign-in rather than a save.
  final bool isGuest;

  final VoidCallback onRegenerate;
  final VoidCallback onSaveToLibrary;

  const WorkspaceResultPreview({
    super.key,
    required this.resultImageUrl,
    required this.isGenerating,
    required this.modelName,
    required this.isSaved,
    required this.onRegenerate,
    required this.onSaveToLibrary,
    this.isSaving = false,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGenerating && resultImageUrl == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              border: Border.all(color: AppColors.creamBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: isGenerating ? _GeneratingCard(modelName: modelName) : _result(),
          ),
        ),
        if (!isGenerating && resultImageUrl != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('REGENERATE', style: AppTypography.monoLabel(size: 11.5, color: AppColors.ink)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.ink),
                      shape: const RoundedRectangleBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (isSaved || isSaving) ? null : onSaveToLibrary,
                    icon: isSaving
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                          )
                        : Icon(
                            isGuest && !isSaved
                                ? Icons.lock_outline_rounded
                                : Icons.check,
                            size: 14,
                          ),
                    label: Text(
                      isSaving
                          ? 'SAVING...'
                          : isSaved
                              ? 'SAVED TO LIBRARY'
                              : isGuest
                                  ? 'SIGN IN TO SAVE'
                                  : 'SAVE TO LIBRARY',
                      style: AppTypography.monoLabel(size: 11.5, color: AppColors.cream),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.5),
                      disabledForegroundColor: AppColors.cream,
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _result() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: resultImageUrl!,
          fit: BoxFit.cover,
          imageBuilder: (context, provider) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(scale: 1.05 - 0.05 * t, child: child),
            ),
            child: Image(image: provider, fit: BoxFit.cover),
          ),
          placeholder: (_, _) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandOrange),
          ),
          errorWidget: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.black26),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              border: Border.all(color: AppColors.creamBorder),
            ),
            child: Text(
              '$modelName — Classic Studio',
              style: AppTypography.mono(size: 12, weight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// The website's in-frame loading card with its four reassurance tiles.
class _GeneratingCard extends StatelessWidget {
  final String modelName;
  const _GeneratingCard({required this.modelName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          const Spacer(),
          Lottie.asset(
            'assets/animations/tryon_fitting.json',
            width: 140,
            height: 140,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.brandOrange),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Creating AI Catalog Shoot...',
            style: AppTypography.mono(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Draping fabric on $modelName in Classic Studio',
            textAlign: TextAlign.center,
            style: AppTypography.mono(size: 12.5, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.cream,
              border: Border.all(color: AppColors.creamBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                _Feature(Icons.auto_awesome, 'Realistic Try-On', 'Advanced AI for realistic results'),
                _Feature(Icons.shield_outlined, 'Secure & Private', 'Your images are safe and never shared'),
                _Feature(Icons.high_quality_outlined, 'High Quality', 'HD results with perfect fit'),
                _Feature(Icons.timer_outlined, 'Easy & Fast', 'Get results in just seconds'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7F5700)),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(fontSize: 9.5, height: 1.25),
          ),
        ],
      ),
    );
  }
}
