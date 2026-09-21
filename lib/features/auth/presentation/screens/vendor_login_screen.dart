import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../routes/app_router.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../widgets/auth_moment_view.dart';

/// How to open the sign-in portal. Passed as the route's arguments; see
/// [AppRouter.openSignIn].
class SignInArgs {
  /// Open on the B2B client portal instead of the merchant studio.
  final bool b2b;

  /// Open on the "Create account" tab (merchant portal only).
  final bool register;

  /// Pop with `true` once signed in, instead of opening the workspace.
  ///
  /// For flows that must resume where they were: a guest in the studio who
  /// hit the free-tier limit or tapped Save, or a shopper whose session
  /// expired mid-fitting. Everyone else is carried into their workspace.
  final bool returnToCaller;

  const SignInArgs({
    this.b2b = false,
    this.register = false,
    this.returnToCaller = false,
  });
}

/// The business sign-in portal: the website's `/login` (Merchant Studio) and
/// `/client-login` (B2B Client Portal) on one screen.
///
/// Merchant Studio is warm ivory with EB Garamond headlines and a black CTA;
/// the B2B portal is obsidian with a gold CTA. Switching between them, and
/// between Sign In and Create Account, animates rather than snapping.
///
/// A successful sign-in does not jump straight to the next screen. It shows
/// the welcome-back moment ([AuthMomentView]) and then either returns to the
/// caller or rebuilds the stack as home → workspace, so Back from the studio
/// lands on the home tab rather than on this form.
class VendorLoginScreen extends StatefulWidget {
  /// `'b2b'` for the client portal, anything else for the merchant studio.
  final String initialType;

  /// Open on the "Create account" tab (merchant portal only).
  final bool initialRegistering;

  /// See [SignInArgs.returnToCaller].
  final bool returnToCaller;

  const VendorLoginScreen({
    super.key,
    this.initialType = 'normal',
    this.initialRegistering = false,
    this.returnToCaller = false,
  });

  /// How long the welcome moment is held before moving on.
  static const Duration successHold = Duration(milliseconds: 1500);

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

enum _Portal { merchant, b2b }

/// What the success screen says.
class _Moment {
  final String headline;
  final String? emphasis;
  final String subtitle;
  final IconData icon;
  final bool dark;

  const _Moment({
    required this.headline,
    required this.emphasis,
    required this.subtitle,
    required this.icon,
    required this.dark,
  });
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  static const _obsidian = Color(0xFF140F0C);
  static const _obsidianCard = Color(0xFF1E1713);
  static const _gold = Color(0xFFC4933F);
  static const _supportEmail = 'info@tryon2buy.com';

  final _authRepo = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();

  late _Portal _portal =
      widget.initialType == 'b2b' ? _Portal.b2b : _Portal.merchant;
  late bool _registering =
      widget.initialRegistering && _portal == _Portal.merchant;

  bool _loading = false;
  bool _obscurePassword = true;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  /// Set once the server said yes; the form is covered until we move on.
  _Moment? _moment;

  bool get _isB2b => _portal == _Portal.b2b;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────

  void _switchPortal(_Portal portal) {
    if (portal == _portal) return;
    setState(() {
      _portal = portal;
      if (portal == _Portal.b2b) _registering = false;
      _autovalidate = AutovalidateMode.disabled;
    });
  }

