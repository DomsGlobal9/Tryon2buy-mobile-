import 'package:flutter/material.dart';

/// Shared motion tokens.
///
/// Every animation in the app pulls its timing and easing from here, so motion
/// reads as one system rather than a pile of one-off durations. The values are
/// tuned for handsets: fast enough that nothing feels like waiting, slow enough
/// to be readable on a 60Hz panel.
class AppMotion {
  const AppMotion._();

  /// Tap feedback, chips, toggles. Must feel instant.
  static const Duration fast = Duration(milliseconds: 140);

  /// The default for entrances and content changes.
  static const Duration base = Duration(milliseconds: 380);

  /// Section reveals and route transitions — long enough to register as motion.
  static const Duration slow = Duration(milliseconds: 520);

  /// Gap between items in a staggered group. Kept small; 60ms × 12 items is
  /// already most of a second before the last item appears.
  static const Duration stagger = Duration(milliseconds: 55);

  /// Ceiling on cumulative stagger delay, so long grids don't crawl.
  static const Duration maxStagger = Duration(milliseconds: 420);

  /// Decelerating curve for things entering the screen.
  static const Curve enter = Curves.easeOutCubic;

  /// For things leaving, or being dismissed.
  static const Curve exit = Curves.easeInCubic;

  /// Slight overshoot — use sparingly, on single hero moments only.
  static const Curve emphasis = Curves.easeOutBack;

  /// Distance a revealing element travels upward, in logical pixels.
  static const double riseDistance = 26;

  /// Honours the OS "reduce motion" setting. When true, callers should render
  /// the final state immediately instead of animating into it.
  ///
  /// Accessibility aside, this is also what keeps widget tests deterministic.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Stagger delay for the item at [index], clamped to [maxStagger].
  static Duration staggerFor(int index) {
    final ms = stagger.inMilliseconds * index;
    return Duration(
      milliseconds: ms > maxStagger.inMilliseconds ? maxStagger.inMilliseconds : ms,
    );
  }
}
