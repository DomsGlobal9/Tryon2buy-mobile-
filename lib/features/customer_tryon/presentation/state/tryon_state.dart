import 'dart:io';
import 'package:equatable/equatable.dart';

import '../../domain/entities/dock_garment.dart';
import '../../domain/entities/dock_photo.dart';
import '../../domain/entities/selfie_record.dart';
import '../../domain/entities/tryon_result.dart';

/// Everything the fitting room remembers across states: the garment being
/// tried on, the shopper's photo, and the recent-selfie history.
final class StudioSession extends Equatable {
  /// The merchant drape the shopper is trying on — the website's
  /// `sourceGeneration` from `GET /api/tryon/generations/:id`. Null until
  /// loaded, or when the caller only had a bare garment image.
  final TryonResult? source;

  /// The garment image to drape when [source] is absent.
  final String fallbackGarmentUrl;

  final String? category;

  final List<SelfieRecord> history;
  final File? selectedFile;
  final String? selectedUrl;
  final String? activeHistoryId;

  /// The unified dock photos (with nested try-on results), populated by
  /// [DockFacade.getPhotosWithResults]. Works for both vendor and guest.
  final List<DockPhoto> dockPhotos;

  /// Garments customers have tried on (vendor-only; empty for guests).
  final List<DockGarment> dockGarments;

  /// Whether the dock is backed by the server (vendor) or local storage.
  final bool isRemoteDock;

  const StudioSession({
    this.source,
    this.fallbackGarmentUrl = '',
    this.category,
    this.history = const [],
    this.selectedFile,
    this.selectedUrl,
    this.activeHistoryId,
    this.dockPhotos = const [],
    this.dockGarments = const [],
    this.isRemoteDock = false,
  });

  /// What the shopper is trying on: the drape if one exists, else the raw
  /// garment photo. Mirrors `sourceGeneration.resultImageUrl || garmentImageUrl`.
  String get garmentUrl {
    final s = source;
    if (s != null) {
      if (s.resultImageUrl.isNotEmpty) return s.resultImageUrl;
      if (s.garmentImageUrl.isNotEmpty) return s.garmentImageUrl;
    }
    return fallbackGarmentUrl;
  }

  /// The parent generation, when trying on a real drape.
  String? get parentGenerationId {
    final id = source?.generationId;
    return (id == null || id.isEmpty) ? null : id;
  }

  /// SAREE (or unknown) unlocks the sleeve and neckline retoucher; other
  /// categories only get backgrounds — same rule as the website.
  bool get allowsOutfitEdits {
    final c = (source?.category ?? category)?.trim().toUpperCase();
    return c == null || c.isEmpty || c == 'SAREE';
  }

  bool get hasSelfie =>
      selectedFile != null || (selectedUrl != null && selectedUrl!.isNotEmpty);

  StudioSession copyWith({
    TryonResult? source,
    String? fallbackGarmentUrl,
    String? category,
    List<SelfieRecord>? history,
    File? selectedFile,
    String? selectedUrl,
    String? activeHistoryId,
    List<DockPhoto>? dockPhotos,
    List<DockGarment>? dockGarments,
    bool? isRemoteDock,
    bool clearSelfie = false,
  }) {
    return StudioSession(
      source: source ?? this.source,
      fallbackGarmentUrl: fallbackGarmentUrl ?? this.fallbackGarmentUrl,
      category: category ?? this.category,
      history: history ?? this.history,
      selectedFile: clearSelfie ? null : (selectedFile ?? this.selectedFile),
      selectedUrl: clearSelfie ? null : (selectedUrl ?? this.selectedUrl),
      activeHistoryId:
          clearSelfie ? null : (activeHistoryId ?? this.activeHistoryId),
      dockPhotos: dockPhotos ?? this.dockPhotos,
      dockGarments: dockGarments ?? this.dockGarments,
      isRemoteDock: isRemoteDock ?? this.isRemoteDock,
    );
  }

  @override
  List<Object?> get props => [
        source,
        fallbackGarmentUrl,
        category,
        history,
        selectedFile,
        selectedUrl,
        activeHistoryId,
        dockPhotos,
        dockGarments,
        isRemoteDock,
      ];
}

/// Sealed state hierarchy for the fitting room. The UI renders exhaustively
/// by switching on these types.
sealed class TryonStudioState extends Equatable {
  final StudioSession session;
  const TryonStudioState(this.session);
}

