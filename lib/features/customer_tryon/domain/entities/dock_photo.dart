import 'package:equatable/equatable.dart';

import 'dock_tryon_result.dart';

/// A customer photograph in the dock, with its nested try-on results.
///
/// Maps to the shape the backend's `dock.service.js → toPhoto()` returns:
/// ```json
/// {
///   "id", "imageUrl", "createdAt", "lastUsedAt", "isActive",
///   "results": [ { ... DockTryonResult ... } ]
/// }
/// ```
///
/// For vendor accounts the dock is server-synced (shared across devices);
/// for guests the facade adapts the local `SelfieRecord` + results store
/// into this same shape so the UI never knows the difference.
class DockPhoto extends Equatable {
  final String id;
  final String imageUrl;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  /// The try-on results generated from this photograph.
  final List<DockTryonResult> results;

  const DockPhoto({
    required this.id,
    required this.imageUrl,
    this.createdAt,
    this.lastUsedAt,
    this.isActive = false,
    this.results = const [],
  });

  /// How many results the UI should badge on the thumbnail.
  int get resultCount => results.length;

  DockPhoto copyWith({
    String? id,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
    List<DockTryonResult>? results,
  }) {
    return DockPhoto(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, createdAt, lastUsedAt, isActive, results];
}
