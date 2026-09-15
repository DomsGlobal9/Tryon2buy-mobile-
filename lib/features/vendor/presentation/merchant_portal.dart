import 'package:flutter/material.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../../routes/app_router.dart';

/// Sends the user to the right merchant-side screen.
///
/// A signed-in B2B client goes to the digitization workspace, a signed-in
/// merchant to the AI studio. Everyone else is shown the sign-in portal,
/// which carries them into their workspace itself once they sign in. The
/// home banner, the quick-action button and the Profile tab all share this
/// so the decision lives in exactly one place.
Future<void> openMerchantPortal(BuildContext context) async {
  final storage = await LocalStorageService.getInstance();
  if (!context.mounted) return;

  if (!storage.isVendorSignedIn) {
    await AppRouter.openSignIn(context);
    return;
  }

  final route =
      storage.isB2bPortal ? AppRouter.b2bDigitize : AppRouter.vendorWorkspace;
  await Navigator.pushNamed(context, route);
}
