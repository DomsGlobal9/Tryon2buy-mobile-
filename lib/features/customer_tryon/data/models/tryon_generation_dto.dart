import 'package:equatable/equatable.dart';

import '../../domain/entities/tryon_result.dart';

/// Data Transfer Object for API JSON ↔ Dart.
///
/// This DTO handles the messy snake_case/camelCase variations from the backend.
/// It maps cleanly to the pure domain [TryonResult] entity via [toEntity].
class TryonGenerationDto extends Equatable {
  final String id;
  final String? vendorId;
  final String? customerId;
  final String? garmentId;
  final String mode;
  final int phase;
  final String? category;
  final String garmentImageUrl;
  final String humanImageUrl;
  final String? resultImageUrl;
  final String status;
  final DateTime? createdAt;

  const TryonGenerationDto({
    required this.id,
    this.vendorId,
    this.customerId,
    this.garmentId,
    required this.mode,
    required this.phase,
    this.category,
    required this.garmentImageUrl,
    required this.humanImageUrl,
    this.resultImageUrl,
    required this.status,
    this.createdAt,
  });

  /// Parses JSON handling both camelCase and snake_case field names.
  factory TryonGenerationDto.fromJson(Map<String, dynamic> json) {
    return TryonGenerationDto(
      id: json['id'] as String? ?? json['generation_id'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? json['vendor_id'] as String?,
      customerId: json['customerId'] as String? ?? json['customer_id'] as String?,
      garmentId: json['garmentId'] as String? ?? json['garment_id'] as String?,
      mode: json['mode'] as String? ?? 'with_garment',
      phase: json['phase'] as int? ?? 1,
      category: json['category'] as String?,
      garmentImageUrl: json['garmentImageUrl'] as String? ??
          json['garment_image_url'] as String? ??
          '',
      humanImageUrl: json['humanImageUrl'] as String? ??
          json['human_image_url'] as String? ??
          '',
      resultImageUrl: json['resultImageUrl'] as String? ??
          json['result_image_url'] as String?,
      status: json['status'] as String? ?? 'COMPLETED',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Maps this DTO to the pure domain entity.
  TryonResult toEntity() {
    return TryonResult(
      generationId: id,
      resultImageUrl: resultImageUrl ?? '',
      garmentImageUrl: garmentImageUrl,
      humanImageUrl: humanImageUrl,
      mode: mode,
      phase: phase,
      category: category,
      vendorId: vendorId,
      customerId: customerId,
      status: status,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        customerId,
        garmentId,
        mode,
        phase,
        category,
        garmentImageUrl,
        humanImageUrl,
        resultImageUrl,
        status,
        createdAt,
      ];
}