/// Waiting for a photo (and, briefly, for the source garment to load).
final class TryonInitial extends TryonStudioState {
  final bool loadingSource;
  final String? sourceError;

  const TryonInitial(
    super.session, {
    this.loadingSource = false,
    this.sourceError,
  });

  @override
  List<Object?> get props => [session, loadingSource, sourceError];
}

/// AI pipeline is running: uploading selfie, running the model, compositing.
final class TryonGenerating extends TryonStudioState {
  final String statusMessage;

  const TryonGenerating(super.session, {required this.statusMessage});

  @override
  List<Object?> get props => [session, statusMessage];
}

/// Which retoucher tab is open on a saree result.
enum OutfitTab { sleeve, neck }

/// A result is on screen. [results] is the carousel for the current selfie,
/// newest first; [index] is the slide being shown.
final class TryonSuccess extends TryonStudioState {
  final List<TryonResult> results;
  final int index;

  /// Chosen but not yet applied. The website selects, then "Apply".
  final String? pendingBackgroundId;
  final String pendingSleeveId;
  final String pendingNeckId;
  final OutfitTab outfitTab;

  final bool isPostProcessing;
  final String? postProcessMessage;

  /// Set when the last post-process failed with a credit gate.
  final String? postProcessCode;

  const TryonSuccess(
    super.session, {
    required this.results,
    this.index = 0,
    this.pendingBackgroundId,
    this.pendingSleeveId = 'elbow-sleeve',
    this.pendingNeckId = 'round-neck',
    this.outfitTab = OutfitTab.sleeve,
    this.isPostProcessing = false,
    this.postProcessMessage,
    this.postProcessCode,
  });

  /// Whether there is anything to show. A carousel can come back empty when
  /// the 20-minute local cache expired underneath a retouch; the screen
  /// checks this before reading [current].
  bool get hasResults => results.isNotEmpty;

  TryonResult get current {
    assert(results.isNotEmpty, 'TryonSuccess.current read with an empty carousel');
    return results[index.clamp(0, results.length - 1)];
  }

  /// The modification the "Apply changes" button would send.
  String get pendingModificationId =>
      outfitTab == OutfitTab.sleeve ? pendingSleeveId : pendingNeckId;

  TryonSuccess copyWith({
    StudioSession? session,
    List<TryonResult>? results,
    int? index,
    String? pendingBackgroundId,
    bool clearPendingBackground = false,
    String? pendingSleeveId,
    String? pendingNeckId,
    OutfitTab? outfitTab,
    bool? isPostProcessing,
    String? postProcessMessage,
    String? postProcessCode,
    bool clearPostMessage = false,
  }) {
    return TryonSuccess(
      session ?? this.session,
      results: results ?? this.results,
      index: index ?? this.index,
      pendingBackgroundId: clearPendingBackground
          ? null
          : (pendingBackgroundId ?? this.pendingBackgroundId),
      pendingSleeveId: pendingSleeveId ?? this.pendingSleeveId,
      pendingNeckId: pendingNeckId ?? this.pendingNeckId,
      outfitTab: outfitTab ?? this.outfitTab,
      isPostProcessing: isPostProcessing ?? this.isPostProcessing,
      postProcessMessage:
          clearPostMessage ? null : (postProcessMessage ?? this.postProcessMessage),
      postProcessCode:
          clearPostMessage ? null : (postProcessCode ?? this.postProcessCode),
    );
  }

  @override
  List<Object?> get props => [
        session,
        results,
        index,
        pendingBackgroundId,
        pendingSleeveId,
        pendingNeckId,
        outfitTab,
        isPostProcessing,
        postProcessMessage,
        postProcessCode,
      ];
}

/// Generation failed. [code] carries the website's credit gates so the UI
/// can show the matching modal instead of a bare snackbar.
final class TryonError extends TryonStudioState {
  final String message;
  final String? code;

  const TryonError(super.session, {required this.message, this.code});

  @override
  List<Object?> get props => [session, message, code];
}

/// Failure codes the UI reacts to with a dialog.
class TryonErrorCode {
  const TryonErrorCode._();
  static const guestLimit = 'GUEST_LIMIT_REACHED';
  static const insufficientCredits = 'INSUFFICIENT_CREDITS';
  static const authExpired = 'AUTH_EXPIRED';
}
