import 'package:equatable/equatable.dart';

/// Domain entity for a cached customer selfie in the ephemeral history dock.
///
/// The 20-minute sliding expiry logic is encapsulated here as a pure computation.
class SelfieRecord extends Equatable {
  static const int expiryDurationMinutes = 20;

  final String id;
  final String imageUrl;
  final DateTime lastUsedAt;
  final bool isActive;

  const SelfieRecord({
    required this.id,
    required this.imageUrl,
    required this.lastUsedAt,
    this.isActive = false,
  });

  /// Whether this record has exceeded the 20-minute privacy window.
  bool get isExpired =>
      DateTime.now().difference(lastUsedAt).inMinutes >= expiryDurationMinutes;

  /// Remaining seconds until expiry (clamped to 0).
  int get remainingSeconds {
    final remaining = (expiryDurationMinutes * 60) -
        DateTime.now().difference(lastUsedAt).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  SelfieRecord copyWith({
    String? id,
    String? imageUrl,
    DateTime? lastUsedAt,
    bool? isActive,
  }) {
    return SelfieRecord(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, lastUsedAt, isActive];
}
