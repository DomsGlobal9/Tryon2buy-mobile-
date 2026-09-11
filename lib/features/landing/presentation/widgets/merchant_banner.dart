import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/animations/pressable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Dark card that invites boutique owners into the merchant portal.
///
/// Replaces the website's full-width "Create your account" CTA and the
/// footer link columns: on mobile a single tappable card does that job.
class MerchantBanner extends StatelessWidget {
  final VoidCallback onTap;

  const MerchantBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 24,
                  color: AppColors.brandOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Own a boutique?',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Turn flat garment photos into model shots and add try-on to your store.',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        color: const Color(0xFFB8AFA5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Open Merchant Portal',
                          style: AppTypography.buttonText.copyWith(
                            fontSize: 12.5,
                            color: AppColors.brandOrange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 15, color: AppColors.brandOrange),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
