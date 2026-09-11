import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/animations/pressable.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/app_choice_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../routes/app_router.dart';
import '../../data/catalog_repository.dart';
import '../../data/models/catalog_product.dart';

/// Product catalog grid for B2B clients — the counterpart to
/// [CustomerLibraryScreen] for digitized products.
///
/// Same architectural pattern: fetch → grid → optimistic delete → rollback.
class B2bCatalogScreen extends StatefulWidget {
  const B2bCatalogScreen({super.key});

  @override
  State<B2bCatalogScreen> createState() => _B2bCatalogScreenState();
}

class _B2bCatalogScreenState extends State<B2bCatalogScreen> {
  final _catalogRepo = CatalogRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<CatalogProduct> _products = const [];

  /// Search filter — applied locally against title and SKU.
  String _searchQuery = '';

  /// Category filter — empty string means "all".
  String _categoryFilter = '';

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onSession);
    _load();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onSession);
    super.dispose();
  }

  /// The token was dropped (expired or rejected); every route here needs it.
  void _onSession() {
    if (!mounted || AuthSession.instance.isVendorSignedIn) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.b2bLogin, (_) => false);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _catalogRepo.fetchProducts();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _products = res.data!;
      } else {
        _errorMessage = res.error;
      }
    });
  }

  List<CatalogProduct> get _filteredProducts {
    var list = _products;

    if (_categoryFilter.isNotEmpty) {
      list = list.where((p) => p.category == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.title.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  /// All unique categories present in the catalog, for the filter chips.
  List<String> get _categories {
    final set = <String>{};
    for (final p in _products) {
      set.add(p.category);
    }
    return set.toList()..sort();
  }

  // ── Delete (optimistic rollback — copied from CustomerLibraryScreen) ──

  Future<void> _confirmDelete(CatalogProduct product) async {
    final confirmed = await UiHelpers.confirm(
      context,
      title: 'Delete this product?',
      message: 'This removes "${product.title}" from your catalog permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await _delete(product);
  }

  Future<void> _delete(CatalogProduct product) async {
    final index = _products.indexOf(product);
    if (index < 0) return;

    // Optimistic removal
    setState(() => _products = List.of(_products)..removeAt(index));

    final response = await _catalogRepo.deleteProduct(product.id);
    if (!mounted) return;

    if (response.success) {
      UiHelpers.showSnackBar(context, 'Product deleted.');
    } else {
      setState(() {
        final restored = List.of(_products);
        restored.insert(index.clamp(0, restored.length), product);
        _products = restored;
      });
      UiHelpers.showSnackBar(
        context,
        response.error ?? 'Could not delete this product.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Digitize New Product',
            onPressed: () => Navigator.pushNamed(context, AppRouter.b2bDigitize),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return EmptyStateView.error(
        title: 'Could not load your catalog',
        message: _errorMessage!,
        onAction: _load,
      );
    }

    if (_products.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: 'Your catalog is empty',
        message:
            'Digitize your first product to see it here. Upload garment images '
            'and our AI will create a catalog-ready studio shoot.',
        actionLabel: 'Digitize Product',
        onAction: () => Navigator.pushNamed(context, AppRouter.b2bDigitize),
      );
    }

    final filtered = _filteredProducts;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search by title or SKU…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // Category filter chips
          if (_categories.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      AppChoiceChip(
                        label: 'All',
                        selected: _categoryFilter.isEmpty,
                        onSelected: () =>
                            setState(() => _categoryFilter = ''),
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AppChoiceChip(
                              label: cat,
                              selected: _categoryFilter == cat,
                              onSelected: () =>
                                  setState(() => _categoryFilter = cat),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),

          // Product count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${filtered.length} product${filtered.length == 1 ? '' : 's'}',
                style: AppTypography.bodyMedium,
              ),
            ),
          ),

          // Product grid — same delegate as CustomerLibraryScreen
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = filtered[index];
                  return FadeSlideIn(
                    key: ValueKey(product.id),
                    delay: AppMotion.staggerFor(index),
                    child: _ProductTile(
                      product: product,
                      onDelete: () => _confirmDelete(product),
                      // "Try It On": the website opens
                      // `/vendor/preview/:primaryAssetId`, i.e. the fitting
                      // room anchored to the product's drape.
                      onTap: () => AppRouter.openStudio(
                        context,
                        garmentImageUrl: product.imageUrl,
                        title: product.title,
                        category: product.category,
                        generationId: product.primaryAssetId,
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private Widgets ─────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: AppColors.backgroundLight),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.backgroundLight,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.backgroundLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.checkroom_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                    ),

                  // Category chip
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.glassDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.category,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Delete button
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Material(
                      color: AppColors.glassDark,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Metadata strip
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: AppTypography.titleMedium.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.displayId,
                    style: AppTypography.labelSmall,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

