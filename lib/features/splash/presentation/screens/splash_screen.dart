import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routes/app_router.dart';

/// First screen the user sees.
///
/// ## Why this is written defensively
///
/// A splash that navigates from a single fire-and-forget `async` call in
/// `initState` is the classic "stuck on splash" bug. Background the app
/// mid-await and the OS freezes the process, so the Dart timer never fires; if
/// Android then recreates the activity, the resumed future finds
/// `mounted == false`, returns silently, and *nothing ever navigates again*.
/// The user returns from the app switcher to a permanent spinner.
///
/// Every way to get stuck is removed here:
///
///  * **Idempotent completion** — [_leaveSplash] is guarded by [_completed], so
///    any number of triggers may call it and only the first one acts.
///  * **Lifecycle retry** — on `AppLifecycleState.resumed` we re-check, and
///    restart the bootstrap if it never finished.
///  * **Bounded awaits** — nothing on the critical path can hang forever.
///  * **A watchdog** — an absolute deadline that leaves the splash regardless
///    of what the bootstrap is doing.
///  * **No dead ends** — a failed bootstrap still enters the app. Session state
///    is re-read lazily by `ApiClient` on the first real request, so a slow
///    disk read must never block the launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Brand beat. Runs *concurrently* with real work rather than being appended
  /// to it, so it costs nothing on a warm launch where init is already done.
  static const Duration _brandBeat = Duration(milliseconds: 700);

  /// Longest we will ever wait on local storage before giving up on it.
  static const Duration _storageTimeout = Duration(seconds: 3);

  /// Absolute ceiling on the splash, whatever else happens.
  static const Duration _watchdog = Duration(seconds: 6);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  /// Set the instant we hand off to the next route. Every navigation path
  /// checks this first, so a late timer or a resume retry cannot double-push.
  bool _completed = false;

  /// True while an attempt is in flight, so `resumed` does not stack a second
  /// bootstrap on top of a healthy first one.
  bool _running = false;

  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // Backstop: whatever the bootstrap does, we are not sitting here longer.
    _watchdogTimer = Timer(_watchdog, _leaveSplash);

    _bootstrap();
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _completed) return;

    // We are back from the background and still on the splash — either the
    // bootstrap's timers were frozen and never fired, or the attempt was lost
    // with a destroyed activity. Restart it. `_leaveSplash` is idempotent, so
    // a healthy in-flight attempt completing later is harmless.
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_completed || _running) return;
    _running = true;

    try {
      // Warm the backend without blocking on it. Render cold-starts, and an
      // offline launch must still reach the UI. `ApiClient.get` folds transport
      // errors into a failure result, so this cannot throw into the zone.
      unawaited(ApiClient.get<dynamic>(ApiEndpoints.healthCheck));

      // The only genuinely required init — bounded, and non-fatal: the service
      // null-guards its getters and `ApiClient` re-awaits it per request.
      final storageReady = LocalStorageService.getInstance()
          .timeout(_storageTimeout)
          .then<void>((_) {})
          .catchError((Object _) {});

      await Future.wait<void>([
        storageReady,
        Future<void>.delayed(_brandBeat),
      ]);
    } catch (_) {
      // Deliberately swallowed. Nothing here is worth trapping the user on a
      // splash for — the app degrades gracefully without warm storage, and
      // real errors surface per-request with proper UI.
    } finally {
      _running = false;
    }

    _leaveSplash();
  }

  /// Hands off to the app. Safe to call repeatedly, from any trigger.
  Future<void> _leaveSplash() async {
    if (_completed || !mounted) return;
    _completed = true;
    _watchdogTimer?.cancel();

    final storage = LocalStorageService.readyInstance ??
        await LocalStorageService.getInstance()
            .timeout(_storageTimeout)
            .catchError((Object _) => LocalStorageService());
    if (!mounted) return;

    // ── Nothing below this line may await ────────────────────────────────
    // `_completed` is already set, so the watchdog is cancelled and the
    // resume retry returns early. One await that never resolves — a wedged
    // preferences channel on a cold start — would leave the user on a
    // spinner with nothing left to rescue them. Every read here is a
    // synchronous cache hit; the two writes are fire-and-forget.

    final rawToken = storage.getVendorToken();
    final vendorSignedIn = storage.isVendorSignedIn;
    final isB2b = storage.isB2bPortal;
    final isGuest = storage.isGuestMode();

    // Hand the session the handle we already hold, so the first screen sees
    // the real account without waiting on storage a second time.
    AuthSession.instance.adopt(storage);

    // A token past its `exp` is cleared from disk in the background. The
    // routing decision above already treats it as signed out, so the app
    // never acts on it even if the write lands late.
    if (!vendorSignedIn && rawToken != null && rawToken.isNotEmpty) {
      unawaited(AuthSession.instance.signOutVendor());
    }

    final String targetRoute;
    if (vendorSignedIn) {
      targetRoute = isB2b ? AppRouter.b2bDigitize : AppRouter.home;
    } else if (isGuest) {
      targetRoute = AppRouter.home;
    } else {
      // Fresh install, or signed out without guest mode: the website's
      // landing hero with the guest, merchant and B2B doors.
      targetRoute = AppRouter.welcome;
    }

    // Navigate after the current frame. Pushing during build/layout — or while
    // the tree is detached mid-lifecycle-transition — is how you get a torn
    // navigator or a silently dropped route.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // If anything else already moved us off the splash, do nothing.
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      Navigator.of(context).pushReplacementNamed(targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.logoWordmarkBlack,
                  width: MediaQuery.sizeOf(context).width * 0.62,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                Text(
                  'AI VIRTUAL TRY-ON',
                  style: AppTypography.bodyMedium.copyWith(
                    letterSpacing: 4,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 44),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.brandOrange),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
