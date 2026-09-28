import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

import 'package:tryon2buy/core/animations/app_motion.dart';
import 'package:tryon2buy/core/constants/api_endpoints.dart';
import 'package:tryon2buy/core/constants/preset_data.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/theme/app_colors.dart';
import 'package:tryon2buy/core/theme/app_typography.dart';
import 'package:tryon2buy/core/utils/image_picker_helper.dart';
import 'package:tryon2buy/core/utils/ui_helpers.dart';
import 'package:tryon2buy/core/widgets/credit_dialogs.dart';
import 'package:tryon2buy/core/widgets/empty_state_view.dart';
import 'package:tryon2buy/core/widgets/image_history_dock.dart';
import 'package:tryon2buy/core/widgets/remote_image.dart';
import 'package:tryon2buy/routes/app_router.dart';
import '../../domain/entities/dock_garment.dart';
import '../../domain/entities/dock_photo.dart';
import '../../domain/entities/tryon_result.dart';
import '../state/tryon_notifier.dart';
import '../state/tryon_state.dart';
import '../widgets/selfie_capture_widget.dart';

/// The shopper's fitting room — the website's `/tryon/:id` page.
///
/// Open it with a [generationId] (a merchant drape) and the shopper tries
/// that look on: upload a photo, "See myself in this", then retouch the
/// background or, for sarees, the blouse sleeves and neckline. Results for
/// the current selfie collect in a carousel, as on the web.
class CustomerTryonStudioScreen extends ConsumerStatefulWidget {
  /// Bare garment image, for callers that have no generation to anchor to.
  final String? garmentImageUrl;
  final String? garmentTitle;

  /// SAREE, LEHANGA, … Used only to decide whether the retoucher shows.
  final String? category;

  /// The drape to try on. This is the normal way in.
  final String? generationId;

  const CustomerTryonStudioScreen({
    super.key,
    this.garmentImageUrl,
    this.garmentTitle,
    this.category,
    this.generationId,
  });

  @override
  ConsumerState<CustomerTryonStudioScreen> createState() =>
      _CustomerTryonStudioScreenState();
}

