import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tryon2buy/features/content/data/legal_content.dart';
import 'package:tryon2buy/features/content/presentation/screens/legal_screen.dart';
import 'package:tryon2buy/routes/app_router.dart';

/// The Profile tab used to send "Privacy policy" and "Terms of service" to
/// `tryon2buy.com/privacy` and `/terms`, which the website does not have.
/// These pin the in-app replacements: both routes resolve, and both
/// documents render with their headings.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpRoute(WidgetTester tester, String route) async {
    // Only [route]; a plain `initialRoute` also builds the splash at `/`
    // underneath, and its timers outlive the test.
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: route,
        onGenerateInitialRoutes: (name) =>
            [AppRouter.onGenerateRoute(RouteSettings(name: name))],
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the privacy route opens the privacy policy', (tester) async {
    await pumpRoute(tester, AppRouter.privacy);

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('Photos you upload'), findsOneWidget);
  });

  testWidgets('the terms route opens the terms of service', (tester) async {
    await pumpRoute(tester, AppRouter.terms);

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Terms of Service'), findsWidgets);
    // Far down the document, past what the list has built so far.
    await tester.scrollUntilVisible(
      find.text('Acceptable use'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Acceptable use'), findsOneWidget);
  });

  test('both documents name the company, a contact and an effective date', () {
    for (final doc in LegalDocument.values) {
      final text = LegalContent.bodyOf(doc).join('\n');
      expect(text, contains(LegalContent.contactEmail), reason: doc.name);
      expect(text, contains(LegalContent.effectiveDate), reason: doc.name);
      expect(text, contains(LegalContent.company), reason: doc.name);
    }
  });
}
