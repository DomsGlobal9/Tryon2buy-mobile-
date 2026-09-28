import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tryon2buy/core/constants/api_endpoints.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';
import '../../data/datasources/dock_facade.dart';
import '../../data/datasources/dock_remote_data_source.dart';
import '../../data/datasources/history_local_data_source.dart';
import '../../data/datasources/tryon_remote_data_source.dart';
import '../../data/datasources/tryon_results_local_data_source.dart';
import '../../data/repositories/dock_repository_impl.dart';
import '../../data/repositories/tryon_repository_impl.dart';
import '../../domain/entities/dock_garment.dart';
import '../../domain/entities/dock_photo.dart';
import '../../domain/entities/selfie_record.dart';
import '../../domain/entities/tryon_result.dart';
import '../../domain/repositories/i_tryon_repository.dart';
import '../../domain/usecases/change_background.dart';
import '../../domain/usecases/generate_virtual_tryon.dart';
import '../../domain/usecases/modify_outfit_style.dart';
import 'tryon_state.dart';

// ─── Dependency Providers ──────────────────────────────────────────

final _remoteDataSourceProvider = Provider<TryonRemoteDataSource>((ref) {
  return TryonRemoteDataSource();
});

final _repositoryProvider = Provider<ITryonRepository>((ref) {
  return TryonRepositoryImpl(ref.read(_remoteDataSourceProvider));
});

final _generateTryonProvider = Provider<GenerateVirtualTryonUseCase>((ref) {
  return GenerateVirtualTryonUseCase(ref.read(_repositoryProvider));
});

final _changeBackgroundProvider = Provider<ChangeBackgroundUseCase>((ref) {
  return ChangeBackgroundUseCase(ref.read(_repositoryProvider));
});

final _modifyOutfitProvider = Provider<ModifyOutfitStyleUseCase>((ref) {
  return ModifyOutfitStyleUseCase(ref.read(_repositoryProvider));
});

final _historyDataSourceProvider = Provider<HistoryLocalDataSource>((ref) {
  return HistoryLocalDataSource();
});

final _resultsDataSourceProvider = Provider<TryonResultsLocalDataSource>((ref) {
  return TryonResultsLocalDataSource();
});

final _dockRemoteDataSourceProvider = Provider<DockRemoteDataSource>((ref) {
  return DockRemoteDataSource();
});

final _dockFacadeProvider = Provider<DockFacade>((ref) {
  // The remote repository is always created, but the facade only uses it
  // when AuthSession.instance.isVendorSignedIn is true at call time.
  final dockRepo = DockRepositoryImpl(ref.read(_dockRemoteDataSourceProvider));
  return DockFacade(
    remoteRepository: dockRepo,
    localHistory: ref.read(_historyDataSourceProvider),
    localResults: ref.read(_resultsDataSourceProvider),
  );
});

// ─── Main Notifier ─────────────────────────────────────────────────

/// The single source of truth for the fitting room.
///
/// Mirrors the website's `CustomerTryon.jsx`: load the source drape, pick a
/// photo, "See myself in this", then a carousel of results per selfie with
/// background and blouse retouching applied on demand.
///
/// Two rules every method follows:
///  * After an `await`, read the *live* [_session] rather than a copy taken
///    earlier. The shopper can pick a photo while the drape is still loading,
///    and that pick must not be overwritten by a stale snapshot.
///  * After an `await`, check [mounted] before assigning `state`. The
///    provider is autoDispose, so backing out mid-request disposes this
///    notifier while the request is still in flight.
class TryonNotifier extends StateNotifier<TryonStudioState> {
  final ITryonRepository _repository;
  final GenerateVirtualTryonUseCase _generateTryon;
  final ChangeBackgroundUseCase _changeBackground;
  final ModifyOutfitStyleUseCase _modifyOutfit;
  final DockFacade _dock;

  /// Convenience accessors for the underlying local stores. The DockFacade
  /// owns them, but the legacy paths in [generate] / [selectFromHistory]
  /// still write through these directly when the dock is in local mode.
  HistoryLocalDataSource get _historyStore => _dock.localHistory;
  TryonResultsLocalDataSource get _resultsStore => _dock.localResults;