  void _setRegistering(bool value) {
    if (value == _registering) return;
    setState(() {
      _registering = value;
      _autovalidate = AutovalidateMode.disabled;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      // From now on, fix-as-you-type feedback.
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    ApiResponse<UserModel> res;
    try {
      if (_isB2b) {
        res = await _authRepo.loginB2bClient(email: email, password: password);
      } else if (_registering) {
        res = await _authRepo.registerVendor(
          email: email,
          password: password,
          name: _nameController.text.trim(),
          storeName: _storeNameController.text.trim(),
        );
      } else {
        res = await _authRepo.loginVendor(email: email, password: password);
      }
    } catch (_) {
      res = ApiResponse.failure('Authentication failed. Please try again.');
    }
    if (!mounted) return;

    if (!res.success) {
      setState(() => _loading = false);
      UiHelpers.showSnackBar(
        context,
        res.error ??
            (_isB2b
                ? 'Access denied. This account may not have B2B permissions.'
                : _registering
                    ? 'Registration failed. Please try again.'
                    : 'Sign in failed. Please try again.'),
        isError: true,
      );
      return;
    }

    final session = AuthSession.instance;
    final name = session.vendorStoreName ?? session.vendorEmail ?? email;
    setState(() {
      _loading = false;
      _moment = _isB2b
          ? _Moment(
              headline: 'Welcome,',
              emphasis: name,
              subtitle: 'Opening your workspace',
              icon: Icons.check_rounded,
              dark: true,
            )
          : _registering
              ? _Moment(
                  headline: 'Your studio is ready,',
                  emphasis: name,
                  subtitle: 'Opening your studio',
                  icon: Icons.auto_awesome_rounded,
                  dark: false,
                )
              : _Moment(
                  headline: 'Welcome back,',
                  emphasis: name,
                  subtitle: 'Opening your studio',
                  icon: Icons.check_rounded,
                  dark: false,
                );
    });

    await Future<void>.delayed(VendorLoginScreen.successHold);
    if (!mounted) return;
    _leave();
  }

  /// Where a successful sign-in goes.
  void _leave() {
    final navigator = Navigator.of(context);
    if (widget.returnToCaller && navigator.canPop()) {
      navigator.pop(true);
      return;
    }
    if (_isB2b) {
      navigator.pushNamedAndRemoveUntil(AppRouter.b2bDigitize, (_) => false);
      return;
    }
    // Home shell underneath, studio on top: Back from the studio lands on
    // the home tab, not on this form.
    navigator.pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
    navigator.pushNamed(AppRouter.vendorWorkspace);
  }

  Future<void> _continueAsGuest() async {
    await _authRepo.enableGuestMode();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
  }

  Future<void> _contactSupport() async {
    final ok = await launchUrl(
      Uri(scheme: 'mailto', path: _supportEmail, queryParameters: {
        'subject': 'Trouble signing in to TryOn2Buy',
      }),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      UiHelpers.showSnackBar(context, 'Email us at $_supportEmail', isError: false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = _isB2b;
    final bg = dark ? _obsidian : AppColors.cream;
    final moment = _moment;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.enter,
              color: bg,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(dark: dark, pageColor: bg),
                    Transform.translate(
                      offset: const Offset(0, -36),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _Card(
                          dark: dark,
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _autovalidate,
                            child: AnimatedSize(
                              duration: AppMotion.base,
                              curve: AppMotion.enter,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: AppMotion.base,
                                switchInCurve: AppMotion.enter,
                                switchOutCurve: AppMotion.exit,
                                transitionBuilder: _fadeRise,
                                layoutBuilder: _topAligned,
                                child: dark
                                    ? _buildB2bForm(key: const ValueKey('b2b'))
                                    : _buildMerchantForm(key: const ValueKey('merchant')),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _Footer(
                      dark: dark,
                      onGuest: _continueAsGuest,
                      onSupport: _contactSupport,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            if (Navigator.canPop(context))
              Positioned(
                top: MediaQuery.paddingOf(context).top + 6,
                left: 8,
                child: _CircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
              ),

            // The welcome moment covers the whole form, so nothing can be
            // tapped twice while the stack is rebuilt behind it.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: moment == null,
                child: AnimatedOpacity(
                  opacity: moment == null ? 0 : 1,
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                  child: moment == null
                      ? const SizedBox.shrink()
                      : AuthMomentView(
                          dark: moment.dark,
                          icon: moment.icon,
                          headline: moment.headline,
                          emphasis: moment.emphasis,
                          subtitle: moment.subtitle,
                          duration: VendorLoginScreen.successHold,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _fadeRise(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  static Widget _topAligned(Widget? current, List<Widget> previous) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [...previous, if (current != null) current],
    );
  }

  // ── Merchant Studio ────────────────────────────────────────────────

  Widget _buildMerchantForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.base,
          transitionBuilder: _fadeRise,
          layoutBuilder: _topAligned,
          child: Column(
            key: ValueKey(_registering),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _registering ? 'Create your studio' : 'Welcome back',
                style: AppTypography.display(size: 30),
              ),
              const SizedBox(height: 6),
              Text(
                _registering
                    ? 'Digitize your catalog and give your customers a fitting room.'
                    : 'Sign in to manage your digital catalog and virtual try-ons.',
                style: AppTypography.bodyMedium.copyWith(fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        _SegmentedTabs(
          index: _registering ? 1 : 0,
          labels: const ['Sign in', 'Create account'],
          onChanged: _loading ? null : (i) => _setRegistering(i == 1),
        ),
        const SizedBox(height: 22),

        AnimatedSize(
          duration: AppMotion.base,
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: _registering
              ? Column(
                  children: [
                    _Field(
                      label: 'Owner name',
                      hint: 'e.g. Jane Doe',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => Validators.name(v ?? ''),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Boutique name',
                      hint: 'e.g. Heritage Coutures',
                      controller: _storeNameController,
                      icon: Icons.storefront_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Please enter your boutique or store name.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),

        _Field(
          label: 'Email address',
          hint: 'you@yourboutique.com',
          controller: _emailController,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) => Validators.email(v ?? ''),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Password',
          hint: _registering ? 'At least 6 characters' : '••••••••',
          controller: _passwordController,
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_loading) _submit();
          },
          validator: (v) => Validators.password(v ?? ''),
          suffix: _EyeButton(
            obscured: _obscurePassword,
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 26),

        _CtaButton(
          label: _registering ? 'Create merchant account' : 'Sign in to studio',
          loading: _loading,
          onPressed: _submit,
          background: AppColors.ink,
          foreground: Colors.white,
        ),
        const SizedBox(height: 26),

        const Divider(color: Color(0x141A1410), height: 1),
        const SizedBox(height: 18),
        _PortalSwitch(
          question: 'Are you a B2B or wholesale client?',
          action: 'Access B2B Client Portal',
          dark: false,
          onTap: _loading ? null : () => _switchPortal(_Portal.b2b),
        ),
      ],
    );
  }

  // ── B2B Client Portal ──────────────────────────────────────────────

  Widget _buildB2bForm({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'CLIENT LOGIN',
                style: AppTypography.eyebrow(size: 11, color: Colors.white, letterSpacing: 2.4),
              ),
            ),
            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12))),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Enterprise workspace for garment digitization and your wholesale catalog.',
          textAlign: TextAlign.center,
          style: AppTypography.grotesk(size: 13, color: const Color(0xFFB5A799)),
        ),
        const SizedBox(height: 24),

        _Field(
          label: 'Business email',
          hint: 'client@brand.com',
          controller: _emailController,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          dark: true,
          validator: (v) => Validators.email(v ?? ''),
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Password',
          hint: '••••••••',
          controller: _passwordController,
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_loading) _submit();
          },
          dark: true,
          validator: (v) => Validators.password(v ?? ''),
          suffix: _EyeButton(
            obscured: _obscurePassword,
            dark: true,
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 26),

        _CtaButton(
          label: 'Access portal',
          loading: _loading,
          onPressed: _submit,
          background: _gold,
          foreground: _obsidian,
        ),
        const SizedBox(height: 26),

        Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        const SizedBox(height: 18),
        _PortalSwitch(
          question: 'Are you a merchant?',
          action: 'Go to Studio Portal',
          dark: true,
          onTap: _loading ? null : () => _switchPortal(_Portal.merchant),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Pieces
// ═══════════════════════════════════════════════════════════════════════

/// Brand image with the wordmark and portal name over a scrim that fades
/// into the page colour, so the card below appears to rise out of it.
class _Hero extends StatelessWidget {
  final bool dark;
  final Color pageColor;

  const _Hero({required this.dark, required this.pageColor});

  @override
  Widget build(BuildContext context) {
    final asset = dark ? 'assets/images/hero_video_poster.jpg' : 'assets/images/tryon_models.png';
    final eyebrow = dark ? 'B2B CLIENT PORTAL' : 'MERCHANT STUDIO';

    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.slow,
            child: Image.asset(
              asset,
              key: ValueKey(asset),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: 1200,
              filterQuality: FilterQuality.medium,
            ),
          ),
          AnimatedContainer(
            duration: AppMotion.base,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  Colors.black.withValues(alpha: dark ? 0.6 : 0.45),
                  Colors.black.withValues(alpha: dark ? 0.35 : 0.05),
                  pageColor,
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(AppAssets.logoWordmarkWhite, height: 24, fit: BoxFit.contain),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: AppMotion.base,
                    child: Text(
                      eyebrow,
                      key: ValueKey(eyebrow),
                      style: AppTypography.eyebrow(
                        size: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool dark;
  final Widget child;

  const _Card({required this.dark, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.enter,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: dark ? _VendorLoginScreenState._obsidianCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.08) : AppColors.creamBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.4 : 0.10),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Two-option pill switch with a sliding indicator.
class _SegmentedTabs extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int>? onChanged;

  const _SegmentedTabs({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.base,
                curve: AppMotion.enter,
                left: index * width,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onChanged == null ? null : () => onChanged!(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppMotion.fast,
                            style: AppTypography.eyebrow(
                              size: 12,
                              letterSpacing: 1.5,
                              color: i == index ? AppColors.ink : AppColors.textSecondary,
                            ),
                            child: Text(labels[i].toUpperCase()),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool dark;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? suffix;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.dark = false,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final fill = dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFDFCF9);
    final border = dark ? Colors.white.withValues(alpha: 0.12) : AppColors.border;
    final focus = dark ? _VendorLoginScreenState._gold : AppColors.ink;
    final text = dark ? Colors.white : AppColors.textPrimary;
    final hintColor = dark ? const Color(0xFF7A6F65) : AppColors.textMuted;
    final iconColor = dark ? _VendorLoginScreenState._gold : AppColors.textSecondary;

    OutlineInputBorder outline(Color color, [double width = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(
            size: 12,
            color: dark ? const Color(0xFFB8ADA0) : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autocorrect: false,
          enableSuggestions: keyboardType != TextInputType.emailAddress,
          style: AppTypography.bodyLarge.copyWith(color: text, fontWeight: FontWeight.w500),
          cursorColor: focus,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyLarge.copyWith(color: hintColor),
            prefixIcon: Icon(icon, size: 19, color: iconColor),
            suffixIcon: suffix,
            filled: true,
            fillColor: fill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: outline(border),
            enabledBorder: outline(border),
            focusedBorder: outline(focus, 1.6),
            errorBorder: outline(AppColors.error),
            focusedErrorBorder: outline(AppColors.error, 1.6),
            errorStyle: AppTypography.bodyMedium.copyWith(
              fontSize: 11.5,
              color: dark ? const Color(0xFFF5A3A3) : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _EyeButton extends StatelessWidget {
  final bool obscured;
  final bool dark;
  final VoidCallback onTap;

  const _EyeButton({required this.obscured, required this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: dark ? const Color(0xFF9E948A) : AppColors.textMuted,
      ),
      onPressed: onTap,
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  const _CtaButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.7),
          disabledForegroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: loading
              ? SizedBox(
                  key: const ValueKey('spinner'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label.toUpperCase(), style: AppTypography.cta(size: 11.5, color: foreground)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: foreground),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PortalSwitch extends StatelessWidget {
  final String question;
  final String action;
  final bool dark;
  final VoidCallback? onTap;

  const _PortalSwitch({
    required this.question,
    required this.action,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = dark ? _VendorLoginScreenState._gold : AppColors.ink;
    return Column(
      children: [
        Text(
          question.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTypography.eyebrow(size: 12, color: const Color(0xFF6B655B)),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action, style: AppTypography.cta(size: 11, color: accent, letterSpacing: 1.2)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final bool dark;
  final VoidCallback onGuest;
  final VoidCallback onSupport;

  const _Footer({required this.dark, required this.onGuest, required this.onSupport});

  @override
  Widget build(BuildContext context) {
    final muted = dark ? const Color(0xFF8C8278) : AppColors.textSecondary;
    return Column(
      children: [
        TextButton.icon(
          onPressed: onGuest,
          icon: Icon(Icons.storefront_outlined, size: 16, color: muted),
          label: Text(
            'Browse the storefront as a guest',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          style: TextButton.styleFrom(foregroundColor: muted),
        ),
        TextButton(
          onPressed: onSupport,
          style: TextButton.styleFrom(foregroundColor: muted),
          child: Text(
            'Trouble signing in? Contact support',
            style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: muted),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onTap,
      ),
    );
  }
}
