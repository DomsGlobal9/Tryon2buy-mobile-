import 'package:flutter/material.dart';

import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import 'vendor_profile_edit_sheet.dart';

/// Interactive card surfacing the vendor's remaining AI credit buckets
/// (drapes, shopper try-ons, background swaps, blouse/neck edits).
class CreditBalanceCard extends StatefulWidget {
  final AuthSession session;

  const CreditBalanceCard({
    super.key,
    required this.session,
  });

  @override
  State<CreditBalanceCard> createState() => _CreditBalanceCardState();
}

class _CreditBalanceCardState extends State<CreditBalanceCard> {
  bool _isRefreshing = false;

  Future<void> _refreshCredits() async {
    setState(() => _isRefreshing = true);
    await AuthRepository().getProfile();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final isUnlimited = s.isUnlimited;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title and refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brandOrangeLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.toll_outlined,
                      size: 18,
                      color: AppColors.brandOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Studio Allowance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandOrange,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                onPressed: _isRefreshing ? null : _refreshCredits,
                tooltip: 'Refresh balance',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Unlimited Badge OR 4 Credit Buckets
          if (isUnlimited)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2118), Color(0xFF1A1410)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.all_inclusive_rounded, color: AppColors.accentGold, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlimited Studio Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enjoy unlimited drapes and shopper try-ons',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _CreditMetricPill(
                    label: 'Drapes',
                    count: s.drapeCredits,
                    icon: Icons.checkroom_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreditMetricPill(
                    label: 'Try-Ons',
                    count: s.userTryonCredits,
                    icon: Icons.camera_alt_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CreditMetricPill(
                    label: 'BG Swap',
                    count: s.bgChangeCredits,
                    icon: Icons.image_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreditMetricPill(
                    label: 'Blouse Edit',
                    count: s.blouseChangeCredits,
                    icon: Icons.auto_fix_high_outlined,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Business details shortcut
          OutlinedButton.icon(
            onPressed: () => VendorProfileEditSheet.show(context),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Edit Business Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditMetricPill extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _CreditMetricPill({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = count < 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLow ? AppColors.warning.withValues(alpha: 0.3) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isLow ? AppColors.warning : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count remaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLow ? AppColors.warning : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
