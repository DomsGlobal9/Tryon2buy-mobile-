import '../../domain/entities/dock_garment.dart';

/// JSON → domain mapping for garments from `GET /api/tryon/dock/garments`.
class DockGarmentDto {
  const DockGarmentDto._();

  static DockGarment fromJson(Map<String, dynamic> json) {
    return DockGarment(
      id: json['id'] as String? ?? '',
      primaryAssetId: json['primaryAssetId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      tryOnCount: json['tryOnCount'] as int? ?? 0,
      lastTriedAt: _parseDate(json['lastTriedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
