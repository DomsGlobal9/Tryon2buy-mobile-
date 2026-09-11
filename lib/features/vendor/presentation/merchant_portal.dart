import 'package:flutter/material.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../../routes/app_router.dart';

/// Sends the user to the right merchant-side screen.
///
/// A signed-in B2B client goes to the digitization workspace, a signed-in
/// merchant to the AI studio. Everyone else is shown the login portal first
/// and, if they sign in there, carried on to their workspace. The home
/// banner, the quick-action button and the Profile tab all share this so the
/// decision lives in exactly one place.
Future<void> openMerchantPortal(BuildContext context) async {
  var storage = await LocalStorageService.getInstance();
  if (!context.mounted) return;

  if (!_isVendorSignedIn(storage)) {
    // The portal pops with `true` on success (see VendorLoginScreen).
    final signedIn = await Navigator.pushNamed(context, AppRouter.vendorLogin);
    if (!context.mounted || signedIn != true) return;
    storage = await LocalStorageService.getInstance();
    if (!context.mounted || !_isVendorSignedIn(storage)) return;
  }

  final route =
      storage.isB2bPortal ? AppRouter.b2bDigitize : AppRouter.vendorWorkspace;
  await Navigator.pushNamed(context, route);
}

bool _isVendorSignedIn(LocalStorageService storage) => storage.isVendorSignedIn;
