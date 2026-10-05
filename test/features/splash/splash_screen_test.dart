import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/app.dart';
import 'package:tryon2buy/core/network/api_client.dart';
import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/storage/local_storage_service.dart';
import 'package:tryon2buy/features/auth/presentation/screens/welcome_screen.dart';
import 'package:tryon2buy/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:tryon2buy/features/splash/presentation/screens/splash_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    LocalStorageService.resetForTests();
    AuthSession.instance.resetForTests();
    ApiClient.client = MockClient((_) async => http.Response('{"status":"ok"}', 200));
  });

  tearDown(() {
    ApiClient.client = http.Client();
  });

  Future<void> pumpSplashFrames(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TryOn2BuyApp()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('splash screen renders progress indicator initially', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: TryOn2BuyApp()));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Drain timers to cleanly complete the test
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  });

  testWidgets('splash screen navigates to welcome screen on clean install without freezing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpSplashFrames(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('splash screen handles string numbers in vendor profile without TypeError crash', (tester) async {
    // Generate valid unexpired token payload
    final expiry = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
    final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}')).replaceAll('=', '');
    final payload = base64Url.encode(utf8.encode('{"id":"v1","role":"merchant","exp":$expiry}')).replaceAll('=', '');
    final validToken = '$header.$payload.signature';

    SharedPreferences.setMockInitialValues({
      'vendor_token': validToken,
      'vendor_profile': jsonEncode({
        'id': 'v1',
        'storeName': 'Test Store',
        'drapeCredits': '15',
        'userTryonCredits': '25',
        'bgChangeCredits': '10',
        'blouseChangeCredits': '5',
      }),
    });

    await pumpSplashFrames(tester);

    // Profile and shell mount safely without throwing TypeError: String is not a subtype of num?
    expect(find.byType(MainShellScreen), findsOneWidget);
    expect(AuthSession.instance.drapeCredits, 15);
    expect(AuthSession.instance.userTryonCredits, 25);
    expect(AuthSession.instance.bgChangeCredits, 10);
    expect(AuthSession.instance.blouseChangeCredits, 5);
  });
}
