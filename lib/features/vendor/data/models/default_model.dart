class DefaultModel {
  final String name;
  final String imageUrl;

  const DefaultModel({
    required this.name,
    required this.imageUrl,
  });

  factory DefaultModel.fromJson(Map<String, dynamic> json) {
    return DefaultModel(
      name: json['name'] as String? ?? 'Model',
      imageUrl: json['img'] as String? ?? json['image_url'] as String? ?? '',
    );
  }
}
