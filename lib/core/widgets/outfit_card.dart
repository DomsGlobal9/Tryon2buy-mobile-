import 'package:flutter/material.dart';

import '../animations/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'remote_image.dart';

/// The one product tile used everywhere an outfit is listed: the Discover
/// grid, search results, the home "Trending" rail and a merchant's public
/// shop. Before this each screen carried its own copy of the same card.
class OutfitCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;

  /// Small pill drawn over the image's top-left corner, e.g. the category.
  final String? badge;

  final String ctaLabel;
  final VoidCallback onTap;

  /// Fixed width for use inside a horizontal list. Leave null in a grid.
  final double? width;

  const OutfitCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.ctaLabel = 'Try on',
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RemoteImage(
                    url: imageUrl,
                    fallbackIcon: Icons.checkroom,
                    decodeWidth: 600,
                  ),
                  if (badge != null && badge!.isNotEmpty)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.glassDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(fontSize: 13.5),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11.5),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 12, color: AppColors.brandOrange),
                      const SizedBox(width: 4),
                      Text(
                        ctaLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
