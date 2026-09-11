/// A single digitized product in the vendor's B2B catalog.
///
/// Maps directly to the `Product` Prisma model returned by
/// `GET /api/tryon/catalog/products`.
class CatalogProduct {
  final String id;
  final String vendorId;
  final String title;
  final String? description;
  final String? sku;
  final String category;
  final String primaryAssetId;
  final String? imageUrl;

  const CatalogProduct({
    required this.id,
    required this.vendorId,
    required this.title,
    this.description,
    this.sku,
    required this.category,
    required this.primaryAssetId,
    this.imageUrl,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    // The server joins `primaryAsset` when returning products. The image URL
    // can live either at the top level (from the join) or nested under the
    // asset relation — handle both to stay resilient against backend tweaks.
    final assetMap = json['primaryAsset'] as Map<String, dynamic>?;
    final imageUrl = json['imageUrl'] as String? ??
        assetMap?['imageUrl'] as String?;

    return CatalogProduct(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String? ?? json['vendor_id'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      category: json['category'] as String,
      primaryAssetId: json['primaryAssetId'] as String? ??
          json['primary_asset_id'] as String? ??
          '',
      imageUrl: imageUrl,
    );
  }

  /// Display-friendly product identifier. Prefers the merchant-provided SKU;
  /// falls back to a prefix of the UUID so every tile still has a badge.
  String get displayId {
    if (sku != null && sku!.isNotEmpty) return sku!.toUpperCase();
    return 'PRD-${id.split('-').first.toUpperCase()}';
  }
}
