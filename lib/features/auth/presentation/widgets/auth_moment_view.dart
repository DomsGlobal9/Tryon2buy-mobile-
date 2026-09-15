import 'package:flutter/material.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The full-screen brand moment shown between an account action and the
/// screen it leads to: "Welcome back, Heritage Coutures" after a sign-in,
/// "You're signed out" after a sign-out.
///
/// Apps that jump straight from a form to the next screen feel like a web
/// page reloading. A short, animated confirmation tells the user the action
/// took, and gives the navigator time to rebuild the stack behind it.
///
/// The view only draws; the caller owns the timer and the navigation, so the
/// same widget serves as a route (see `SignedOutScreen`) and as an overlay
/// on the login form.
class AuthMomentView extends StatefulWidget {
  /// Dark ink background with white type (sign-out, B2B), or cream.
  final bool dark;

  final IconData icon;

  /// First line, set in the serif: "Welcome back," / "You're signed out."
  final String headline;

  /// Optional italic second line in the accent colour: the store name.
  final String? emphasis;

  final String subtitle;

  /// How long the caller will hold this view; drives the progress hairline.
  final Duration duration;

  const AuthMomentView({
    super.key,
    required this.icon,
    required this.headline,
    required this.subtitle,
    this.emphasis,
    this.dark = false,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AuthMomentView> createState() => _AuthMomentViewState();
}

class _AuthMomentViewState extends State<AuthMomentView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  late final Animation<double> _badge = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  );
  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final dark = widget.dark;
    final background = dark ? AppColors.ink : AppColors.cream;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final muted = dark ? const Color(0xFFB8AFA5) : AppColors.textSecondary;
    final accent = dark ? const Color(0xFFC4933F) : AppColors.brandOrange;

    return ColoredBox(
      color: background,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final badgeT = reduced ? 1.0 : _badge.value;
                    final textT = reduced ? 1.0 : _text.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: badgeT.clamp(0.0, 1.2).toDouble(),
                          child: Opacity(
                            opacity: badgeT.clamp(0.0, 1.0).toDouble(),
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Icon(widget.icon, size: 40, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Opacity(
                          opacity: textT,
                          child: Transform.translate(
                            offset: Offset(0, (1 - textT) * 18),
                            child: Column(
                              children: [
                                Text(
                                  widget.headline,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.display(size: 34, color: foreground),
                                ),
                                if (widget.emphasis != null &&
                                    widget.emphasis!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.emphasis!,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.display(
                                      size: 34,
                                      color: accent,
                                      style: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Text(
                                  widget.subtitle.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.eyebrow(size: 10.5, color: muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Wordmark up top, progress hairline down below: the two things
            // that make this read as "the app is doing something for you"
            // rather than a frozen frame.
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  dark ? AppAssets.logoWordmarkWhite : AppAssets.logoWordmarkBlack,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 48,
              right: 48,
              bottom: 40,
              child: _ProgressHairline(
                duration: widget.duration,
                color: accent,
                track: foreground.withValues(alpha: 0.08),
                animate: !reduced,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHairline extends StatelessWidget {
  final Duration duration;
  final Color color;
  final Color track;
  final bool animate;

  const _ProgressHairline({
    required this.duration,
    required this.color,
    required this.track,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: animate ? 0.0 : 1.0, end: 1.0),
          duration: duration,
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) => LinearProgressIndicator(
            value: t,
            minHeight: 3,
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }
}