  /// How often the room tells the server it is still open. Null disables the
  /// timer (tests, and anything that wants only the immediate beats).
  final Duration? _heartbeat;
  Timer? _beat;

  /// How often a shared dock asks what the other devices have been doing,
  /// matching the website. Nothing local ever reports a colleague adding a
  /// photo or clearing an outfit, so without this the dock is a snapshot
  /// taken when the room opened.
  static const Duration _dockPollInterval = Duration(seconds: 10);
  Timer? _poll;

  TryonNotifier({
    required ITryonRepository repository,
    required GenerateVirtualTryonUseCase generateTryon,
    required ChangeBackgroundUseCase changeBackground,
    required ModifyOutfitStyleUseCase modifyOutfit,
    required DockFacade dock,
    Duration? heartbeat = const Duration(seconds: 30),
  })  : _repository = repository,
        _generateTryon = generateTryon,
        _changeBackground = changeBackground,
        _modifyOutfit = modifyOutfit,
        _dock = dock,
        _heartbeat = heartbeat,
        super(const TryonInitial(StudioSession()));

  @override
  void dispose() {
    _beat?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  StudioSession get _session => state.session;

  /// Whether a request is in flight — the pipeline, or a background/outfit
  /// retouch. Browsing the dock stays allowed throughout; *applying* a
  /// different photo or garment does not, because the result would belong to
  /// a pair of inputs nobody ever chose together.
  bool get _isBusy => switch (state) {
        TryonGenerating() => true,
        TryonSuccess(:final isPostProcessing) => isPostProcessing,
        _ => false,
      };

  // ── Setup ──────────────────────────────────────────────────────────

  /// Opens the room for a merchant drape ([generationId]) or, failing that,
  /// a bare garment image. Also restores the most recent selfie and, if it
  /// has results, lands straight on them.
  Future<void> open({
    String? generationId,
    String? garmentUrl,
    String? category,
  }) async {
    final sourceId =
        (generationId != null && generationId.isNotEmpty) ? generationId : null;

    state = TryonInitial(
      StudioSession(
        fallbackGarmentUrl: garmentUrl ?? '',
        category: category,
        isRemoteDock: _dock.isRemote,
      ),
      loadingSource: sourceId != null,
    );

    // ── Load dock photos (unified: remote or local) ──────────────────
    final dockPhotos = await _dock.getPhotosWithResults();
    if (!mounted) return;

    // The shop's "tried on" list — the other half of the dock. Empty for
    // guests (the facade short-circuits), so the tab simply does not show.
    final dockGarments = await _dock.getGarments();
    if (!mounted) return;

    // Also load the legacy local history for the existing SelfieRecord UI.
    final history = await _historyStore.getValidHistory();
    if (!mounted) return;
    SelfieRecord? active;
    for (final r in history) {
      if (r.isActive) {
        active = r;
        break;
      }
    }

    // Merge into the live session: a photo picked during the read wins over
    // the restored one.
    var session = _session.copyWith(
      history: history,
      dockPhotos: dockPhotos,
      dockGarments: dockGarments,
      isRemoteDock: _dock.isRemote,
    );
    if (!session.hasSelfie && active != null) {
      session = session.copyWith(
        selectedUrl: active.imageUrl,
        activeHistoryId: active.id,
      );
    }
    state = TryonInitial(session, loadingSource: sourceId != null);

    if (sourceId != null) {
      final loaded = await _repository.fetchGeneration(sourceId);
      if (!mounted) return;
      switch (loaded) {
        case Success(:final data):
          state = TryonInitial(_session.copyWith(source: data));
        case Fail(:final failure):
          state = TryonInitial(_session, sourceError: failure.message);
          return;
      }
    }

    // Results this selfie already produced (any garment) come back as the
    // carousel, like the website's `carouselResults` — unless the shopper has
    // meanwhile picked a fresh photo, which starts a new session.
    if (active != null &&
        _session.selectedFile == null &&
        _session.activeHistoryId == active.id) {
      final results = await _resultsStore.resultsFor(active.id);
      if (!mounted) return;
      if (results.isNotEmpty &&
          _session.selectedFile == null &&
          state is! TryonSuccess) {
        state = TryonSuccess(_session, results: results);
        return;
      }
    }

    if (state is TryonInitial) state = TryonInitial(_session);

    if (_dock.isRemote) _startHeartbeat();
  }

  // ── Heartbeat ──────────────────────────────────────────────────────

  /// Tells the server this room is still open, for the photo in the slot and
  /// the garment on the canvas.
  ///
  /// It does two jobs at once, which is why nothing else can stand in for it.
  /// Beating a photo refreshes `lastUsedAt`, so a merchant who spends half an
  /// hour retouching does not have it expire underneath them — the 20-minute
  /// window is meant to run from last *use*, and without this it effectively
  /// runs from the last generation. It also sets `inUseAt`, which is the only
  /// thing that makes a colleague deleting it on another device get asked
  /// first instead of taking the customer off this screen without a word.
  ///
  /// Thirty seconds against the server's ninety-second `IN_USE_MS`, as on the
  /// website: a lost beat costs a warning, never the session.
  void _startHeartbeat() {
    _beat?.cancel();
    _poll?.cancel();
    _beatNow();
    final every = _heartbeat;
    if (every == null) return;
    _beat = Timer.periodic(every, (_) => _beatNow());
    _poll = Timer.periodic(_dockPollInterval, (_) => _pollDock());
  }

  void _pollDock() {
    // Never while a request is in flight. Refreshing underneath a generation
    // churns the state it is about to land on, for a list nobody is reading
    // at that moment anyway.
    if (_isBusy) return;
    refreshDock().ignore();
  }

  void _beatNow() {
    if (!_dock.isRemote) return;
    final session = _session;

    // Only an id the server's own list vouches for: `open()` restores
    // `activeHistoryId` from the on-device store even in remote mode, so it
    // can hold a local id the server has never seen.
    final photoId = session.activeHistoryId;
    if (photoId != null && session.dockPhotos.any((p) => p.id == photoId)) {
      _dock.touchPhoto(photoId).ignore();
    }

    // The try-on page is addressed by the garment's *asset* id; the server
    // takes either that or the product id, so no lookup is needed first.
    final garmentId = session.source?.generationId;
    if (garmentId != null && garmentId.isNotEmpty) {
      _dock.touchGarment(garmentId).ignore();
    }
  }

  // ── Photo selection ────────────────────────────────────────────────

  void selectFile(File file) {
    // Keep "loading" if the drape is still on its way, so "See myself in
    // this" stays disabled until there is something to try on.
    final current = state;
    state = TryonInitial(
      _session.copyWith(clearSelfie: true).copyWith(
        selectedFile: file,
        selectedUrl: file.path,
      ),
      loadingSource: current is TryonInitial && current.loadingSource,
    );
    _dockPickedFile(file);
  }

  Future<void> _dockPickedFile(File file) async {
    try {
      final saved = await _historyStore.saveImage(file.path, setActive: true);
      if (!mounted) return;
      final history = await _historyStore.getValidHistory();
      if (!mounted) return;
      final current = state;
      if (current is TryonInitial) {
        state = TryonInitial(
          current.session.copyWith(
            history: history,
            activeHistoryId: saved.id,
          ),
          loadingSource: current.loadingSource,
          sourceError: current.sourceError,
        );
      } else if (current is TryonSuccess) {
        state = TryonSuccess(
          current.session.copyWith(
            history: history,
            activeHistoryId: saved.id,
          ),
          results: current.results,
          isPostProcessing: current.isPostProcessing,
        );
      }
    } catch (_) {}
  }

  Future<void> selectFromHistory(SelfieRecord record) async {
    await _historyStore.promoteToActive(record.id);
    if (!mounted) return;
    final history = await _historyStore.getValidHistory();
    if (!mounted) return;
    final session = _session.copyWith(
      history: history,
      clearSelfie: true,
    ).copyWith(selectedUrl: record.imageUrl, activeHistoryId: record.id);

    final results = await _resultsStore.resultsFor(record.id);
    if (!mounted) return;
    state = results.isNotEmpty
        ? TryonSuccess(session, results: results)
        : TryonInitial(session);
  }

  Future<void> clearSelfie() async {
    final history = await _historyStore.getValidHistory();
    if (!mounted) return;
    state = TryonInitial(
      _session.copyWith(history: history, clearSelfie: true),
    );
  }

  // ── Generation ─────────────────────────────────────────────────────

  /// "See myself in this" and "Regenerate" are the same call.
  Future<void> generate() async {
    final session = _session;
    // A double tap must not start a second pipeline run (and spend a
    // second credit) while the first is in flight.
    if (!session.hasSelfie || state is TryonGenerating) return;

    state = TryonGenerating(session, statusMessage: 'Fitting in progress…');

    // ── Resolve the dock photo BEFORE generating ──────────────────────
    //
    // The server groups a try-on under a dock photograph only by the
    // `dock_photo_id` stamped into the result at generation time — it never
    // matches on vendorId or image URL (see dock.service.js `_resultsFor`).
    // So for a signed-in merchant the photo must already exist in the dock,
    // and its id must travel with the request, or the result is an orphan:
    // present in the database, invisible in the dock on every device, and
    // impossible to delete from it.
    //
    // A fresh file is therefore uploaded and docked here, ahead of the
    // pipeline, instead of after it. Guests keep the old order: their dock is
    // local and the server has nothing to link.
    var humanUrl = session.selectedUrl ?? '';
    var selfieFile = session.selectedFile;
    String? dockPhotoId;
    String? preDockedPhotoId;

    if (_dock.isRemote) {
      if (selfieFile != null) {
        final upload = await _repository.uploadSelfie(selfieFile);
        if (!mounted) return;
        switch (upload) {
          case Success(:final data):
            humanUrl = data;
            selfieFile = null; // already hosted; don't upload it twice
            try {
              final photo = await _dock.addPhoto(data);
              if (!mounted) return;
              preDockedPhotoId = photo?.id;
              dockPhotoId = photo?.id;
            } catch (_) {
              // Docking failed but the upload did not. Generate anyway; the
              // result simply won't be grouped, which is today's behaviour.
            }
          case Fail(:final failure):
            if (!mounted) return;
            state = TryonError(
              session,
              message: failure.message,
              code: _codeFor(failure),
            );
            return;
        }
      } else if (session.activeHistoryId != null &&
          session.dockPhotos.any((p) => p.id == session.activeHistoryId)) {
        // `activeHistoryId` can also hold a *local* history id (open()
        // restores it from the on-device store even in remote mode), so only
        // trust it when the server's own dock list vouches for it.
        dockPhotoId = session.activeHistoryId;
      }
    }

    final result = await _generateTryon(
      garmentUrl: session.garmentUrl,
      humanImageUrl: humanUrl,
      selfieFile: selfieFile,
      parentGenerationId: session.parentGenerationId,
      targetFolder: ApiEndpoints.targetTryonResults,
      dockPhotoId: dockPhotoId,
    );

    switch (result) {
      case Success<TryonResult>(:final data):
        final now = DateTime.now();
        final stamped = data.copyWith(
          createdAt: data.createdAt ?? now,
          lastUsedAt: now,
          category: data.category ?? session.source?.category ?? session.category,
        );

        // Persist even if the screen has gone: the credit is spent and the
        // result must be waiting in "My Looks" when the shopper comes back.
        //
        // A photo docked above must not be added a second time here, so it
        // takes the place of the active id up front.
        var selfieId = session.activeHistoryId ?? preDockedPhotoId;
        var history = session.history;
        var results = <TryonResult>[stamped];
        try {
          // First use of a fresh photo: the upload gave it a hosted URL, which
          // becomes its history entry so later try-ons reuse it.
          if (selfieId == null && data.humanImageUrl.isNotEmpty) {
            // Sync to dock (remote for vendor, local for guest).
            final dockPhoto = await _dock.addPhoto(data.humanImageUrl);
            if (dockPhoto != null) selfieId = dockPhoto.id;
            // Also save locally for the legacy SelfieRecord flow.
            if (!_dock.isRemote) {
              final saved = await _historyStore.saveImage(data.humanImageUrl);
              selfieId = saved.id;
            }
          } else if (selfieId != null) {
            // Using a photo extends its 20-minute window, as on the website.
            await _dock.activatePhoto(selfieId);
            if (!_dock.isRemote) {
              await _historyStore.promoteToActive(selfieId);
            }
          }
          history = await _historyStore.getValidHistory();
          if (selfieId != null) {
            final stored = await _resultsStore.add(selfieId, stamped);
            if (stored.isNotEmpty) results = stored;
          }
        } catch (_) {
          // Local persistence failed (disk full, corrupt prefs). The result
          // is still in hand: show it, just without history.
        }
        if (!mounted) return;

        // Refresh dock photos after generation.
        List<DockPhoto> dockPhotos = session.dockPhotos;
        try {
          dockPhotos = await _dock.getPhotosWithResults();
        } catch (_) {
          // Non-critical: the dock list updates on next open.
        }

        // From here on the photo is its hosted copy: drop the local file so
        // "Regenerate" reuses the upload instead of sending it again.
        final hosted = data.humanImageUrl.isNotEmpty
            ? data.humanImageUrl
            : session.selectedUrl;
        state = TryonSuccess(
          session.copyWith(
            history: history,
            dockPhotos: dockPhotos,
            clearSelfie: true,
          ).copyWith(
            selectedUrl: hosted,
            activeHistoryId: selfieId,
          ),
          results: results,
        );

        // A photo docked a moment ago is only alive, not claimed: `addPhoto`
        // and `activatePhoto` set `lastUsedAt`, never `inUseAt`.
        _beatNow();

      case Fail<TryonResult>(:final failure):
        if (!mounted) return;
        state = TryonError(
          session,
          message: failure.message,
          code: _codeFor(failure),
        );
    }
  }

  /// Back to the photo step, keeping the selfie so "Regenerate" works.
  void backToStart() => state = TryonInitial(_session);

  // ── Dock photo switching ───────────────────────────────────────────

  /// Switch to a different customer photo from the dock, keeping its
  /// existing try-on results. This is the key multi-try-on UX: the shopper
  /// picks a photo, tries multiple garments, and can always switch back
  /// to any photo and see all its results.
  Future<void> switchDockPhoto(DockPhoto photo) async {
    if (_isBusy) return;

    // Activate it in the dock (syncs to backend for vendor).
    await _dock.activatePhoto(photo.id);
    if (!mounted) return;

    // Also sync the legacy local history if in local mode.
    if (!_dock.isRemote) {
      await _historyStore.promoteToActive(photo.id);
    }
    if (!mounted) return;

    final history = await _historyStore.getValidHistory();
    if (!mounted) return;

    // Refresh dock photos to get the latest state.
    final dockPhotos = await _dock.getPhotosWithResults();
    if (!mounted) return;

    final session = _session.copyWith(
      history: history,
      dockPhotos: dockPhotos,
      clearSelfie: true,
    ).copyWith(
      selectedUrl: photo.imageUrl,
      activeHistoryId: photo.id,
    );

    // If this photo already has results, show them.
    final results = await _resultsStore.resultsFor(photo.id);
    if (!mounted) return;
    state = results.isNotEmpty
        ? TryonSuccess(session, results: results)
        : TryonInitial(session);

    // Claim the new photo at once rather than up to thirty seconds later:
    // the risky moment is the first minute, while a colleague can still see
    // it sitting unclaimed in their own dock.
    _beatNow();
  }

  /// Removes a photo from the dock, and every try-on made from it.
  ///
  /// Like [deleteGarment], the failure comes back rather than being shown:
  /// a 409 means a colleague on another device is being fitted with this
  /// photograph right now, and the screen turns that into a second question
  /// instead of a refusal.
  Future<Failure?> deletePhoto(DockPhoto photo, {bool force = false}) async {
    final result = await _dock.deletePhoto(photo.id, force: force);
    if (!mounted) return null;

    switch (result) {
      case Success():
        final wasInUseHere = _session.activeHistoryId == photo.id;
        await refreshDock();
        if (!mounted) return null;
        // Deleting the photo on the canvas takes it off this screen too;
        // leaving it there would offer a "Regenerate" that cannot work.
        if (wasInUseHere) {
          state = TryonInitial(_session.copyWith(clearSelfie: true));
        }
        return null;
      case Fail(:final failure):
        return failure;
    }
  }

  // ── Tried outfits ──────────────────────────────────────────────────

  /// "Try This" on a tried outfit: swap the garment, keep the photo.
  ///
  /// The opposite of [switchDockPhoto]. The dock's garment carries the asset
  /// id the try-on page is addressed by, so this is the same load `open()`
  /// does for a deep link — except the current selfie is preserved rather
  /// than re-derived, and the room lands on the photo step so the shopper
  /// sees the new garment on the canvas and generates deliberately.
  Future<void> switchGarment(DockGarment garment) async {
    if (_isBusy) return;

    state = TryonInitial(
      _session.copyWith(category: garment.category),
      loadingSource: true,
    );

    // "Somebody has this open." Best-effort; a lost beat only means a
    // colleague gets no warning before deleting it, which is not fatal here.
    _dock.touchGarment(garment.id).ignore();

    final loaded = await _repository.fetchGeneration(garment.primaryAssetId);
    if (!mounted) return;

    switch (loaded) {
      case Success(:final data):
        state = TryonInitial(_session.copyWith(source: data));
      case Fail(:final failure):
        state = TryonInitial(_session, sourceError: failure.message);
    }
  }

  /// Removes an outfit from the "tried on" list.
  ///
  /// Returns the failure instead of surfacing it, because one of them is a
  /// question rather than an error: a 409 means a colleague on another
  /// device is fitting this outfit right now. The screen asks, then calls
  /// again with [force].
  Future<Failure?> deleteGarment(DockGarment garment, {bool force = false}) async {
    final result = await _dock.deleteGarment(garment.id, force: force);
    if (!mounted) return null;

    switch (result) {
      case Success():
        await refreshDock();
        return null;
      case Fail(:final failure):
        return failure;
    }
  }

  /// Refresh dock photos from the backend (vendor) or local store (guest).
  Future<void> refreshDock() async {
    final dockPhotos = await _dock.getPhotosWithResults();
    if (!mounted) return;
    // Already empty for guests — the facade short-circuits — so this needs no
    // isRemote guard, and no cast back from a dynamic list.
    final dockGarments = await _dock.getGarments();
    if (!mounted) return;
    final current = state;
    final updatedSession = _session.copyWith(
      dockPhotos: dockPhotos,
      dockGarments: dockGarments,
    );
    state = switch (current) {
      TryonInitial(:final loadingSource, :final sourceError) =>
        TryonInitial(updatedSession, loadingSource: loadingSource, sourceError: sourceError),
      TryonSuccess() => current.copyWith(session: updatedSession),
      TryonGenerating(:final statusMessage) =>
        TryonGenerating(updatedSession, statusMessage: statusMessage),
      TryonError(:final message, :final code) =>
        TryonError(updatedSession, message: message, code: code),
    };
  }

  // ── Carousel ───────────────────────────────────────────────────────

  void showResult(int index) {
    final current = state;
    if (current is! TryonSuccess || !current.hasResults) return;
    state = current.copyWith(
      index: index.clamp(0, current.results.length - 1),
      clearPendingBackground: true,
    );
  }

  Future<void> deleteResult(TryonResult result) async {
    final current = state;
    if (current is! TryonSuccess) return;
    final selfieId = current.session.activeHistoryId;

    // A merchant's dock is shared, so this has to reach the server: a result
    // removed only here stays on every other device the shop has open, and
    // comes back on this one at the next refresh. The facade deletes
    // remotely for a merchant and locally for a guest.
    await _dock.deleteResult(result.generationId, selfieId: selfieId);
    if (!mounted) return;

    // The local copy is written for both kinds of session, so it is cleared
    // either way. Removing an id that has already gone is harmless.
    final remaining = selfieId != null
        ? await _resultsStore.remove(selfieId, result.generationId)
        : current.results.where((r) => r != result).toList();
    if (!mounted) return;

    if (remaining.isEmpty) {
      state = TryonInitial(current.session);
      return;
    }
    state = current.copyWith(
      results: remaining,
      index: current.index.clamp(0, remaining.length - 1),
    );
  }

  // ── Retouching ─────────────────────────────────────────────────────

  void selectBackground(String backgroundId) {
    final current = state;
    if (current is! TryonSuccess || current.isPostProcessing) return;
    state = current.copyWith(pendingBackgroundId: backgroundId);
  }

  void setOutfitTab(OutfitTab tab) {
    final current = state;
    if (current is! TryonSuccess || current.isPostProcessing) return;
    state = current.copyWith(outfitTab: tab);
  }

  void selectModification(String modificationId) {
    final current = state;
    if (current is! TryonSuccess || current.isPostProcessing) return;
    state = current.outfitTab == OutfitTab.sleeve
        ? current.copyWith(pendingSleeveId: modificationId)
        : current.copyWith(pendingNeckId: modificationId);
  }

  Future<void> applyBackground() async {
    final current = state;
    if (current is! TryonSuccess || !current.hasResults) return;
    final bgId = current.pendingBackgroundId;
    if (bgId == null || current.isPostProcessing) return;

    state = current.copyWith(
      isPostProcessing: true,
      postProcessMessage: 'Applying background…',
      clearPostMessage: false,
    );

    final result = await _changeBackground(
      currentImageUrl: current.current.resultImageUrl,
      backgroundId: bgId,
      // The parent drape, as the website sends it.
      generationId: current.session.parentGenerationId,
    );

    await _finishPostProcess(current, result, clearBackground: true);
  }

  Future<void> applyModification() async {
    final current = state;
    if (current is! TryonSuccess ||
        !current.hasResults ||
        current.isPostProcessing) {
      return;
    }

    state = current.copyWith(
      isPostProcessing: true,
      postProcessMessage: 'Applying…',
    );

    final result = await _modifyOutfit(
      currentImageUrl: current.current.resultImageUrl,
      modificationType: current.pendingModificationId,
      generationId: current.session.parentGenerationId,
    );

    await _finishPostProcess(current, result);
  }

  Future<void> _finishPostProcess(
    TryonSuccess before,
    Result<String> result, {
    bool clearBackground = false,
  }) async {
    switch (result) {
      case Success<String>(:final data):
        final edited = before.current.copyWith(
          resultImageUrl: data,
          lastUsedAt: DateTime.now(),
        );
        // The on-screen list, edited in place. This stays the answer if the
        // store has meanwhile expired the entry (20-minute window): a visible
        // carousel is never replaced with an empty one.
        var results = before.results
            .map((r) => r == before.current ? edited : r)
            .toList();
        final selfieId = before.session.activeHistoryId;
        if (selfieId != null) {
          try {
            final stored = await _resultsStore.replaceImage(
                selfieId, before.current.generationId, data);
            if (stored.any((r) => r.generationId == before.current.generationId)) {
              results = stored;
            }
          } catch (_) {
            // Keep the in-memory edit.
          }
        }
        if (!mounted) return;
        state = before.copyWith(
          results: results,
          isPostProcessing: false,
          clearPendingBackground: clearBackground,
          clearPostMessage: true,
        );

      case Fail<String>(:final failure):
        if (!mounted) return;
        state = before.copyWith(
          isPostProcessing: false,
          postProcessMessage: failure.message,
          postProcessCode: _codeFor(failure),
        );
    }
  }

  /// Clears a shown post-process error so it does not re-fire on rebuild.
  void acknowledgePostProcessError() {
    final current = state;
    if (current is! TryonSuccess) return;
    state = current.copyWith(clearPostMessage: true);
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  static String? _codeFor(Failure failure) => switch (failure) {
        GuestLimitReachedFailure() => TryonErrorCode.guestLimit,
        InsufficientCreditsFailure() => TryonErrorCode.insufficientCredits,
        AuthTokenExpiredFailure() => TryonErrorCode.authExpired,
        _ => null,
      };
}

// ─── Riverpod Provider ─────────────────────────────────────────────

final tryonNotifierProvider =
    StateNotifierProvider.autoDispose<TryonNotifier, TryonStudioState>((ref) {
  return TryonNotifier(
    repository: ref.read(_repositoryProvider),
    generateTryon: ref.read(_generateTryonProvider),
    changeBackground: ref.read(_changeBackgroundProvider),
    modifyOutfit: ref.read(_modifyOutfitProvider),
    dock: ref.read(_dockFacadeProvider),
  );
});
