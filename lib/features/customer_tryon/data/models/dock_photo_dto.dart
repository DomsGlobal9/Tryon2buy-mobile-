import '../../domain/entities/dock_photo.dart';
import '../../domain/entities/dock_tryon_result.dart';

/// JSON ↔ domain mapping for dock photos and their nested results.
///
/// Matches the backend's `toPhoto()` and `toResult()` shapes from
/// `dock.service.js`.
class DockPhotoDto {
  const DockPhotoDto._();

  static DockPhoto fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    final results = rawResults
        .whereType<Map<String, dynamic>>()
        .map(_resultFromJson)
        .toList();

    return DockPhoto(
      id: json['id'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      lastUsedAt: _parseDate(json['lastUsedAt']),
      isActive: json['isActive'] as bool? ?? false,
      results: results,
    );
  }

  static DockTryonResult _resultFromJson(Map<String, dynamic> json) {
    return DockTryonResult(
      id: json['id'] as String? ?? '',
      resultImageUrl: json['resultImageUrl'] as String? ?? '',
      garmentImageUrl: json['garmentImageUrl'] as String? ?? '',
      dockPhotoId: json['dockPhotoId'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
