class GarmentColour {
  final String code;
  final String name;
  final String? imageUrl;

  const GarmentColour({
    required this.code,
    required this.name,
    this.imageUrl,
  });

  factory GarmentColour.fromJson(Map<String, dynamic> json) => GarmentColour(
        code: (json['code'] ?? json['variantCode'] ?? '').toString(),
        name: (json['name'] ?? json['colourName'] ?? '').toString(),
        imageUrl: json['imageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'imageUrl': imageUrl,
      };
}

class ScannedGarment {
  final String title;
  final String? category;
  final String imageUrl;
  final String? variantCode;
  final String? colourName;
  final List<GarmentColour> colours;

  const ScannedGarment({
    required this.title,
    this.category,
    required this.imageUrl,
    this.variantCode,
    this.colourName,
    this.colours = const [],
  });

  factory ScannedGarment.fromJson(Map<String, dynamic> json) {
    final rawColours = json['colours'] as List<dynamic>?;
    final colours = rawColours
            ?.map((e) => GarmentColour.fromJson(e as Map<String, dynamic>))
            .where((c) => c.code.isNotEmpty || c.name.isNotEmpty)
            .toList() ??
        const [];

    return ScannedGarment(
      title: json['title'] as String? ?? 'Garment',
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      variantCode: json['variantCode'] as String?,
      colourName: json['colourName'] as String?,
      colours: colours,
    );
  }

  /// Title formatted for display (with colour name appended if present).
  String get displayTitle =>
      (colourName != null && colourName!.trim().isNotEmpty)
          ? '$title — $colourName'
          : title;
}
