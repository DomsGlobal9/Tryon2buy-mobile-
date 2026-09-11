import 'package:flutter/material.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/animations/pressable.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routes/app_router.dart';
import '../../data/auth_repository.dart';

/// First screen on a fresh install — the website's landing hero.
///
/// Same doors as tryon2buy.com: "Continue as Guest" opens the app without an
/// account (the studio allows ten free tries), merchants sign in or sign up,
/// and B2B partners have their own invite-only portal.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _continueAsGuest(BuildContext context) async {
    await AuthRepository().enableGuestMode();
    if (context.mounted) _enterApp(context);
  }

  /// The business portal pops with `true` on success; open the app shell
  /// and the right workspace on top of it.
  Future<void> _openBusiness(BuildContext context, String route) async {
    final ok = await Navigator.pushNamed(context, route);
    if (!context.mounted || ok != true) return;
    await AuthSession.instance.refresh();
    if (!context.mounted) return;
    _enterApp(context);
    final session = AuthSession.instance;
    if (session.isVendorSignedIn) {
      Navigator.pushNamed(
        context,
        session.isB2bPortal ? AppRouter.b2bDigitize : AppRouter.vendorWorkspace,
      );
    }
  }

  void _enterApp(BuildContext context) =>
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.5,
            child: Image.asset(
              'assets/images/hero_video_poster.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.5,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [Color(0x66000000), Color(0x00FAF7F2), AppColors.cream],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(AppAssets.logoWordmarkWhite, height: 24, fit: BoxFit.contain),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('The Ultimate\nVirtual Try-On.', style: AppTypography.display(size: 40)),
                        const SizedBox(height: 10),
                        Text(
                          "Elevate your boutique's catalog with studio-quality digital "
                          'draping. Transform flat garment photos into stunning editorial '
                          'model shots instantly, and allow your customers to try on your '
                          'fashion collection from anywhere.',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 13.5),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          children: const [
                            _Check('Zero Photoshoot Costs'),
                            _Check('Immersive Try-On'),
                            _Check('Studio-Grade Quality'),
                            _Check('Multi-Category Support'),
                          ],
                        ),
                        const SizedBox(height: 22),

                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () => _continueAsGuest(context),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: Text('CONTINUE AS GUEST', style: AppTypography.cta(size: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => _openBusiness(context, AppRouter.vendorLogin),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: const BorderSide(color: AppColors.ink),
                                    shape: const RoundedRectangleBorder(),
                                  ),
                                  child: Text('LOGIN', style: AppTypography.cta(color: AppColors.ink)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => _openBusiness(context, AppRouter.vendorSignup),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: const BorderSide(color: AppColors.ink),
                                    shape: const RoundedRectangleBorder(),
                                  ),
                                  child: Text('SIGNUP', style: AppTypography.cta(color: AppColors.ink)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Pressable(
                            onTap: () => _openBusiness(context, AppRouter.b2bLogin),
                            child: Text(
                              'ARE YOU A B2B OR WHOLESALE CLIENT? ACCESS B2B CLIENT PORTAL →',
                              textAlign: TextAlign.center,
                              style: AppTypography.eyebrow(size: 9.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _Check extends StatelessWidget {
  final String text;
  const _Check(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: AppColors.brandOrange),
        const SizedBox(width: 6),
        Text(text.toUpperCase(), style: AppTypography.eyebrow(size: 10, color: AppColors.ink, letterSpacing: 1)),
      ],
    );
  }
}
