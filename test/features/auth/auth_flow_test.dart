import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/core/network/api_client.dart';
import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/storage/local_storage_service.dart';
import 'package:tryon2buy/features/auth/presentation/screens/signed_out_screen.dart';
import 'package:tryon2buy/features/auth/presentation/screens/vendor_login_screen.dart';
import 'package:tryon2buy/features/auth/presentation/screens/welcome_screen.dart';
import 'package:tryon2buy/features/auth/presentation/widgets/auth_moment_view.dart';
import 'package:tryon2buy/features/vendor/presentation/screens/vendor_workspace_screen.dart';
import 'package:tryon2buy/routes/app_router.dart';

/// The two account moments the app used to skip: signing in jumped from the
/// form to the next screen, and signing out left the user where they were
/// with a snackbar. Both now pass through a full-screen confirmation, and
/// these pin where each one lands.

/// An unsigned JWT with a readable `exp`, which is all the client checks.
String _jwt({required Duration ttl}) {
  String part(Map<String, Object> claims) =>
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  final exp = DateTime.now().add(ttl).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${part({'vendorId': 'v1', 'role': 'merchant', 'exp': exp})}.sig';
}

Future<void> _pumpFrames(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    LocalStorageService.resetForTests();
    AuthSession.instance.resetForTests();
  });

  tearDown(() {
    ApiClient.client = http.Client();
  });

  Future<void> pumpRoute(WidgetTester tester, String route) async {
    // A tall phone, so the whole form and its button are on screen.
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Only [route]. A plain `initialRoute: '/vendor-login'` also builds `/`,
    // the splash, underneath, which pings the backend and leaves its
    // timers pending when the test ends.
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: route,
        onGenerateInitialRoutes: (name) =>
            [AppRouter.onGenerateRoute(RouteSettings(name: name))],
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pump();
  }

  testWidgets('a merchant sign-in shows the welcome moment, then the studio',
      (tester) async {
    ApiClient.client = MockClient((request) async {
      if (request.url.path.endsWith('/api/auth/vendor/login')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'token': _jwt(ttl: const Duration(days: 7)),
            'vendor': {
              'id': 'v1',
              'email': 'owner@shop.com',
              'name': 'Jane',
              'storeName': 'Heritage Coutures',
            },
          }),
          200,
        );
      }
      return http.Response('{}', 200);
    });

    await pumpRoute(tester, AppRouter.vendorLogin);
    expect(find.byType(VendorLoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'owner@shop.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.ensureVisible(find.text('SIGN IN TO STUDIO'));
    await tester.tap(find.text('SIGN IN TO STUDIO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // The welcome-back moment, addressed to the boutique.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AuthMomentView), findsOneWidget);
    expect(find.text('Heritage Coutures'), findsOneWidget);
    expect(AuthSession.instance.isVendorSignedIn, isTrue);

    // Then the stack is rebuilt as home → studio, with the form gone.
    await tester.pump(VendorLoginScreen.successHold);
    await _pumpFrames(tester);
    expect(find.byType(VendorWorkspaceScreen), findsOneWidget);
    expect(find.byType(VendorLoginScreen), findsNothing);
  });

  testWidgets('a rejected sign-in stays on the form with the server message',
      (tester) async {
    ApiClient.client = MockClient((request) async {
      return http.Response(
        jsonEncode({'error': 'Invalid email or password.'}),
        401,
      );
    });

    await pumpRoute(tester, AppRouter.vendorLogin);

    await tester.enterText(find.byType(TextFormField).at(0), 'owner@shop.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.ensureVisible(find.text('SIGN IN TO STUDIO'));
    await tester.tap(find.text('SIGN IN TO STUDIO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(VendorLoginScreen), findsOneWidget);
    expect(find.byType(AuthMomentView), findsNothing);
    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(AuthSession.instance.isVendorSignedIn, isFalse);
  });

  testWidgets('an empty form is refused with inline messages, not a request',
      (tester) async {
    var requests = 0;
    ApiClient.client = MockClient((_) async {
      requests++;
      return http.Response('{}', 200);
    });

    await pumpRoute(tester, AppRouter.vendorLogin);
    await tester.ensureVisible(find.text('SIGN IN TO STUDIO'));
    await tester.tap(find.text('SIGN IN TO STUDIO'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('the signed-out screen lands on the welcome screen',
      (tester) async {
    ApiClient.client = MockClient((_) async => http.Response('{}', 200));

    await pumpRoute(tester, AppRouter.signedOut);
    expect(find.byType(SignedOutScreen), findsOneWidget);
    expect(find.text("You're signed out."), findsOneWidget);

    await tester.pump(SignedOutScreen.hold);
    await _pumpFrames(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SignedOutScreen), findsNothing);
  });
}
