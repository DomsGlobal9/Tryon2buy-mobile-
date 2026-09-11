import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Fades and lifts [child] into place the first time it scrolls into view.
///
/// This is the mobile counterpart of the web app's framer-motion
/// `whileInView` reveals. It is dependency-free: rather than an observer
/// package, it listens to the [ScrollNotificationObserver] that [Scaffold]
/// already installs above its body, and measures its own [RenderBox] against
/// the viewport on each scroll.
///
/// Design notes:
///  * **Fires once.** Content does not re-animate when you scroll back up —
///    that reads as a glitch, not polish.
///  * **Above-the-fold content animates immediately.** A first-frame check
///    means the hero does not sit invisible waiting for a scroll that never
///    comes.
///  * **Degrades safely.** With no scrollable ancestor, or with "reduce
///    motion" enabled, the child is shown at rest with no animation at all.
class RevealOnScroll extends StatefulWidget {
  final Widget child;

  /// Delay before this element starts, for staggering neighbours.
  final Duration delay;

  /// How far up the child travels as it fades in.
  final double offset;

  /// Fraction of the viewport height the element must cross before it counts
  /// as visible. 0.12 means "once its top edge is 12% up from the bottom".
  final double threshold;

  const RevealOnScroll({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = AppMotion.riseDistance,
    this.threshold = 0.12,
  });

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  ScrollNotificationObserverState? _observer;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.enter));

    // Catch content that is already on screen at first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReveal());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (AppMotion.reduced(context)) {
      _revealed = true;
      _controller.value = 1;
      return;
    }

    _observer?.removeListener(_onScroll);
    final observer = ScrollNotificationObserver.maybeOf(context);
    _observer = observer?..addListener(_onScroll);

    if (observer == null) {
      // No scrollable ancestor, so no scroll notification will ever arrive and
      // the initState visibility probe is the only trigger there is. Rather
      // than risk leaving below-the-fold content at Opacity(0) forever, show
      // it. A reveal that plays slightly early beats content that never
      // appears at all.
      _revealed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (_revealed) return;
    _maybeReveal();
  }

  void _maybeReveal() {
    if (_revealed || !mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final topY = box.localToGlobal(Offset.zero).dy;

    // Visible once the top edge has risen above the trigger line, and while
    // any part of it is still below the top of the screen.
    final triggerLine = screenHeight * (1 - widget.threshold);
    final isVisible = topY < triggerLine && topY + box.size.height > 0;
    if (!isVisible) return;

    _revealed = true;
    _observer?.removeListener(_onScroll);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value.dy * widget.offset),
          child: child,
        ),
      ),
    );
  }
}
