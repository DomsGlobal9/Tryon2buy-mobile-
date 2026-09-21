import 'package:equatable/equatable.dart';

/// A try-on result nested under a dock photo.
///
/// Maps to the shape the backend's `dock.service.js → toResult()` returns:
/// ```json
/// { "id", "resultImageUrl", "garmentImageUrl", "dockPhotoId", "createdAt" }
/// ```
class DockTryonResult extends Equatable {
  final String id;
  final String resultImageUrl;
  final String garmentImageUrl;
  final String? dockPhotoId;
  final DateTime? createdAt;

  const DockTryonResult({
    required this.id,
    required this.resultImageUrl,
    this.garmentImageUrl = '',
    this.dockPhotoId,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, resultImageUrl, garmentImageUrl, dockPhotoId, createdAt];
}
