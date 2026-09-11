class GarmentModel {
  final String id;
  final String? vendorId;
  final String? label;
  final String? category;
  final String status;
  final String? primaryImageUrl;
  final Map<String, String>? pieceUrls; // e.g. {'saree': url, 'blouse': url}
  final DateTime? createdAt;

  GarmentModel({
    required this.id,
    this.vendorId,
    this.label,
    this.category,
    required this.status,
    this.primaryImageUrl,
    this.pieceUrls,
    this.createdAt,
  });

  factory GarmentModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? pieces;
    if (json['pieces'] is List) {
      pieces = {};
      for (final p in (json['pieces'] as List)) {
        if (p is Map && p['slotKey'] != null && p['imageUrl'] != null) {
          pieces[p['slotKey']] = p['imageUrl'];
        }
      }
    } else if (json['metadata'] is Map && json['metadata']['garment_urls'] is Map) {
      pieces = Map<String, String>.from(json['metadata']['garment_urls']);
    }

    return GarmentModel(
      id: json['id'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? json['vendor_id'] as String?,
      label: json['label'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      primaryImageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      pieceUrls: pieces,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
