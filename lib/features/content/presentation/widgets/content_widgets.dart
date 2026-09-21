import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Building blocks shared by the About, Solutions and Journal pages.

class SectionPadding extends StatelessWidget {
  final Widget child;
  const SectionPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: child,
      );
}

class ContentParagraph extends StatelessWidget {
  final String text;
  const ContentParagraph(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
      );
}

class ContentBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const ContentBullet({super.key, required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 16, color: AppColors.brandOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(text, style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NumberedStep extends StatelessWidget {
  final int number;
  final String title;
  final String text;

  const NumberedStep({super.key, required this.number, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
            ),
            child: Text('$number', style: AppTypography.display(size: 20, color: AppColors.brandOrange)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: AppTypography.eyebrow(size: 13, color: AppColors.ink, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(text, style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange (or outlined) pill CTA in Merriweather, as on the marketing pages.
class ContentCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const ContentCta({super.key, required this.label, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));
    return SizedBox(
      height: 54,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandOrange,
                side: const BorderSide(color: AppColors.brandOrange, width: 2),
                shape: shape,
              ),
              child: Text(label.toUpperCase(), style: AppTypography.cta(size: 12, color: AppColors.brandOrange)),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(label.toUpperCase(), style: AppTypography.cta(size: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                shape: shape,
                elevation: 6,
                shadowColor: AppColors.brandOrange.withValues(alpha: 0.4),
              ),
            ),
    );
  }
}

/// The "Book a Demo" modal from the website's navbar and About page.
Future<void> showDemoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.asset(AppAssets.logoWordmarkBlack, height: 28)),
            const SizedBox(height: 22),
            Text('Book a Demo', style: AppTypography.display(size: 30)),
            const SizedBox(height: 12),
            Text(
              'Ready to see our Proprietary Dupatta Drape Matrix in action? Contact our enterprise team to schedule a live technical demonstration tailored to your catalog.',
              style: AppTypography.bodyMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text('EMAIL US AT', style: AppTypography.eyebrow(size: 12)),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => launchUrl(Uri(scheme: 'mailto', path: 'info@tryon2buy.com')),
                    child: Text('info@tryon2buy.com', style: AppTypography.titleMedium.copyWith(fontSize: 18)),
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
