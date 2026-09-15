import 'package:flutter/material.dart';

import '../../../core/session/auth_session.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../routes/app_router.dart';

/// The one sign-out flow for every business screen: confirm, clear the
/// session, show the signed-out moment, land on the welcome screen.
///
/// The Profile tab, the merchant studio and the B2B workspace each used to
/// do this their own way (a snackbar, the login form, the home tab). Now they
/// all end at the same front door, and a relaunch after signing out shows
/// the welcome screen too, because guest mode is cleared along with the
/// account.
///
/// [beforeSignOut] runs after the user confirms and before the session is
/// cleared, for screens whose session listener would otherwise race this
/// navigation.
Future<void> signOutAndLeave(
  BuildContext context, {
  String title = 'Sign out?',
  String message = 'You can sign back in with your email and password at any time.',
  String confirmLabel = 'Sign out',
  VoidCallback? beforeSignOut,
}) async {
  final ok = await UiHelpers.confirm(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    destructive: true,
  );
  if (!ok || !context.mounted) return;

  beforeSignOut?.call();

  final storage = await LocalStorageService.getInstance();
  await storage.setGuestMode(false);
  await AuthSession.instance.signOutVendor();
  if (!context.mounted) return;

  Navigator.pushNamedAndRemoveUntil(context, AppRouter.signedOut, (_) => false);
}
