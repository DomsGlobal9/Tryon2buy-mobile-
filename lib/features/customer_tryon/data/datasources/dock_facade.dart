import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/utils/result.dart';

import '../../domain/entities/dock_garment.dart';
import '../../domain/entities/dock_photo.dart';
import '../../domain/entities/dock_tryon_result.dart';
import '../../domain/entities/selfie_record.dart';
import '../../domain/entities/tryon_result.dart';
import '../../domain/repositories/i_dock_repository.dart';
import 'history_local_data_source.dart';
import 'tryon_results_local_data_source.dart';

/// The "Dock Facade" — auto-selects between the server-synced remote dock
/// (vendor accounts) and the existing local SharedPreferences dock (guests).
///
/// Mirrors the website's `photoDock.js` pattern: when signed in the dock
/// belongs to the account and syncs across devices; when anonymous it stays
/// local to this device and expires after 20 minutes.
///
/// The UI consumes [DockPhoto] objects regardless of backing store, so it
/// never knows (or cares) where the data comes from.
class DockFacade {
  final IDockRepository? _remote;
  final HistoryLocalDataSource _localHistory;
  final TryonResultsLocalDataSource _localResults;

  DockFacade({
    required IDockRepository? remoteRepository,
    required HistoryLocalDataSource localHistory,
    required TryonResultsLocalDataSource localResults,
  })  : _remote = remoteRepository,
        _localHistory = localHistory,
        _localResults = localResults;

  /// Whether the dock is backed by the server.
  bool get isRemote => _remote != null && AuthSession.instance.isVendorSignedIn;

  // ── Read ────────────────────────────────────────────────────────────

  /// All photos with their try-on results, unified across both backends.
  Future<List<DockPhoto>> getPhotosWithResults() async {
    if (isRemote) {
      final result = await _remote!.listPhotos();
      return result.dataOrNull ?? const [];
    }

    // Local fallback: adapt SelfieRecords + results into DockPhotos.
    final history = await _localHistory.getValidHistory();
    final photos = <DockPhoto>[];
    for (final record in history) {
      final results = await _localResults.resultsFor(record.id);
      photos.add(_adaptLocal(record, results));
    }
    return photos;
  }

  /// Garments that customers have tried on (vendor-only).
  Future<List<DockGarment>> getGarments() async {
    if (!isRemote) return const [];
    final result = await _remote!.listGarments();
    return result.dataOrNull ?? const [];
  }

  // ── Write ───────────────────────────────────────────────────────────

  /// Add a new photo to the dock.
  ///
  /// For vendor sessions this syncs to the backend. For guests it saves to
  /// the local history store and returns the adapted [DockPhoto].
  Future<DockPhoto?> addPhoto(String imageUrl) async {
    if (isRemote) {
      final result = await _remote!.addPhoto(imageUrl);
      return result.dataOrNull;
    }

    // Local: save through the existing store.
    final record = await _localHistory.saveImage(imageUrl);
    return _adaptLocal(record, const []);
  }

  /// Activate a photo (make it the selected one).
  Future<void> activatePhoto(String photoId) async {
    if (isRemote) {
      await _remote!.activatePhoto(photoId);
    } else {
      await _localHistory.promoteToActive(photoId);
    }
  }

  /// Heartbeat — keeps the photo alive and marks it "in use".
  Future<void> touchPhoto(String photoId) async {
    if (isRemote) {
      await _remote!.touchPhoto(photoId);
    }
    // Local dock does not need a heartbeat — nothing else can delete it.
  }

  /// Delete a photo (and all its results).
  ///
  /// Returned rather than swallowed, like [deleteGarment]: a 409 means a
  /// colleague on another device is being fitted with this photograph, and
  /// deleting it takes their customer off their screen. The caller asks
  /// before retrying with [force].
  Future<Result<void>> deletePhoto(String photoId, {bool force = false}) async {
    // Local dock has no explicit delete — photos expire after 20 minutes.
    if (!isRemote) return const Success<void>(null);
    return _remote!.deletePhoto(photoId, force: force);
  }

  /// Heartbeat for a garment being viewed — "somebody has this open", so a
  /// colleague deleting it from another device is warned first.
  Future<void> touchGarment(String garmentId) async {
    if (isRemote) await _remote!.touchGarment(garmentId);
  }

  /// Removes an outfit from the "tried on" list by erasing the try-ons that
  /// put it there. The product itself is untouched.
  ///
  /// Returned rather than swallowed: a 409 means someone on another device
  /// is fitting this outfit right now, and the caller should confirm before
  /// retrying with [force]. Guests have no garment list, so this is a no-op
  /// for them.
  Future<Result<void>> deleteGarment(String garmentId, {bool force = false}) async {
    if (!isRemote) return const Success<void>(null);
    return _remote!.deleteGarment(garmentId, force: force);
  }

  /// Delete a single try-on result.
  ///
  /// For a merchant this has to reach the server: the dock is shared, so a
  /// result removed only on this phone stays on every other device the shop
  /// has open.
  Future<void> deleteResult(String resultId, {String? selfieId}) async {
    if (isRemote) {
      await _remote!.deleteResult(resultId);
    } else if (selfieId != null) {
      await _localResults.remove(selfieId, resultId);
    }
  }

  /// Clear the entire dock.
  Future<void> clearDock() async {
    if (isRemote) {
      await _remote!.clearDock();
    } else {
      await _localHistory.clearHistory();
    }
  }

  // ── Local history passthrough ──────────────────────────────────────
  // These are needed by the TryonNotifier for the local guest flow, which
  // manages selfie records and results directly. The facade exposes them
  // so the notifier doesn't need to hold separate references.

  /// The underlying local history store — for selfie operations in guest mode.
  HistoryLocalDataSource get localHistory => _localHistory;

  /// The underlying local results store — for result operations in guest mode.
  TryonResultsLocalDataSource get localResults => _localResults;

  // ── Private ────────────────────────────────────────────────────────

  /// Adapt a local [SelfieRecord] + results into the unified [DockPhoto].
  DockPhoto _adaptLocal(SelfieRecord record, List<TryonResult> results) {
    return DockPhoto(
      id: record.id,
      imageUrl: record.imageUrl,
      createdAt: record.lastUsedAt,
      lastUsedAt: record.lastUsedAt,
      isActive: record.isActive,
      results: results
          .map(
            (r) => DockTryonResult(
              id: r.generationId,
              resultImageUrl: r.resultImageUrl,
              garmentImageUrl: r.garmentImageUrl,
              dockPhotoId: record.id,
              createdAt: r.createdAt,
            ),
          )
          .toList(),
    );
  }
}
