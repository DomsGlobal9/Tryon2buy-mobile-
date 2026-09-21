import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/presentation/sign_out.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';
import '../../../vendor/presentation/merchant_portal.dart';

/// The Profile tab: who is signed in, shortcuts to their stuff, the merchant
/// and B2B portals, and support links.
///
/// Rebuilds from [AuthSession] so a sign-in or sign-out anywhere in the app
/// is reflected the moment the user comes back to this tab.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _supportEmail = 'info@tryon2buy.com';

  /// Read from the platform so it cannot drift from `pubspec.yaml`'s
  /// `version:` the way a literal did.
  static final Future<String> _appVersion = PackageInfo.fromPlatform()
      .then((info) => info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})')
      .catchError((Object _) => '');

  void _goToTab(BuildContext context, int tab, String fallbackRoute) {
    final shell = MainShellScope.maybeOf(context);
    if (shell != null) {
      shell.goToTab(tab);
    } else {
      Navigator.pushNamed(context, fallbackRoute);
    }
  }

  /// Confirms, clears the session, and leaves through the signed-out screen
  /// to the welcome page, like every other sign-out in the app.
  Future<void> _signOutVendor(BuildContext context) => signOutAndLeave(context);

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      UiHelpers.showSnackBar(context, 'Could not open link.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: const Text('Profile'),
      ),
      body: ListenableBuilder(
        listenable: AuthSession.instance,
        builder: (context, _) {
          final session = AuthSession.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _AccountCard(
                session: session,
                onSignIn: () => AppRouter.openSignIn(context),
                onSignOut: () => _signOutVendor(context),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Shopping'),
              _Group(children: [
                _Tile(
                  icon: Icons.collections_bookmark_outlined,
                  title: 'My Looks',
                  subtitle: session.isVendorSignedIn
                      ? 'Your draped catalog'
                      : 'Recent try-ons on this device',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.customerLibrary),
                ),
                _Tile(
                  icon: Icons.checkroom_outlined,
                  title: 'Browse catalog',
                  subtitle: 'Sarees, lehengas, kurtis and more',
                  onTap: () => _goToTab(context, 1, AppRouter.catalog),
                ),
              ]),
              const SizedBox(height: 24),

              const _SectionLabel('For businesses'),
              _Group(children: [
                _Tile(
                  icon: Icons.storefront_outlined,
                  title: session.isVendorSignedIn
                      ? (session.isB2bPortal
                          ? 'B2B workspace'
                          : 'Merchant studio')
                      : 'Merchant portal',
                  subtitle: session.isVendorSignedIn
                      ? (session.vendorStoreName ??
                          session.vendorEmail ??
                          'Signed in')
                      : 'Digitize your catalog with AI model shots',
                  onTap: () => openMerchantPortal(context),
                ),
                if (!session.isVendorSignedIn)
                  _Tile(
                    icon: Icons.business_center_outlined,
                    title: 'B2B client portal',
                    subtitle: 'Invite-only partner access',
                    onTap: () => AppRouter.openSignIn(context, b2b: true),
                  ),
                if (session.isVendorSignedIn)
                  _Tile(
                    icon: Icons.logout_rounded,
                    title: 'Sign out of merchant portal',
                    destructive: true,
                    onTap: () => _signOutVendor(context),
                  ),
              ]),
              const SizedBox(height: 24),

              // The website's top navigation: About, Solutions, Journal.
              const _SectionLabel('Explore'),
              _Group(children: [
                _Tile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Solutions',
                  subtitle: 'Saree, Lehenga, Anarkali, Sharara, Kurti',
                  onTap: () => Navigator.pushNamed(context, AppRouter.solutions),
                ),
                _Tile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Us',
                  subtitle: 'The team and the technology',
                  onTap: () => Navigator.pushNamed(context, AppRouter.about),
                ),
                _Tile(
                  icon: Icons.menu_book_outlined,
                  title: 'Journal',
                  subtitle: 'Fashion physics and ecommerce strategy',
                  onTap: () => Navigator.pushNamed(context, AppRouter.journal),
                ),
              ]),
              const SizedBox(height: 24),

              const _SectionLabel('Support'),
              _Group(children: [
                _Tile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Contact us',
                  subtitle: _supportEmail,
                  onTap: () => _open(
                    context,
                    Uri(scheme: 'mailto', path: _supportEmail),
                  ),
                ),
                _Tile(
                  icon: Icons.language_rounded,
                  title: 'Visit tryon2buy.com',
                  onTap: () =>
                      _open(context, Uri.parse(ApiEndpoints.webAppUrl)),
                ),
                // Shown in-app: the website has no privacy or terms pages
                // (its footer links are empty anchors), so a web link here
                // dropped the user on the marketing home page.
                _Tile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  onTap: () => Navigator.pushNamed(context, AppRouter.privacy),
                ),
                _Tile(
                  icon: Icons.description_outlined,
                  title: 'Terms of service',
                  onTap: () => Navigator.pushNamed(context, AppRouter.terms),
                ),
              ]),
              const SizedBox(height: 28),

              Center(
                child: FutureBuilder<String>(
                  future: _appVersion,
                  builder: (context, snapshot) {
                    final version = snapshot.data;
                    return Text(
                      version == null || version.isEmpty
                          ? 'TryOn2Buy'
                          : 'TryOn2Buy  ·  v$version',
                      style: AppTypography.labelSmall,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AuthSession session;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const _AccountCard({
    required this.session,
    required this.onSignIn,
    required this.onSignOut,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = session.isVendorSignedIn;
    final name = session.vendorStoreName ?? 'Fashion Studio';
    final email = session.vendorEmail;
    final isB2b = session.isB2bPortal;

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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: signedIn ? AppColors.ink : AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: signedIn && name.isNotEmpty
                ? Text(
                    _initials(name),
                    style: GoogleFonts.ebGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: isB2b ? const Color(0xFFC4933F) : AppColors.brandOrange,
                    ),
                  )
                : const Icon(Icons.person_outline_rounded,
                    size: 28, color: AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signedIn ? name : 'Welcome, guest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  signedIn
                      ? '${email ?? 'Signed in'} • ${isB2b ? 'B2B Client' : 'Merchant'}'
                      : 'Sign in to access your draping studio and looks',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: signedIn
                      ? OutlinedButton(
                          onPressed: onSignOut,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: AppTypography.buttonText
                                .copyWith(fontSize: 12.5),
                          ),
                          child: const Text('Sign out'),
                        )
                      : ElevatedButton(
                          onPressed: onSignIn,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            textStyle: AppTypography.buttonText
                                .copyWith(fontSize: 12.5),
                          ),
                          child: const Text('Sign in'),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.borderLight),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: color),
      title: Text(
        title,
        style: AppTypography.titleMedium.copyWith(fontSize: 14.5, color: color),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
            ),
      trailing: destructive
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
