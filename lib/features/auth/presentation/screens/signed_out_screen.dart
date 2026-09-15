import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../routes/app_router.dart';
import '../widgets/auth_moment_view.dart';

/// Shown after a business account signs out, before the welcome screen.
///
/// Signing out used to leave the user exactly where they were with a
/// snackbar, or drop them on the login form with no explanation. A dedicated
/// beat confirms the action and returns them to the app's front door.
class SignedOutScreen extends StatefulWidget {
  const SignedOutScreen({super.key});

  /// Long enough to read, short enough not to feel like a wait.
  static const Duration hold = Duration(milliseconds: 1400);

  @override
  State<SignedOutScreen> createState() => _SignedOutScreenState();
}

class _SignedOutScreenState extends State<SignedOutScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SignedOutScreen.hold, _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _leave() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.welcome, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // A tap skips the wait; nobody should feel held on a confirmation.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _leave,
      child: const Scaffold(
        body: AuthMomentView(
          dark: true,
          icon: Icons.waving_hand_rounded,
          headline: "You're signed out.",
          subtitle: 'See you next time',
          duration: SignedOutScreen.hold,
        ),
      ),
    );
  }
}
