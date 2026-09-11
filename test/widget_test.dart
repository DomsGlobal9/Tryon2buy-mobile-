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

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    LocalStorageService.resetForTests();
    AuthSession.instance.resetForTests();
    // The splash warms the backend; answer it without a network.
    ApiClient.client = MockClient((_) async => http.Response('{"status":"ok"}', 200));
  });

  tearDown(() {
    ApiClient.client = http.Client();
  });

  Future<void> pumpThroughSplash(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TryOn2BuyApp()));
    // Brand beat (700 ms) + storage, then the post-frame navigation and the
    // route transition. Pumped in fixed steps rather than `pumpAndSettle`:
    // the home shell keeps a loading spinner on its catalog tab, so the tree
    // never reaches a frame-free state to settle on.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('a fresh install lands on the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpThroughSplash(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('a returning guest lands on the home shell', (tester) async {
    SharedPreferences.setMockInitialValues({'guest_mode': true});

    await pumpThroughSplash(tester);

    expect(find.byType(MainShellScreen), findsOneWidget);
  });
}
