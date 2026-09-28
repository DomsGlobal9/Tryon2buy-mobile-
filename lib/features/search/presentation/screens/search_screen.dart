import 'package:flutter/material.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_choice_chip.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/outfit_card.dart';
import '../../../../routes/app_router.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/data/models/dress_product_model.dart';
import '../../domain/catalog_search.dart';

/// Full-screen catalog search.
///
/// Opens with the keyboard up, filters the catalog as you type across name,
/// fabric and category, and remembers recent queries. Category avatars on the
/// home tab open this screen with [initialCategory] set, so "Saree" shows
/// every saree rather than a placeholder page.
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const SearchScreen({super.key, this.initialQuery, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _all = CatalogSearch.all;

  final _repository = CatalogRepository();
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  bool _loading = true;
  String? _error;
  List<DressProductModel> _products = const [];
  List<String> _recent = const [];

  late String _category =
      CatalogSearch.normalizeCategory(widget.initialCategory) ?? _all;
  String get _query => _controller.text.trim();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _controller.addListener(_onQueryChanged);
    _load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final storage = await LocalStorageService.getInstance();
    final response = await _repository.fetchCatalogDresses();
    if (!mounted) return;

    setState(() {
      _recent = storage.getRecentSearches();
      _loading = false;
      if (response.success && response.data != null) {
        _products = response.data!;
      } else {
        _error = response.error ?? 'Could not load the catalog';
      }
    });

    // Only steal focus when the user came here to type, not to browse a
    // category they already picked.
    if (widget.initialCategory == null && widget.initialQuery == null) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _submit(String value) async {
    final storage = await LocalStorageService.getInstance();
    await storage.addRecentSearch(value);
    if (!mounted) return;
    setState(() => _recent = storage.getRecentSearches());
  }

  Future<void> _clearRecent() async {
    final storage = await LocalStorageService.getInstance();
    await storage.clearRecentSearches();
    if (!mounted) return;
    setState(() => _recent = const []);
  }

  void _useRecent(String value) {
    _controller.text = value;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _focusNode.unfocus();
  }

  // ── Derived data ───────────────────────────────────────────────────────

  List<String> get _categories =>
      CatalogSearch.categoriesOf(_products, extra: _category);

  List<DressProductModel> get _results =>
      CatalogSearch.filter(_products, query: _query, category: _category);

  bool get _isBrowsing => _query.isEmpty && _category == _all;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: _SearchField(
          controller: _controller,
          focusNode: _focusNode,
          onSubmitted: _submit,
          onClear: () => _controller.clear(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return EmptyStateView.error(
        title: 'Could not load outfits',
        message: _error!,
        onAction: _load,
      );
    }

    return Column(
      children: [
        _CategoryStrip(
          categories: _categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        Expanded(
          child: _isBrowsing && _recent.isNotEmpty
              ? _RecentSearches(
                  items: _recent,
                  onTap: _useRecent,
                  onClear: _clearRecent,
                )
              : _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final results = _results;

    if (results.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No outfits found',
        message: _query.isEmpty
            ? 'Nothing in this category yet. Try another one.'
            : 'Nothing matches "$_query". Try a different word or category.',
        actionLabel: 'Clear filters',
        onAction: () {
          _controller.clear();
          setState(() => _category = _all);
        },
      );
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${results.length} outfit${results.length == 1 ? '' : 's'}',
              style: AppTypography.bodyMedium,
            ),
          ),
        ),
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
                final product = results[index];
                return FadeSlideIn(
                  key: ValueKey(product.id),
                  delay: AppMotion.staggerFor(index),
                  child: OutfitCard(
                    imageUrl: product.thumbnail,
                    title: product.name,
                    subtitle: product.fabric,
                    badge: product.category,
                    onTap: () {
                      if (_query.isNotEmpty) _submit(_query);
                      AppRouter.openStudio(
                        context,
                        garmentImageUrl: product.frontViewUrl,
                        title: product.name,
                        category: product.category,
                        generationId: product.generationId,
                      );
                    },
                  ),
                );
              },
              childCount: results.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmitted,
          style: AppTypography.bodyLarge.copyWith(fontSize: 14.5),
          decoration: InputDecoration(
            hintText: 'Search sarees, lehengas, kurtis…',
            hintStyle: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 21, color: AppColors.textMuted),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 19),
                    tooltip: 'Clear',
                    onPressed: onClear,
                  ),
            filled: false,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryStrip({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          return AppChoiceChip(
            label: CatalogSearch.label(c),
            selected: c == selected,
            onSelected: () => onSelected(c),
          );
        },
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const _RecentSearches({
    required this.items,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent searches', style: AppTypography.titleMedium),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear'),
            ),
          ],
        ),
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.history_rounded,
                size: 20, color: AppColors.textMuted),
            title: Text(item, style: AppTypography.bodyLarge),
            trailing: const Icon(Icons.north_west_rounded,
                size: 16, color: AppColors.textMuted),
            onTap: () => onTap(item),
          ),
      ],
    );
  }
}
