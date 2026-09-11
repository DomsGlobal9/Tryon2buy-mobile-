import 'package:flutter/material.dart';

import '../../../../core/animations/reveal_on_scroll.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../catalog/data/models/dress_product_model.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';
import '../../../shop/data/shop_repository.dart';
import '../../../vendor/presentation/merchant_portal.dart';
import '../widgets/category_rail.dart';
import '../widgets/home_header.dart';
import '../widgets/home_hero_carousel.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/how_it_works_strip.dart';
import '../widgets/merchant_banner.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/trending_rail.dart';

/// The app's Home tab, laid out like a native shopping app rather than the
/// website's marketing page.
///
/// Top to bottom:
///   1. Header — wordmark, greeting, account button (scrolls away, no navbar)
///   2. Search pill → full-screen search
///   3. Hero carousel — swipeable promo cards with dots
///   4. Quick actions — Try On · Catalog · My Looks · Merchant
///   5. Category rail — round avatars per garment type → filtered search
///   6. Trending now — real catalog products, horizontally scrolling
///   7. How it works — compact 3-step card
///   8. Merchant banner
///
/// Pull down to refresh the catalog rail.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  /// Bumped on pull-to-refresh; keying the rail on it remounts it, which
  /// re-runs its fetch without the rail needing a public reload API.
  int _refreshEpoch = 0;

  // ── Navigation ─────────────────────────────────────────────────────────

  /// Inside the nav shell, switch tabs so the bottom bar stays put. Standalone
  /// (reached from the merchant workspace's storefront link) there is no
  /// shell, so push the equivalent route instead.
  void _goToTab(int tab, String fallbackRoute) {
    final shell = MainShellScope.maybeOf(context);
    if (shell != null) {
      shell.goToTab(tab);
    } else {
      Navigator.pushNamed(context, fallbackRoute);
    }
  }

  void _openDiscover() => _goToTab(1, AppRouter.catalog);
  void _openMyLooks() => _goToTab(2, AppRouter.customerLibrary);
  void _openProfile() => _goToTab(3, AppRouter.profile);
  void _openMerchant() => openMerchantPortal(context);
  void _openSearch() => AppRouter.openSearch(context);

  void _openCategory(String category) =>
      AppRouter.openSearch(context, category: category);

  void _openProduct(DressProductModel product) => AppRouter.openStudio(
        context,
        garmentImageUrl: product.frontViewUrl,
        title: product.name,
        category: product.category,
        generationId: product.generationId,
      );

  /// The website's "Continue as Guest": straight into the studio, no
  /// account needed. A signed-in business goes to its own workspace.
  Future<void> _openWorkspace() async {
    if (AuthSession.instance.isVendorSignedIn) {
      await openMerchantPortal(context);
      return;
    }
    final storage = await LocalStorageService.getInstance();
    await storage.setGuestMode(true);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRouter.vendorWorkspace);
  }

  Future<void> _refresh() async {
    // Pull-to-refresh must reach the server, not the shared 90s cache.
    ShopRepository.invalidateCache();
    setState(() => _refreshEpoch++);
    // Keep the indicator visible long enough to register as a refresh; the
    // remounted rail shows its own skeleton while the request is in flight.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        color: AppColors.brandOrange,
        backgroundColor: AppColors.surface,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  HomeHeader(
                    onAccountTap: _openProfile,
                    onSignInTap: () =>
                        Navigator.pushNamed(context, AppRouter.vendorLogin),
                  ),
                  HomeSearchBar(onTap: _openSearch),
                  const SizedBox(height: 14),

                  // Above the fold: RevealOnScroll fires on first frame.
                  RevealOnScroll(
                    child: HomeHeroCarousel(
                      onTryOn: _openDiscover,
                      onMerchant: _openMerchant,
                    ),
                  ),
                  const SizedBox(height: 22),

                  RevealOnScroll(
                    child: QuickActionsRow(
                      onTryOn: _openWorkspace,
                      onCatalog: _openDiscover,
                      onMyLooks: _openMyLooks,
                      onMerchant: _openMerchant,
                    ),
                  ),
                  const SizedBox(height: 28),

                  RevealOnScroll(
                    child: CategoryRail(onCategoryTap: _openCategory),
                  ),
                  const SizedBox(height: 28),

                  RevealOnScroll(
                    child: TrendingRail(
                      key: ValueKey('trending-$_refreshEpoch'),
                      onSeeAll: _openDiscover,
                      onProductTap: _openProduct,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const RevealOnScroll(child: HowItWorksStrip()),
                  const SizedBox(height: 24),

                  RevealOnScroll(
                    child: MerchantBanner(onTap: _openMerchant),
                  ),
                  const SizedBox(height: 28),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
