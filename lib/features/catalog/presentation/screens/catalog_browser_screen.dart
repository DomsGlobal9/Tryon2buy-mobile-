import 'package:flutter/material.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_choice_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/outfit_card.dart';
import '../../../../routes/app_router.dart';
import '../../../search/domain/catalog_search.dart';
import '../../data/catalog_repository.dart';
import '../../data/models/dress_product_model.dart';

/// The Discover tab: the full catalog with category filters and a search
/// entry point. Categories come from the data, not a hard-coded list, so the
/// chips always match what the backend actually has.
class CatalogBrowserScreen extends StatefulWidget {
  const CatalogBrowserScreen({super.key});

  @override
  State<CatalogBrowserScreen> createState() => _CatalogBrowserScreenState();
}

class _CatalogBrowserScreenState extends State<CatalogBrowserScreen> {
  static const _all = CatalogSearch.all;

  final _repository = CatalogRepository();

  bool _isLoading = true;
  String? _error;
  List<DressProductModel> _products = const [];
  String _category = _all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => _fetch(forceRefresh: false);

  /// Pull-to-refresh: skip the shared cache and hit the server.
  Future<void> _refresh() => _fetch(forceRefresh: true);

  Future<void> _fetch({required bool forceRefresh}) async {
    setState(() {
      _isLoading = _products.isEmpty;
      _error = null;
    });

    final response =
        await _repository.fetchCatalogDresses(forceRefresh: forceRefresh);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _products = response.data!;
      } else {
        _error = response.error ?? 'Could not load the catalog';
      }
    });
  }

  List<String> get _categories => CatalogSearch.categoriesOf(_products);

  List<DressProductModel> get _filtered =>
      CatalogSearch.filter(_products, category: _category);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () => AppRouter.openSearch(context),
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

    if (_error != null) {
      return EmptyStateView.error(
        title: 'Could not load the catalog',
        message: _error!,
        onAction: _load,
      );
    }

    if (_products.isEmpty) {
      // The message says "pull down", so pulling down has to work here too.
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
                message:
                    'The collection is empty right now. Pull down to check again.',
              ),
            ),
          ],
        ),
      );
    }

    final items = _filtered;

    return RefreshIndicator(
      color: AppColors.brandOrange,
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  return AppChoiceChip(
                    label: CatalogSearch.label(c),
                    selected: c == _category,
                    onSelected: () => setState(() => _category = c),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${items.length} outfit${items.length == 1 ? '' : 's'}',
                style: AppTypography.bodyMedium,
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: Icons.search_off_rounded,
                title: 'Nothing in this category',
                message: 'Try another category or search the whole catalog.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = items[index];
                    return FadeSlideIn(
                      key: ValueKey(product.id),
                      delay: AppMotion.staggerFor(index),
                      child: OutfitCard(
                        imageUrl: product.thumbnail,
                        title: product.name,
                        subtitle: product.fabric,
                        badge: product.category,
                        onTap: () => AppRouter.openStudio(
                          context,
                          garmentImageUrl: product.frontViewUrl,
                          title: product.name,
                          category: product.category,
                          generationId: product.generationId,
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
