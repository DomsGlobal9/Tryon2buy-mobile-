import 'package:equatable/equatable.dart';

/// A garment that has been tried on by customers, from the backend's
/// `GET /api/tryon/dock/garments` endpoint.
///
/// The garment list is derived from try-on records — it tells the shop
/// which products customers have tried today, across all devices.
class DockGarment extends Equatable {
  /// The Product ID.
  final String id;

  /// The asset ID of the product's primary image — what the try-on page
  /// navigates by.
  final String primaryAssetId;

  final String title;
  final String? category;
  final String imageUrl;
  final int tryOnCount;
  final DateTime? lastTriedAt;

  const DockGarment({
    required this.id,
    required this.primaryAssetId,
    this.title = '',
    this.category,
    this.imageUrl = '',
    this.tryOnCount = 0,
    this.lastTriedAt,
  });

  @override
  List<Object?> get props => [
        id,
        primaryAssetId,
        title,
        category,
        imageUrl,
        tryOnCount,
        lastTriedAt,
      ];
}
