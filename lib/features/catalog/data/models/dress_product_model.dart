/// A browsable outfit on the Discover tab and in search.
///
/// Backed by the demo collection (the website's `/shop/demo`), not the old
/// `catalog-dresses` proxy, which only ever returned three mock dresses.
/// [generationId] is what the try-on studio needs: the website opens each
/// piece as `/tryon/:id` and generates against that parent generation.
class DressProductModel {
  final String id;
  final String name;
  final String category;
  final String fabric;
  final String frontViewUrl;
  final String thumbnail;
  final String generationId;

  const DressProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.fabric,
    required this.frontViewUrl,
    required this.thumbnail,
    this.generationId = '',
  });

  factory DressProductModel.fromJson(Map<String, dynamic> json) {
    final front = json['front_view_url'] as String? ??
        json['frontViewUrl'] as String? ??
        '';
    return DressProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Designer Outfit',
      category: json['category'] as String? ?? 'Indian Wear',
      fabric: json['fabric'] as String? ?? '',
      frontViewUrl: front,
      thumbnail: json['thumbnail'] as String? ?? front,
      generationId: json['generationId'] as String? ?? '',
    );
  }
}