class _CustomerTryonStudioScreenState
    extends ConsumerState<CustomerTryonStudioScreen> {
  static const _framingExampleUrl =
      'https://res.cloudinary.com/doiezptnn/image/upload/v1782733465/79061311-f8ef-4542-88ea-4783015af68d_z2bhdi.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tryonNotifierProvider.notifier).open(
            generationId: widget.generationId,
            garmentUrl: widget.garmentImageUrl,
            category: widget.category,
          );
    });
  }

  // ── Credit gates ──────────────────────────────────────────────────

  Future<void> _handleCode(String? code, String message) async {
    if (!mounted) return;
    switch (code) {
      // A guest has spent the free tier: the website's offer of an account.
      case TryonErrorCode.guestLimit:
        final signIn = await showLimitReachedDialog(context, vendor: false);
        if (signIn && mounted) await _openSignIn();

      // A business token was rejected or had expired. This is not a quota,
      // so say so rather than showing the free-trial pitch to someone who
      // already has an account. `ApiClient` has already signed them out.
      case TryonErrorCode.authExpired:
        final signIn = await UiHelpers.confirm(
          context,
          title: 'Session expired',
          message: 'Your sign-in has expired. Sign in again to continue.',
          confirmLabel: 'Sign in',
        );
        if (signIn && mounted) await _openSignIn();

      case TryonErrorCode.insufficientCredits:
        // A shopper is not the account holder and cannot subscribe to
        // anything: they are told to ask the boutique. Only a signed-in
        // merchant sees the plan pitch, which is how the website decides it.
        await showUpgradeDialog(
          context,
          customer: !AuthSession.instance.isVendorSignedIn,
        );
      default:
        UiHelpers.showSnackBar(context, message, isError: true);
    }
  }

  /// Opens the business portal and re-reads the session on the way back, so
  /// the studio and every other screen agree on who is signed in.
  Future<void> _openSignIn() async {
    // `returnToCaller`: come back to this fitting, photo and drape intact,
    // rather than being carried off into the merchant studio.
    await AppRouter.openSignIn(context, returnToCaller: true);
    await AuthSession.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tryonNotifierProvider);
    final notifier = ref.read(tryonNotifierProvider.notifier);

    ref.listen<TryonStudioState>(tryonNotifierProvider, (prev, next) {
      if (next is TryonError) {
        _handleCode(next.code, next.message);
      } else if (next is TryonSuccess &&
          prev is TryonSuccess &&
          !next.isPostProcessing &&
          next.postProcessMessage != null &&
          prev.postProcessMessage != next.postProcessMessage) {
        _handleCode(next.postProcessCode, next.postProcessMessage!);
        notifier.acknowledgePostProcessError();
      }
    });

    final session = state.session;
    final totalDockItems = (session.dockPhotos.isNotEmpty
            ? session.dockPhotos.length
            : session.history.length) +
        session.dockGarments.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(
          widget.garmentTitle?.toUpperCase() ?? 'PERSONAL FITTING',
          style: AppTypography.display(size: 20),
        ),
      ),
      body: switch (state) {
        TryonInitial() => _InitialBody(state: state, notifier: notifier),
        TryonGenerating() => _GeneratingBody(state: state),
        // A carousel can come back empty when the 20-minute local cache
        // expired underneath a retouch: show the photo step, never index it.
        TryonSuccess() when !state.hasResults => _InitialBody(
            state: TryonInitial(state.session),
            notifier: notifier,
          ),
        TryonSuccess() => _SuccessBody(state: state, notifier: notifier),
        TryonError() => _InitialBody(
            state: TryonInitial(state.session),
            notifier: notifier,
          ),
      },
      floatingActionButton: totalDockItems > 0
          ? FloatingActionButton.extended(
              heroTag: 'dock_floating_btn',
              onPressed: () => _openDockSheet(
                context,
                session,
                notifier,
                state is TryonGenerating ||
                    (state is TryonSuccess && state.isPostProcessing),
              ),
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: AppColors.border),
              ),
              icon: Badge(
                label: Text('$totalDockItems'),
                backgroundColor: const Color(0xFFDD6B20),
                textColor: Colors.white,
                child: const Icon(Icons.access_time,
                    color: Color(0xFFDD6B20), size: 20),
              ),
              label: Text(
                'Photo Dock',
                style: AppTypography.monoLabel(
                  size: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : null,
    );
  }

  void _openDockSheet(
    BuildContext context,
    StudioSession session,
    TryonNotifier notifier,
    bool busy,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding:
              const EdgeInsets.only(top: 14, bottom: 20, left: 16, right: 16),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    session.isRemoteDock
                        ? 'PHOTOS & TRIED LOOKS'
                        : 'RECENT SELFIES (20m DOCK)',
                    style: AppTypography.monoLabel(
                        size: 13, color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: const Icon(Icons.close,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Photos automatically expire 20 minutes after their last use.',
                style: AppTypography.mono(
                    size: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ImageHistoryDock(
                history: session.history,
                dockPhotos: session.dockPhotos,
                garments: session.dockGarments,
                activeImageId: session.activeHistoryId,
                activeGarmentAssetId: session.source?.generationId,
                isRemoteDock: session.isRemoteDock,
                busy: busy,
                onSelectImage: (record) {
                  Navigator.pop(sheetContext);
                  notifier.selectFromHistory(record);
                },
                onSelectDockPhoto: (photo) {
                  Navigator.pop(sheetContext);
                  notifier.switchDockPhoto(photo);
                },
                onDeleteDockPhoto: session.isRemoteDock
                    ? (photo) => _DockSection.removePhoto(context, notifier, photo)
                    : null,
                onSelectGarment: (garment) {
                  Navigator.pop(sheetContext);
                  notifier.switchGarment(garment);
                },
                onDeleteGarment: (garment) =>
                    _DockSection.removeGarment(context, notifier, garment),
                onAddImage: () async {
                  Navigator.pop(sheetContext);
                  final file = await ImagePickerHelper.pickFromGallery();
                  if (file != null) notifier.selectFile(file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Canvas
// ═══════════════════════════════════════════════════════════════════════

/// The 3:4 stage the website centres on: garment first, then the result.
class _Canvas extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final Widget? overlay;
  final bool dimmed;

  const _Canvas({
    required this.imageUrl,
    this.caption,
    this.overlay,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border.all(color: AppColors.creamBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedOpacity(
              duration: AppMotion.base,
              opacity: dimmed ? 0.4 : 1,
              child: RemoteImage(url: imageUrl, fallbackIcon: Icons.checkroom),
            ),
            if (caption != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Text(
                      caption!.toUpperCase(),
                      style: AppTypography.monoLabel(
                          size: 11.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Initial — pick a photo
// ═══════════════════════════════════════════════════════════════════════

class _InitialBody extends StatelessWidget {
  final TryonInitial state;
  final TryonNotifier notifier;

  const _InitialBody({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final session = state.session;

    if (state.sourceError != null) {
      return EmptyStateView.error(
        title: 'Dress not found or link expired',
        message: state.sourceError!,
        onAction: () => Navigator.maybePop(context),
        actionLabel: 'Go back',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (state.loadingSource)
          const AspectRatio(
            aspectRatio: 3 / 4,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _Canvas(
            imageUrl: session.garmentUrl,
            caption: 'The garment you will try on',
          ),
        const SizedBox(height: 20),

        // ── Upload Your Photo ──────────────────────────────────────
        Text(
          'Upload Your Photo',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(fontSize: 19),
        ),
        const SizedBox(height: 4),
        Text(
          'For the best try-on experience, please follow the guidelines below.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(fontSize: 13.5),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFED8936))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Framing example',
                style: AppTypography.titleMedium.copyWith(fontSize: 13),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFED8936))),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: const RemoteImage(
              url: _CustomerTryonStudioScreenState._framingExampleUrl,
              fallbackIcon: Icons.person_outline,
            ),
          ),
        ),
        const SizedBox(height: 12),

        _NoteBox(
          icon: Icons.lightbulb_outline_rounded,
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium.copyWith(fontSize: 13),
              children: [
                TextSpan(
                  text: 'Note: ',
                  style: AppTypography.titleMedium.copyWith(fontSize: 13),
                ),
                const TextSpan(
                  text: 'For the best fit visualization, please upload a clear, '
                      'front-facing full-body photo. Ensure your posture and hand '
                      'placement closely match the product model.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        SelfieCaptureWidget(
          selectedFile: session.selectedFile,
          previewUrl: session.selectedUrl,
          onFileSelected: notifier.selectFile,
          onRemove: session.hasSelfie ? notifier.clearSelfie : null,
        ),
        const SizedBox(height: 12),

        // No dock here. Choosing a photo is what the capture widget above is
        // for; the dock itself lives behind the floating "Photo Dock" button,
        // which is the only place it should appear.
        _PrivacyNotes(),
        const SizedBox(height: 18),

        _PillButton(
          label: 'See myself in this',
          enabled: session.hasSelfie && !state.loadingSource,
          onPressed: notifier.generate,
        ),
      ],
    );
  }
}

class _GeneratingBody extends StatelessWidget {
  final TryonGenerating state;
  const _GeneratingBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _Canvas(
          imageUrl: state.session.garmentUrl,
          dimmed: true,
          overlay: const _BusyOverlay(),
        ),
        const SizedBox(height: 18),
        _PillButton(
          label: 'Fitting in progress…',
          enabled: false,
          onPressed: () {},
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Success — result carousel + retouching
// ═══════════════════════════════════════════════════════════════════════

class _SuccessBody extends StatelessWidget {
  final TryonSuccess state;
  final TryonNotifier notifier;

  const _SuccessBody({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final busy = state.isPostProcessing;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Try On This Look', style: AppTypography.display(size: 24)),
        const SizedBox(height: 12),

        _Canvas(
          imageUrl: state.current.resultImageUrl,
          dimmed: busy,
          overlay: Stack(
            children: [
              if (busy) const _BusyOverlay(),
              if (state.results.length > 1) ...[
                if (state.index > 0)
                  _ArrowButton(
                    alignment: Alignment.centerLeft,
                    icon: Icons.chevron_left_rounded,
                    onTap: () => notifier.showResult(state.index - 1),
                  ),
                if (state.index < state.results.length - 1)
                  _ArrowButton(
                    alignment: Alignment.centerRight,
                    icon: Icons.chevron_right_rounded,
                    onTap: () => notifier.showResult(state.index + 1),
                  ),
              ],
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: _Filmstrip(
                  results: state.results,
                  index: state.index,
                  onSelect: notifier.showResult,
                  onDelete: notifier.deleteResult,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (state.current.generationId.isNotEmpty)
          _ShareRow(generationId: state.current.generationId),
        const SizedBox(height: 18),

        // ── Your photo ─────────────────────────────────────────────
        SelfieCaptureWidget(
          selectedFile: session.selectedFile,
          previewUrl: session.selectedUrl,
          compact: true,
          onFileSelected: notifier.selectFile,
          onRemove: notifier.clearSelfie,
        ),
        const SizedBox(height: 12),

        // The dock lives here too: "Try This" on a tried outfit is most
        // useful while looking at a result, not only before the first one.
        // As on the photo step: the dock is the floating button's, not the
        // page's. Two copies of it on one screen was the bug.

        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: busy ? null : notifier.generate,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('REGENERATE', style: AppTypography.cta(color: AppColors.ink)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.ink.withValues(alpha: 0.3)),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ),

        if (session.allowsOutfitEdits) ...[
          const SizedBox(height: 24),
          const Divider(color: AppColors.creamBorder),
          const SizedBox(height: 16),
          _OutfitRetoucher(state: state, notifier: notifier),
        ],

        const SizedBox(height: 24),
        const Divider(color: AppColors.creamBorder),
        const SizedBox(height: 16),
        _BackgroundPanel(state: state, notifier: notifier),
      ],
    );
  }
}

class _OutfitRetoucher extends StatelessWidget {
  final TryonSuccess state;
  final TryonNotifier notifier;

  const _OutfitRetoucher({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final busy = state.isPostProcessing;
    final sleeve = state.outfitTab == OutfitTab.sleeve;
    final options = sleeve ? PresetData.blouseSleeves : PresetData.necklines;
    final selected = sleeve ? state.pendingSleeveId : state.pendingNeckId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _SegmentTab(
                label: 'Sleeve style',
                selected: sleeve,
                onTap: busy ? null : () => notifier.setOutfitTab(OutfitTab.sleeve),
              ),
              _SegmentTab(
                label: 'Neck style',
                selected: !sleeve,
                onTap: busy ? null : () => notifier.setOutfitTab(OutfitTab.neck),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _OptionTile(
                  imageUrl: options[i].imageUrl,
                  label: options[i].name,
                  selected: options[i].id == selected,
                  enabled: !busy,
                  aspectRatio: 1,
                  onTap: () => notifier.selectModification(options[i].id),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _InkButton(
          label: busy ? 'Applying…' : 'Apply changes',
          icon: Icons.auto_awesome,
          enabled: !busy,
          onPressed: notifier.applyModification,
        ),
      ],
    );
  }
}

class _BackgroundPanel extends StatelessWidget {
  final TryonSuccess state;
  final TryonNotifier notifier;

  const _BackgroundPanel({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final busy = state.isPostProcessing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Change Background', style: AppTypography.display(size: 22)),
        const SizedBox(height: 4),
        Text(
          'Select a background and apply it to your try-on.',
          style: AppTypography.mono(size: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 4 / 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: PresetData.backgrounds.length,
          itemBuilder: (context, i) {
            final bg = PresetData.backgrounds[i];
            return _OptionTile(
              imageUrl: bg.imageUrl,
              label: bg.name,
              selected: state.pendingBackgroundId == bg.id,
              enabled: !busy,
              onTap: () => notifier.selectBackground(bg.id),
            );
          },
        ),
        const SizedBox(height: 16),
        _InkButton(
          label: busy ? 'Applying…' : 'Apply background',
          enabled: !busy && state.pendingBackgroundId != null,
          onPressed: notifier.applyBackground,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Dock
// ═══════════════════════════════════════════════════════════════════════

/// The two destructive dock flows, shared by whatever is showing the dock.
///
/// Not a widget any more. The dock used to be rendered inline in the page
/// *and* inside the floating button's sheet, which put two of them on screen
/// at once; the sheet is now the only one, and this is what is left.
abstract final class _DockSection {
  /// Confirm, delete; and if a colleague is being fitted with this photo on
  /// another device (409), say what that costs them before going ahead.
  static Future<void> removePhoto(
    BuildContext context,
    TryonNotifier notifier,
    DockPhoto photo,
  ) async {
    final count = photo.resultCount;
    final ok = await UiHelpers.confirm(
      context,
      title: 'Remove this photo?',
      message: count == 0
          ? 'It comes off the dock on every device signed in to this shop.'
          : 'The $count try-${count == 1 ? 'on' : 'ons'} made from it go too, '
              'on every device signed in to this shop.',
      confirmLabel: 'Remove',
      cancelLabel: 'Keep it',
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    var failure = await notifier.deletePhoto(photo);

    if (failure is ServerFailure && failure.statusCode == 409) {
      if (!context.mounted) return;
      final anyway = await UiHelpers.confirm(
        context,
        title: 'Someone is being fitted with this photo',
        message: 'They are on another device, and removing it takes the photo '
            'off their screen along with the try-ons made from it.',
        confirmLabel: 'Remove anyway',
        cancelLabel: 'Leave it',
        destructive: true,
      );
      if (!anyway || !context.mounted) return;
      failure = await notifier.deletePhoto(photo, force: true);
    }

    if (failure != null && context.mounted) {
      UiHelpers.showSnackBar(context, failure.message, isError: true);
    }
  }

  /// Confirm, delete; and if a colleague on another device is fitting this
  /// outfit right now (409), say so and offer to remove it anyway.
  static Future<void> removeGarment(
    BuildContext context,
    TryonNotifier notifier,
    DockGarment garment,
  ) async {
    final name = garment.title.isEmpty ? 'this outfit' : garment.title;
    final ok = await UiHelpers.confirm(
      context,
      title: 'Remove $name?',
      message: 'Its recent try-ons come off the list. The product itself '
          'stays in your catalogue and can be tried on again.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    var failure = await notifier.deleteGarment(garment);

    if (failure is ServerFailure && failure.statusCode == 409) {
      if (!context.mounted) return;
      final anyway = await UiHelpers.confirm(
        context,
        title: 'Someone is trying this on',
        message: '${failure.message} Remove it anyway?',
        confirmLabel: 'Remove anyway',
        destructive: true,
      );
      if (!anyway || !context.mounted) return;
      failure = await notifier.deleteGarment(garment, force: true);
    }

    if (failure != null && context.mounted) {
      UiHelpers.showSnackBar(context, failure.message, isError: true);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Small pieces
// ═══════════════════════════════════════════════════════════════════════

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Lottie.asset(
        'assets/animations/tryon_fitting.json',
        width: 220,
        height: 220,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandOrange),
            ),
          );
        },
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnails of every result for this selfie, with a delete per thumb.
class _Filmstrip extends StatelessWidget {
  final List<TryonResult> results;
  final int index;
  final ValueChanged<int> onSelect;
  final ValueChanged<TryonResult> onDelete;

  const _Filmstrip({
    required this.results,
    required this.index,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < results.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => onSelect(i),
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          width: 40,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: i == index
                                  ? const Color(0xFFDD6B20)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: i == index ? 1.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Opacity(
                            opacity: i == index ? 1 : 0.5,
                            child: RemoteImage(
                              url: results[i].garmentImageUrl.isNotEmpty
                                  ? results[i].garmentImageUrl
                                  : results[i].resultImageUrl,
                              fallbackIcon: Icons.checkroom,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onDelete(results[i]),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xE6EF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.monoLabel(
              size: 12.5,
              color: selected ? AppColors.ink : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Image tile with a bottom-anchored label, used for blouse styles and
/// backgrounds. Selection is a gold ring.
class _OptionTile extends StatelessWidget {
  final String imageUrl;
  final String label;
  final bool selected;
  final bool enabled;
  final double? aspectRatio;
  final VoidCallback onTap;

  const _OptionTile({
    required this.imageUrl,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFFC4933F)
                  : AppColors.ink.withValues(alpha: 0.15),
              width: selected ? 2.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.startsWith('assets/'))
                ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18, top: 4, left: 4, right: 4),
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.backgroundLight,
                        child: Icon(Icons.image_outlined, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                )
              else
                RemoteImage(url: imageUrl, fallbackIcon: Icons.image_outlined),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x33000000), Color(0xCC000000)],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoLabel(
                    size: 11.5,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return aspectRatio != null
        ? AspectRatio(aspectRatio: aspectRatio!, child: tile)
        : tile;
  }
}

class _NoteBox extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _NoteBox({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFEFCBF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFEEBC8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFDD6B20)),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PrivacyNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget line(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 14, color: const Color(0xFFDD6B20)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          line(Icons.lock_outline_rounded,
              'Uploaded images will be used solely to generate virtual try-on previews.'),
          const SizedBox(height: 8),
          line(Icons.favorite_border_rounded,
              'Your privacy is important to us. We do not share your images with anyone.'),
        ],
      ),
    );
  }
}

/// The website's orange pill: "SEE MYSELF IN THIS".
class _PillButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _PillButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDD6B20),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.1),
          disabledForegroundColor: AppColors.textMuted,
          elevation: enabled ? 6 : 0,
          shadowColor: const Color(0xFFDD6B20).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.cta(
            color: enabled ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Square-cornered ink button used for "Apply".
class _InkButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _InkButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cream,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.cream,
          shape: const RoundedRectangleBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 8),
            ],
            Text(label.toUpperCase(),
                style: AppTypography.cta(color: AppColors.cream)),
          ],
        ),
      ),
    );
  }
}

/// "Copy link" and "Open on web" for a finished look.
class _ShareRow extends StatelessWidget {
  final String generationId;

  const _ShareRow({required this.generationId});

  String get _link => ApiEndpoints.shareLink(generationId);

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (context.mounted) {
      UiHelpers.showSnackBar(context, 'Link copied. Paste it anywhere to share.');
    }
  }

  Future<void> _open(BuildContext context) async {
    final ok = await launchUrl(Uri.parse(_link), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      UiHelpers.showSnackBar(context, 'Could not open the link.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle style() => OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.ink.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.link_rounded, size: 16),
            label: Text('COPY LINK', style: AppTypography.monoLabel(size: 11.5)),
            style: style(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text('OPEN ON WEB', style: AppTypography.monoLabel(size: 11.5)),
            style: style(),
          ),
        ),
      ],
    );
  }
}
