import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../data/legal_content.dart';

/// Privacy Policy and Terms of Service, read from [LegalContent].
///
/// Both used to open `tryon2buy.com/privacy` and `/terms`, which the website
/// does not have (its footer links are empty anchors), so the user landed on
/// the marketing home page. The store listings also require a policy that
/// can be read inside the app.
class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  static const _gold = Color(0xFF7F5700);

  Future<void> _email(BuildContext context) async {
    final ok = await launchUrl(
      Uri(scheme: 'mailto', path: LegalContent.contactEmail),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      UiHelpers.showSnackBar(context, 'Could not open your mail app.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = LegalContent.titleOf(document);
    final body = LegalContent.bodyOf(document);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(title, style: AppTypography.display(size: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(title, style: AppTypography.display(size: 34)),
          const SizedBox(height: 6),
          Text(
            'EFFECTIVE ${LegalContent.effectiveDate.toUpperCase()}',
            style: AppTypography.eyebrow(size: 10, color: _gold),
          ),
          const SizedBox(height: 22),
          for (final line in body) _block(line),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _email(context),
              icon: const Icon(Icons.mail_outline_rounded, size: 16),
              label: Text(
                LegalContent.contactEmail.toUpperCase(),
                style: AppTypography.eyebrow(size: 10, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(String line) {
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(line.substring(2), style: AppTypography.display(size: 24)),
      );
    }
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.circle, size: 6, color: _gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                line.substring(2),
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        line,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
