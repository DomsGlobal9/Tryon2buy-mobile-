import '../../../../core/constants/category_names.dart';

/// One draped garment in a merchant's public collection.
///
/// Its [id] is a generation id: the customer try-on opens it as the parent
/// generation, exactly like the website's `/tryon/:id` route.
class ShopItem {
  final String id;
  final String? category;
  final String resultImageUrl;
  final String garmentImageUrl;
  final DateTime? createdAt;

  const ShopItem({
    required this.id,
    required this.category,
    required this.resultImageUrl,
    required this.garmentImageUrl,
    this.createdAt,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        id: json['id']?.toString() ?? '',
        category: json['category'] as String?,
        resultImageUrl: json['resultImageUrl'] as String? ?? '',
        garmentImageUrl: json['garmentImageUrl'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  /// The image a shopper sees on the card: the drape if it exists.
  String get displayUrl =>
      resultImageUrl.isNotEmpty ? resultImageUrl : garmentImageUrl;

  /// "Saree", "Lehenga", … or the website's fallback label.
  String get title => CategoryNames.display(category);
}
