import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../routes/app_router.dart';
import '../../../shop/data/models/shop_item.dart';
import '../../../shop/data/shop_repository.dart';

/// A merchant's public collection — the website's `/shop/:vendorId`.
///
/// Every piece has "Try This On" (opens the fitting room for that drape) and
/// a copy-link button for sharing with a friend. Pass `demo` to browse the
/// master catalogue guests see.
class VendorPublicShopScreen extends StatefulWidget {
  final String vendorId;

  /// When true the screen is a tab body: no app bar of its own.
  final bool embedded;

  const VendorPublicShopScreen({
    super.key,
    required this.vendorId,
    this.embedded = false,
  });

  @override
  State<VendorPublicShopScreen> createState() => _VendorPublicShopScreenState();
}

class _VendorPublicShopScreenState extends State<VendorPublicShopScreen> {
  final _shop = ShopRepository();

  bool _isLoading = true;
  String? _error;
  List<ShopItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => _fetch(forceRefresh: false);

  /// Pull-to-refresh skips the shared 90 s cache and hits the server.
  Future<void> _refresh() => _fetch(forceRefresh: true);

  Future<void> _fetch({required bool forceRefresh}) async {
    setState(() {
      _isLoading = _items.isEmpty;
      _error = null;
    });

    final res = await _shop.fetchCollection(
      widget.vendorId,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _items = res.data!;
      } else {
        _error = res.error ?? 'Collection not found.';
      }
    });
  }

  Future<void> _copyLink(ShopItem item) async {
    await Clipboard.setData(ClipboardData(text: ApiEndpoints.shareLink(item.id)));
    if (mounted) UiHelpers.showSnackBar(context, 'Link copied to share with a friend.');
  }

  void _tryOn(ShopItem item) => AppRouter.openStudio(
        context,
        garmentImageUrl: item.displayUrl,
        title: item.title,
        category: item.category,
        generationId: item.id,
      );

  @override
  Widget build(BuildContext context) {
    final body = _body();
    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('COLLECTION', style: AppTypography.display(size: 20)),
      ),
      body: body,
    );
  }

  Widget _body() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return EmptyStateView.error(title: 'Collection not found', message: _error!, onAction: _refresh);
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.brandOrange,
        onRefresh: _refresh,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: Icons.shopping_bag_outlined,
                title: 'No items in this collection yet.',
                message: 'Check back soon — new pieces appear here as the boutique digitizes them.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.brandOrange,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Curated Collection', style: AppTypography.display(size: 30)),
                  const SizedBox(height: 6),
                  Text(
                    'SELECT A PIECE YOU LOVE AND SEE HOW IT LOOKS ON YOU — VIRTUALLY.',
                    style: AppTypography.monoLabel(size: 9.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => FadeSlideIn(
                  key: ValueKey(_items[i].id),
                  delay: AppMotion.staggerFor(i),
                  child: _CollectionCard(
                    item: _items[i],
                    onTryOn: () => _tryOn(_items[i]),
                    onCopy: () => _copyLink(_items[i]),
                  ),
                ),
                childCount: _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onTryOn;
  final VoidCallback onCopy;

  const _CollectionCard({required this.item, required this.onTryOn, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTryOn,
              child: ColoredBox(
                color: AppColors.background,
                child: RemoteImage(url: item.displayUrl, fallbackIcon: Icons.checkroom),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoLabel(size: 9),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: onTryOn,
                    icon: const Icon(Icons.auto_awesome, size: 11),
                    label: Text('TRY THIS ON', style: AppTypography.monoLabel(size: 8, color: AppColors.cream, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 36,
                height: 36,
                child: OutlinedButton(
                  onPressed: onCopy,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    backgroundColor: AppColors.cream,
                    side: BorderSide(color: AppColors.ink.withValues(alpha: 0.1)),
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
