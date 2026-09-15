import 'package:flutter/material.dart';
import '../core/animations/app_page_route.dart';
import '../features/auth/presentation/screens/signed_out_screen.dart';
import '../features/auth/presentation/screens/vendor_login_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/b2b/presentation/screens/b2b_catalog_screen.dart';
import '../features/b2b/presentation/screens/b2b_digitize_screen.dart';
import '../features/catalog/presentation/screens/catalog_browser_screen.dart';
import '../features/content/presentation/screens/about_screen.dart';
import '../features/content/data/legal_content.dart';
import '../features/content/presentation/screens/journal_screen.dart';
import '../features/content/presentation/screens/legal_screen.dart';
import '../features/content/presentation/screens/solution_screen.dart';
import '../features/customer_tryon/presentation/screens/customer_tryon_studio_screen.dart';
import '../features/customer_tryon/presentation/screens/vendor_public_shop_screen.dart';
import '../features/landing/presentation/screens/landing_screen.dart';
import '../features/library/presentation/screens/customer_library_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/shell/presentation/screens/main_shell_screen.dart';
import '../features/shop/data/shop_repository.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/vendor/presentation/screens/vendor_gallery_screen.dart';
import '../features/vendor/presentation/screens/vendor_workspace_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String welcome = '/welcome';
  static const String landing = '/landing';
  static const String vendorLogin = '/vendor-login';
  static const String vendorSignup = '/vendor-signup';
  static const String signedOut = '/signed-out';
  static const String vendorWorkspace = '/vendor-workspace';
  static const String vendorGallery = '/vendor-gallery';
  static const String customerStudio = '/customer-studio';
  static const String catalog = '/catalog';
  static const String search = '/search';
  static const String vendorShop = '/vendor-shop';
  static const String customerLibrary = '/customer-library';
  static const String profile = '/profile';

  // ── Marketing pages (About, Solutions, Journal) ────────────────────────
  static const String about = '/about';
  static const String solutions = '/solutions';
  static const String solution = '/solution';
  static const String journal = '/journal';
  static const String journalPost = '/journal-post';

  // ── Legal (in-app; the website's footer links for these are empty) ────
  static const String privacy = '/privacy';
  static const String terms = '/terms';

  // ── B2B Client Portal ──────────────────────────────────────────────────
  static const String b2bLogin = '/b2b-login';
  static const String b2bDigitize = '/b2b-digitize';
  static const String b2bCatalog = '/b2b-catalog';

  // ── Typed helpers ──────────────────────────────────────────────────────
  // Every "open the studio with this garment" call used to hand-build the
  // same argument map. One helper means one place to get the keys right.

  static Future<void> openStudio(
    BuildContext context, {
    required String? garmentImageUrl,
    String? title,
    String? category,
    String? generationId,
  }) {
    return Navigator.pushNamed(
      context,
      customerStudio,
      arguments: <String, dynamic>{
        'garmentImageUrl': garmentImageUrl,
        'garmentTitle': title,
        'category': category,
        'generationId': generationId,
      },
    );
  }

  static Future<void> openSearch(
    BuildContext context, {
    String? query,
    String? category,
  }) {
    return Navigator.pushNamed(
      context,
      search,
      arguments: <String, dynamic>{'query': query, 'category': category},
    );
  }

  /// Opens the business sign-in portal.
  ///
  /// By default a successful sign-in carries the user into their workspace
  /// (home shell underneath, studio on top) and this future completes with
  /// null once the portal is gone. With [returnToCaller] the portal instead
  /// pops with `true`, for flows that must resume where they were.
  static Future<Object?> openSignIn(
    BuildContext context, {
    bool b2b = false,
    bool register = false,
    bool returnToCaller = false,
  }) {
    return Navigator.pushNamed(
      context,
      vendorLogin,
      arguments: SignInArgs(
        b2b: b2b,
        register: register,
        returnToCaller: returnToCaller,
      ),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return AppPageRoute<dynamic>(builder: (_) => const SplashScreen());

      case home:
        final tab = settings.arguments as int? ?? 0;
        return AppPageRoute<dynamic>(
          builder: (_) => MainShellScreen(initialIndex: tab),
        );

      // First-launch gate: shopper sign-in / guest, plus business portals.
      case welcome:
        return AppPageRoute<dynamic>(builder: (_) => const WelcomeScreen());

      // The bare home page, without the nav shell. Reached from the
      // merchant workspace's "public storefront" action.
      case landing:
        return AppPageRoute<dynamic>(builder: (_) => const LandingScreen());

      case vendorLogin:
        // Typed arguments from [openSignIn]; a bare 'b2b' string is the
        // older calling convention and still works.
        final args = settings.arguments;
        final signIn = args is SignInArgs
            ? args
            : SignInArgs(b2b: args == 'b2b');
        return AppPageRoute<dynamic>(
          builder: (_) => VendorLoginScreen(
            initialType: signIn.b2b ? 'b2b' : 'normal',
            initialRegistering: signIn.register,
            returnToCaller: signIn.returnToCaller,
          ),
        );

      // "Create account" from the welcome screen: same portal, second tab.
      case vendorSignup:
        return AppPageRoute<dynamic>(
          builder: (_) => const VendorLoginScreen(
            initialType: 'normal',
            initialRegistering: true,
          ),
        );

      // The beat between signing out and the welcome screen.
      case signedOut:
        return AppPageRoute<dynamic>(builder: (_) => const SignedOutScreen());

      case vendorWorkspace:
        return AppPageRoute<dynamic>(builder: (_) => const VendorWorkspaceScreen());

      case vendorGallery:
        return AppPageRoute<dynamic>(builder: (_) => const VendorGalleryScreen());

      case customerStudio:
        final args = settings.arguments as Map<String, dynamic>?;
        return AppPageRoute<dynamic>(
          builder: (_) => CustomerTryonStudioScreen(
            garmentImageUrl: args?['garmentImageUrl'] as String?,
            garmentTitle: args?['garmentTitle'] as String?,
            category: args?['category'] as String?,
            generationId: args?['generationId'] as String?,
          ),
        );

      case catalog:
        return AppPageRoute<dynamic>(builder: (_) => const CatalogBrowserScreen());

      case search:
        final args = settings.arguments as Map<String, dynamic>?;
        return AppPageRoute<dynamic>(
          builder: (_) => SearchScreen(
            initialQuery: args?['query'] as String?,
            initialCategory: args?['category'] as String?,
          ),
        );

      case customerLibrary:
        return AppPageRoute<dynamic>(builder: (_) => const CustomerLibraryScreen());

      case profile:
        return AppPageRoute<dynamic>(builder: (_) => const ProfileScreen());

      case vendorShop:
        final vendorId = settings.arguments as String? ?? ShopRepository.demoVendorId;
        return AppPageRoute<dynamic>(
          builder: (_) => VendorPublicShopScreen(vendorId: vendorId),
        );

      case b2bLogin:
        return AppPageRoute<dynamic>(
          builder: (_) => const VendorLoginScreen(initialType: 'b2b'),
        );

      case about:
        return AppPageRoute<dynamic>(builder: (_) => const AboutScreen());

      case solutions:
        return AppPageRoute<dynamic>(builder: (_) => const SolutionsIndexScreen());

      case solution:
        final key = settings.arguments as String? ?? 'saree';
        return AppPageRoute<dynamic>(builder: (_) => SolutionScreen(solutionKey: key));

      case journal:
        return AppPageRoute<dynamic>(builder: (_) => const JournalScreen());

      case journalPost:
        final slug = settings.arguments as String? ?? '';
        return AppPageRoute<dynamic>(builder: (_) => JournalPostScreen(slug: slug));

      case privacy:
        return AppPageRoute<dynamic>(
          builder: (_) => const LegalScreen(document: LegalDocument.privacy),
        );

      case terms:
        return AppPageRoute<dynamic>(
          builder: (_) => const LegalScreen(document: LegalDocument.terms),
        );

      case b2bDigitize:
        return AppPageRoute<dynamic>(builder: (_) => const B2bDigitizeScreen());

      case b2bCatalog:
        return AppPageRoute<dynamic>(builder: (_) => const B2bCatalogScreen());

      default:
        return AppPageRoute<dynamic>(
          builder: (_) => const MainShellScreen(),
        );
    }
  }
}
