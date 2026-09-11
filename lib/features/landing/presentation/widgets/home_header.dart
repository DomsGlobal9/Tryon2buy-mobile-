import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The home screen's top strip: wordmark and greeting on the left, and on
/// the right either a "Sign in" pill (guest) or the shopper's initials
/// avatar (signed in). A guest must never look signed in.
class HomeHeader extends StatelessWidget {
  /// Opens the Profile tab. Used when signed in.
  final VoidCallback onAccountTap;

  /// Opens the shopper sign-in screen. Used when signed out.
  final VoidCallback onSignInTap;

  const HomeHeader({
    super.key,
    required this.onAccountTap,
    required this.onSignInTap,
  });

  static String greetingFor(DateTime now, {String? name}) {
    final hour = now.hour;
    final base = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final first = name?.trim().split(RegExp(r'\s+')).first;
    return (first == null || first.isEmpty) ? base : '$base, $first';
  }

  static String initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthSession.instance,
      builder: (context, _) {
        // The website has one kind of account: the merchant. Shoppers browse
        // as guests, so "signed in" here means a business session.
        final session = AuthSession.instance;
        final signedIn = session.isVendorSignedIn;
        final name = session.vendorStoreName ?? session.vendorEmail;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      AppAssets.logoWordmarkBlack,
                      height: 22,
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signedIn
                          ? greetingFor(DateTime.now(), name: name)
                          : 'Browsing as guest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (signedIn)
                _Avatar(
                  initials: name == null ? '' : initialsOf(name),
                  onTap: onAccountTap,
                )
              else
                _SignInPill(onTap: onSignInTap),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final VoidCallback onTap;

  const _Avatar({required this.initials, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile',
      child: Material(
        color: AppColors.ink,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: initials.isEmpty
                  ? const Icon(Icons.person_rounded,
                      size: 22, color: AppColors.brandOrange)
                  : Text(
                      initials,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandOrange,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInPill extends StatelessWidget {
  final VoidCallback onTap;

  const _SignInPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.person_outline_rounded, size: 18),
        label: const Text('Sign in'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: AppTypography.buttonText.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}
