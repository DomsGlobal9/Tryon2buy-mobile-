import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The website's three credit gates, word for word.
///
/// * [showLimitReachedDialog] — `VendorLimitModal`: a guest has spent the
///   10 free tries, or a merchant has exhausted a feature's credits.
/// * [showUpgradeDialog] — `VendorUpgradeModal`: the backend answered
///   `403 INSUFFICIENT_CREDITS`.
/// * [showGuestSaveDialog] — the workspace's "Save to Library" when browsing
///   as a guest.
class CreditDialogs {
  const CreditDialogs._();

  static const contactEmail = 'contact@tryon2buy.com';
  static const infoEmail = 'info@tryon2buy.com';
}

/// Returns `true` when the user chose the dialog's primary action.
Future<bool> showLimitReachedDialog(
  BuildContext context, {
  required bool vendor,
}) {
  return _showBrandDialog(
    context,
    title: vendor ? 'Credit Limit Reached' : 'Free Trial Ended',
    body: vendor
        ? "You've used all your allocated try-on credits for this feature. Please Contact Us to upgrade your plan."
        : "You've used your 10 free trial credits! Create a free merchant account to unlock more credits and full studio features.",
    primaryLabel: vendor ? 'Contact Us' : 'Login as Vendor',
    primaryColor: AppColors.ink,
    onPrimary: vendor
        ? () => launchUrl(Uri(scheme: 'mailto', path: CreditDialogs.contactEmail))
        : null,
  );
}

Future<bool> showUpgradeDialog(
  BuildContext context, {
  bool customer = false,
}) {
  return _showBrandDialog(
    context,
    title: 'Out of Credits',
    // No number here, deliberately. The website carried "5" while every
    // allowance is in fact 10, so it said one thing and the sibling dialog
    // said another; the count was removed rather than corrected, because it
    // varies by plan and the copy would drift again.
    body: customer
        ? 'The free try-ons for this shop have all been used. Please ask the boutique for more, and keep trying on beautiful outfits.'
        : "You've used all of your free merchant try-ons! Subscribe to our Unlimited Plan to keep generating stunning personalized fits for your customers.",
    primaryLabel: 'Contact Us to Upgrade',
    primaryColor: const Color(0xFFC4933F),
    onPrimary: () => launchUrl(Uri(
      scheme: 'mailto',
      path: CreditDialogs.infoEmail,
      queryParameters: {'subject': 'Upgrade to Unlimited'},
    )),
  );
}

/// Resolves to `'account'`, `'demo'` or null (dismissed).
Future<String?> showGuestSaveDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _BrandDialog(
      title: 'Save to Library',
      body: 'To save your custom drapes to a personal library, please create a '
          'free Merchant Account.\n\nAlternatively, you can visit the Demo '
          'Gallery to try on existing collection pieces!',
      primaryLabel: 'Create Account',
      primaryColor: AppColors.ink,
      secondaryLabel: 'View Demo Gallery',
      onPrimary: () => Navigator.pop(ctx, 'account'),
      onSecondary: () => Navigator.pop(ctx, 'demo'),
      serifTitle: false,
    ),
  );
}

Future<bool> _showBrandDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String primaryLabel,
  required Color primaryColor,
  Future<void> Function()? onPrimary,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _BrandDialog(
      title: title,
      body: body,
      primaryLabel: primaryLabel,
      primaryColor: primaryColor,
      onPrimary: () async {
        Navigator.pop(ctx, true);
        if (onPrimary != null) await onPrimary();
      },
    ),
  );
  return result == true;
}

class _BrandDialog extends StatelessWidget {
  final String title;
  final String body;
  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool serifTitle;

  const _BrandDialog({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryColor,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.serifTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.logoWordmarkBlack, height: 28),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: serifTitle
                  ? AppTypography.display(size: 28)
                  : AppTypography.studioHeading(size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(primaryLabel.toUpperCase(), style: AppTypography.cta()),
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.ink),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    secondaryLabel!.toUpperCase(),
                    style: AppTypography.cta(color: AppColors.ink),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
