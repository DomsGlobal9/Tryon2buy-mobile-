import 'package:flutter/material.dart';

import 'app_motion.dart';

/// The app's standard push transition: a short rise combined with a fade.
///
/// Flutter's stock Material route on Android uses a full-height vertical slide
/// that feels heavy for a browsing app with large imagery. This travels a
/// fraction of the screen and leans on opacity instead, which keeps photo-led
/// screens from appearing to "launch" at the user.
///
/// The outgoing screen fades slightly rather than sitting static, so the two
/// layers read as connected.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    this.fullscreenModal = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: AppMotion.base,
          reverseTransitionDuration: AppMotion.fast,
        );

  /// Slides up from further down, for sheet-like destinations.
  final bool fullscreenModal;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;

    final begin = fullscreenModal ? 0.10 : 0.035;

    final enter = CurvedAnimation(parent: animation, curve: AppMotion.enter);
    final leave =
        CurvedAnimation(parent: secondaryAnimation, curve: AppMotion.enter);

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, begin),
          end: Offset.zero,
        ).animate(enter),
        // Push the outgoing screen back a touch so the stack has depth.
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.85).animate(leave),
          child: child,
        ),
      ),
    );
  }
}
