import 'package:flutter/material.dart';

import '../../../../core/animations/pressable.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/category_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/remote_image.dart';
import 'home_section_header.dart';

/// Horizontal strip of round category avatars, one per garment category the
/// try-on engine supports — the website's five "Solutions".
///
/// Keys are the backend's spellings (`LEHANGA`, `KURTHI`): the search screen
/// filters the collection by these, so a dictionary spelling would match
/// nothing and show an empty page.
class CategoryRail extends StatelessWidget {
  /// Called with the backend category key, e.g. `SAREE`.
  final ValueChanged<String> onCategoryTap;

  const CategoryRail({super.key, required this.onCategoryTap});

  static const _categories = <_Category>[
    _Category('SAREE', AppAssets.categorySaree),
    _Category('LEHANGA', AppAssets.categoryLehenga),
    _Category('ANARKALI', AppAssets.categoryAnarkali),
    _Category('KURTHI', AppAssets.categoryKurti),
    _Category('SHARARA', AppAssets.categorySharara),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(title: 'Try on by category'),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, i) {
              final c = _categories[i];
              return Pressable(
                onTap: () => onCategoryTap(c.key),
                pressedScale: 0.94,
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipOval(
                          child: RemoteImage(
                            url: c.imageUrl,
                            fallbackIcon: Icons.checkroom,
                            decodeWidth: 200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        CategoryNames.display(c.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Category {
  final String key;
  final String imageUrl;

  const _Category(this.key, this.imageUrl);
}
