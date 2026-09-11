import 'package:equatable/equatable.dart';

/// Pure domain entity representing a completed virtual try-on generation.
///
/// This is what use cases and the UI work with.
/// It is immutable, has value equality, and contains zero Flutter/HTTP/JSON logic.
class TryonResult extends Equatable {
  final String generationId;
  final String resultImageUrl;
  final String garmentImageUrl;
  final String humanImageUrl;
  final String mode;
  final int phase;
  final String? category;
  final String? vendorId;
  final String? customerId;
  final String status;
  final DateTime? createdAt;

  /// When the shopper last generated, viewed or retouched this result on
  /// this device. Drives the 20-minute privacy window of the local store.
  final DateTime? lastUsedAt;

  const TryonResult({
    required this.generationId,
    required this.resultImageUrl,
    required this.garmentImageUrl,
    required this.humanImageUrl,
    required this.mode,
    required this.phase,
    this.category,
    this.vendorId,
    this.customerId,
    required this.status,
    this.createdAt,
    this.lastUsedAt,
  });

  TryonResult copyWith({
    String? generationId,
    String? resultImageUrl,
    String? garmentImageUrl,
    String? humanImageUrl,
    String? mode,
    int? phase,
    String? category,
    String? vendorId,
    String? customerId,
    String? status,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return TryonResult(
      generationId: generationId ?? this.generationId,
      resultImageUrl: resultImageUrl ?? this.resultImageUrl,
      garmentImageUrl: garmentImageUrl ?? this.garmentImageUrl,
      humanImageUrl: humanImageUrl ?? this.humanImageUrl,
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      category: category ?? this.category,
      vendorId: vendorId ?? this.vendorId,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  List<Object?> get props => [
        generationId,
        resultImageUrl,
        garmentImageUrl,
        humanImageUrl,
        mode,
        phase,
        category,
        vendorId,
        customerId,
        status,
        createdAt,
        lastUsedAt,
      ];
}
