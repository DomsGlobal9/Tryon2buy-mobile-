import 'package:flutter/material.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/outfit_card.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/data/models/dress_product_model.dart';
import 'home_section_header.dart';

/// "Trending now": a horizontal rail of real catalog products.
///
/// The website's home is all marketing copy; a mobile home should put actual
/// merchandise above the fold. This fetches the same public catalog endpoint
/// the Discover tab uses and shows the first few items.
class TrendingRail extends StatefulWidget {
  final VoidCallback onSeeAll;
  final ValueChanged<DressProductModel> onProductTap;

  const TrendingRail({
    super.key,
    required this.onSeeAll,
    required this.onProductTap,
  });

  @override
  State<TrendingRail> createState() => _TrendingRailState();
}

class _TrendingRailState extends State<TrendingRail> {
  static const _maxItems = 8;
  static const double _railHeight = 262;
  static const double _cardWidth = 158;

  final _repository = CatalogRepository();

  bool _loading = true;
  String? _error;
  List<DressProductModel> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _repository.fetchCatalogDresses();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        _products = response.data!.take(_maxItems).toList();
      } else {
        _error = response.error ?? 'Could not load outfits';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Trending now',
          subtitle: 'Tap any outfit to try it on',
          actionLabel: 'See all',
          onAction: widget.onSeeAll,
        ),
        SizedBox(height: _railHeight, child: _buildRail()),
      ],
    );
  }

  Widget _buildRail() {
    if (_loading) return const _SkeletonRail(cardWidth: _cardWidth);

    if (_error != null || _products.isEmpty) {
      return _InlineNotice(
        icon: _error != null ? Icons.cloud_off_outlined : Icons.checkroom,
        message: _error ?? 'No outfits in the catalog yet.',
        actionLabel: _error != null ? 'Retry' : 'Browse catalog',
        onAction: _error != null ? _load : widget.onSeeAll,
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _products.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final product = _products[i];
        return FadeSlideIn(
          delay: AppMotion.staggerFor(i),
          child: OutfitCard(
            width: _cardWidth,
            imageUrl: product.thumbnail,
            title: product.name,
            subtitle: product.fabric,
            badge: product.category,
            onTap: () => widget.onProductTap(product),
          ),
        );
      },
    );
  }
}

/// Grey placeholder cards while the catalog request is in flight, so the
/// page keeps its shape instead of jumping when the data lands.
class _SkeletonRail extends StatelessWidget {
  final double cardWidth;

  const _SkeletonRail({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) => Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Container(color: AppColors.backgroundLight)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(width: 100),
                  const SizedBox(height: 6),
                  _bar(width: 60),
                  const SizedBox(height: 10),
                  _bar(width: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width}) => Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(5),
        ),
      );
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlineNotice({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandOrange,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
