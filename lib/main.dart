import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/api_endpoints.dart';
import 'core/storage/local_storage_service.dart';

void main() {
  // Everything before `runApp` delays the first frame, so the goal is to reach
  // it in as few statements as possible. Orientation locking and disk-backed
  // storage are both started here but deliberately *not* awaited: the splash
  // owns waiting for storage (with a timeout), and orientation applies on the
  // platform thread whenever it lands.
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // Never let a widget-tree exception leave the user on a frozen screen.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (kReleaseMode) {
          // Hook a crash reporter in here when one is added.
          debugPrint('[FlutterError] ${details.exceptionAsString()}');
        }
      };

      // A store build must say which backend it talks to. The compiled-in
      // default is the dev host (see ApiEndpoints), which is right for
      // `flutter run` and wrong for anything a customer installs. Refuse
      // visibly rather than write real merchants into the dev database.
      if (kReleaseMode && !ApiEndpoints.hasExplicitBaseUrl) {
        runApp(const _MisconfiguredBuildApp());
        return;
      }

      unawaited(SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]));

      // Warm the preference cache in the background. The splash awaits the same
      // future with a timeout, and every accessor null-guards, so a slow or
      // failed read degrades instead of blocking launch.
      unawaited(LocalStorageService.getInstance().catchError(
        (Object _) => LocalStorageService(),
      ));

      runApp(const ProviderScope(child: TryOn2BuyApp()));
    },
    (error, stack) {
      debugPrint('[Uncaught] $error\n$stack');
    },
  );
}

/// Shown instead of the app when a release build was made without
/// `--dart-define-from-file=env/prod.json` (or another `API_BASE_URL`).
class _MisconfiguredBuildApp extends StatelessWidget {
  const _MisconfiguredBuildApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'This build was made without an API_BASE_URL.\n\n'
              'Rebuild with:\n'
              'flutter build … --dart-define-from-file=env/prod.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
