import 'package:tryon2buy/core/utils/result.dart';

import '../entities/dock_garment.dart';
import '../entities/dock_photo.dart';

/// Abstract contract for all dock data operations.
///
/// The vendor dock syncs with the backend (`/api/tryon/dock/*`), while the
/// guest dock adapts the existing local stores into the same interface.
abstract interface class IDockRepository {
  /// Everything the dock holds: photos with their nested try-on results.
  Future<Result<List<DockPhoto>>> listPhotos();

  /// Adds a photo to the dock and makes it active.
  Future<Result<DockPhoto>> addPhoto(String imageUrl);

  /// Makes one photo the active one.
  Future<Result<DockPhoto>> activatePhoto(String photoId);

  /// Clears the active selection without removing anything.
  Future<Result<void>> deactivateAll();

  /// Heartbeat — extends the 20-minute window and marks "in use".
  Future<Result<void>> touchPhoto(String photoId);

  /// Removes a photo and all its try-on results.
  /// Returns `inUse: true` conflict if someone else is using it (unless [force]).
  Future<Result<void>> deletePhoto(String photoId, {bool force});

  /// The garments customers have tried on, most recent first.
  Future<Result<List<DockGarment>>> listGarments();

  /// Heartbeat for a garment being viewed.
  Future<Result<void>> touchGarment(String garmentId);

  /// Removes a garment's try-on history.
  Future<Result<void>> deleteGarment(String garmentId, {bool force});

  /// Removes a single try-on result.
  Future<Result<void>> deleteResult(String resultId);

  /// Empties the entire dock.
  Future<Result<void>> clearDock();
}
