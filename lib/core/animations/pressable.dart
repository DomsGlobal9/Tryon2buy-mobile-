import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Wraps a tappable surface with a subtle press-in scale.
///
/// Cards in this app are large image tiles where a ripple is invisible against
/// the photo. A scale gives unambiguous feedback on any background, and it
/// reads as native on both platforms.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Scale at full press. Bigger cards want a subtler value.
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = (_down && enabled && !AppMotion.reduced(context))
        ? widget.pressedScale
        : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
