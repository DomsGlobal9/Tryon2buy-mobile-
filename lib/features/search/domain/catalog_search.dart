import '../../../core/constants/category_names.dart';
import '../../catalog/data/models/dress_product_model.dart';

/// Pure catalog filtering shared by the Discover tab and the search screen.
///
/// Kept free of Flutter so it can be unit-tested directly.
class CatalogSearch {
  const CatalogSearch._();

  /// The pseudo-category that means "no category filter".
  static const String all = 'ALL';

  /// Upper-cased, trimmed category key; null when blank.
  static String? normalizeCategory(String? raw) {
    final value = raw?.trim().toUpperCase();
    return (value == null || value.isEmpty) ? null : value;
  }

  /// [all] followed by every distinct category in [products], sorted.
  /// [extra] is included even when no product carries it, so a category the
  /// user navigated to still shows as selected on an empty result.
  static List<String> categoriesOf(
    Iterable<DressProductModel> products, {
    String? extra,
  }) {
    final set = <String>{};
    for (final p in products) {
      final key = normalizeCategory(p.category);
      if (key != null) set.add(key);
    }
    final extraKey = normalizeCategory(extra);
    if (extraKey != null) set.add(extraKey);
    return [all, ...set.toList()..sort()];
  }

  /// Products matching every word of [query] (across name, fabric and
  /// category) and, unless [category] is [all], whose category contains it.
  static List<DressProductModel> filter(
    Iterable<DressProductModel> products, {
    String query = '',
    String category = all,
  }) {
    final wanted = normalizeCategory(category) ?? all;
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    return products.where((p) {
      if (wanted != all &&
          !(normalizeCategory(p.category) ?? '').contains(wanted)) {
        return false;
      }
      if (terms.isEmpty) return true;
      final haystack = '${p.name} ${p.fabric} ${p.category}'.toLowerCase();
      return terms.every(haystack.contains);
    }).toList();
  }

  /// "SAREE" → "Saree", "LEHANGA" → "Lehenga"; the [all] key → "All".
  static String label(String category) {
    if (category == all) return 'All';
    if (category.isEmpty) return category;
    return CategoryNames.display(category);
  }
}
