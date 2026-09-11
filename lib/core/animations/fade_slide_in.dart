import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Plays a fade-and-rise entrance as soon as the widget is built.
///
/// Use for content that appears in response to an action — a grid that just
/// finished loading, a result that just arrived. For content further down a
/// long page, prefer `RevealOnScroll`, which waits until it is actually seen.
///
/// Combine with [AppMotion.staggerFor] to cascade a list:
///
/// ```dart
/// FadeSlideIn(delay: AppMotion.staggerFor(index), child: tile)
/// ```
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  /// Slide direction. Positive rises from below, negative drops from above.
  final double direction;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.base,
    this.offset = AppMotion.riseDistance,
    this.direction = 1,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: AppMotion.enter);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;

    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.offset * widget.direction),
          child: child,
        ),
      ),
    );
  }
}
