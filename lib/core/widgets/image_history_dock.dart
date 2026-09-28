import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/customer_tryon/domain/entities/dock_garment.dart';
import '../../features/customer_tryon/domain/entities/dock_photo.dart';
import '../../features/customer_tryon/domain/entities/selfie_record.dart';
import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'remote_image.dart';

/// The photo dock — a horizontal strip of thumbnails with result-count
/// badges and a sync indicator.
///
/// Two kinds of thing live here, and they are never mixed in one list:
///
///  * **Photos** — the customer's own photographs. Tapping one means
///    "dress *me* in whatever outfit is open". They expire twenty minutes
///    after last use, which the badge counts down.
///  * **Tried outfits** — garments from the shop's catalogue that have been
///    tried on, across every device the account is signed in on. Tapping
///    one means "keep my photo, switch the garment". Shop activity, not a
///    privacy window.
///
/// When [garments] is empty (always, for a guest — the server derives that
/// list per merchant) the dock is just the photo strip it always was. When
/// it has entries, a segmented control above the strip switches between
/// the two categories.
///
/// Photo data comes in two shapes: legacy `List<SelfieRecord>` (guest-only
/// fallback) and unified `List<DockPhoto>` from the DockFacade. The strip
/// prefers [dockPhotos] and falls back to [history].
class ImageHistoryDock extends StatefulWidget {
  /// Legacy selfie records (guest-only fallback).
  final List<SelfieRecord> history;

  /// Unified dock photos (from DockFacade), with nested try-on results.
  final List<DockPhoto> dockPhotos;

  /// The shop's "tried on" list. Empty hides the tab entirely.
  final List<DockGarment> garments;

  final String? activeImageId;

  /// The asset id of the garment currently on the canvas, so its tile is
  /// highlighted in the outfits tab.
  final String? activeGarmentAssetId;

  /// Called when a legacy selfie record is tapped.
  final ValueChanged<SelfieRecord> onSelectImage;

  /// Called when a dock photo is tapped.
  final ValueChanged<DockPhoto>? onSelectDockPhoto;

  /// "Try This": swap the canvas garment for this one.
  final ValueChanged<DockGarment>? onSelectGarment;

  /// Long-press on an outfit: remove it from the tried-on list.
  final ValueChanged<DockGarment>? onDeleteGarment;

  final VoidCallback onAddImage;

  /// Whether the dock is synced with the server.
  final bool isRemoteDock;

  /// Called on long-press of a dock photo (vendor: delete photo).
  final ValueChanged<DockPhoto>? onDeleteDockPhoto;

  /// True while a generation or retouch is in flight.
  ///
  /// The dock stays open and both tabs still browse — someone waiting on a
  /// generation is exactly who wants to look at what to try next. What is
  /// refused is *applying* a change, because swapping the photo or the
  /// garment out from under a running pipeline produces a result belonging
  /// to a pair of inputs nobody ever chose together.
  final bool busy;

  const ImageHistoryDock({
    super.key,
    required this.history,
    this.dockPhotos = const [],
    this.garments = const [],
    this.activeImageId,
    this.activeGarmentAssetId,
    required this.onSelectImage,
    this.onSelectDockPhoto,
    this.onSelectGarment,
    this.onDeleteGarment,
    required this.onAddImage,
    this.isRemoteDock = false,
    this.onDeleteDockPhoto,
    this.busy = false,
  });

  @override
  State<ImageHistoryDock> createState() => _ImageHistoryDockState();
}

enum _DockTab { photos, outfits }

class _ImageHistoryDockState extends State<ImageHistoryDock> {
  _DockTab _tab = _DockTab.photos;

  /// Repaints the expiry badges so they actually count down.
  ///
  /// A badge reads the clock while it is being laid out and nothing else
  /// drives a repaint, so without this the number is frozen at whatever it
  /// was when the strip was last built and only jumps when something
  /// unrelated rebuilds the tree. Twenty seconds keeps a minute-resolution
  /// label at most twenty seconds stale, which costs nothing.
  Timer? _ticker;

  /// Whether anything on screen is actually counting down. A dock photo only
  /// shows a deadline once the server has said when it was last used, so a
  /// dock that has none does not need repainting at all.
  bool get _needsTicker =>
      widget.history.isNotEmpty ||
      widget.dockPhotos.any((p) => p.lastUsedAt != null);

  void _syncTicker() {
    if (_needsTicker) {
      _ticker ??= Timer.periodic(const Duration(seconds: 20), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _useDockPhotos => widget.dockPhotos.isNotEmpty;
  int get _photoCount =>
      _useDockPhotos ? widget.dockPhotos.length : widget.history.length;
  bool get _hasOutfits => widget.garments.isNotEmpty;

  @override
  void didUpdateWidget(covariant ImageHistoryDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the outfits list empties out from under the open tab (last one
    // deleted, or the merchant signed out), fall back rather than showing
    // an empty strip with no way to switch.
    if (_tab == _DockTab.outfits && !_hasOutfits) _tab = _DockTab.photos;
    _syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    if (_photoCount == 0 && !_hasOutfits) return const SizedBox.shrink();

    final showOutfits = _hasOutfits && _tab == _DockTab.outfits;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasOutfits) ...[
            _Segmented(
              selected: _tab,
              photoCount: _photoCount,
              outfitCount: widget.garments.length,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 8),
          ],
          // The dock fills the width it is given and lets the thumbnail
          // strip scroll inside what is left. A shrink-wrapped strip in a
          // min-width row grew with every photo (ten thumbnails is ~500 px)
          // and overflowed the screen once the history held six or more.
          //
          // While busy the callbacks are dropped rather than the whole strip
          // being wrapped in an IgnorePointer: that would kill the horizontal
          // scroll too, and browsing is the one thing that stays allowed.
          AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: widget.busy ? 0.45 : 1,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: showOutfits
                  ? _OutfitStrip(
                      key: const ValueKey('outfits'),
                      garments: widget.garments,
                      activeAssetId: widget.activeGarmentAssetId,
                      onSelect: widget.busy ? null : widget.onSelectGarment,
                      onDelete: widget.busy ? null : widget.onDeleteGarment,
                    )
                  : _PhotoStrip(
                      key: const ValueKey('photos'),
                      history: widget.history,
                      dockPhotos: widget.dockPhotos,
                      activeImageId: widget.activeImageId,
                      isRemoteDock: widget.isRemoteDock,
                      onSelectImage: widget.busy ? null : widget.onSelectImage,
                      onSelectDockPhoto:
                          widget.busy ? null : widget.onSelectDockPhoto,
                      onDeleteDockPhoto:
                          widget.busy ? null : widget.onDeleteDockPhoto,
                      onAddImage: widget.busy ? null : widget.onAddImage,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Segmented control
// ═══════════════════════════════════════════════════════════════════════

/// The website's dock accent (`#dd6b20`), which marks the open tab. The same
/// orange the fitting room already uses for its pill button and rules.
const Color _dockAccent = Color(0xFFDD6B20);

class _Segmented extends StatelessWidget {
  final _DockTab selected;
  final int photoCount;
  final int outfitCount;
  final ValueChanged<_DockTab> onChanged;

  const _Segmented({
    required this.selected,
    required this.photoCount,
    required this.outfitCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          // Wording, counts and icons follow the website's dock verbatim:
          // "My Photos (n)" / "Outfits Tried (m)".
          _SegmentTab(
            icon: Icons.image_outlined,
            label: 'My Photos ($photoCount)',
            selected: selected == _DockTab.photos,
            onTap: () => onChanged(_DockTab.photos),
          ),
          _SegmentTab(
            icon: Icons.checkroom_rounded,
            label: 'Outfits Tried ($outfitCount)',
            selected: selected == _DockTab.outfits,
            onTap: () => onChanged(_DockTab.outfits),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _dockAccent : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsets.symmetric(vertical: 7),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoLabel(size: 10.5, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Photos strip
// ═══════════════════════════════════════════════════════════════════════

class _PhotoStrip extends StatelessWidget {
  final List<SelfieRecord> history;
  final List<DockPhoto> dockPhotos;
  final String? activeImageId;
  final bool isRemoteDock;

  /// Null while busy — the strip still scrolls, but nothing can be applied.
  final ValueChanged<SelfieRecord>? onSelectImage;
  final ValueChanged<DockPhoto>? onSelectDockPhoto;
  final ValueChanged<DockPhoto>? onDeleteDockPhoto;
  final VoidCallback? onAddImage;

  const _PhotoStrip({
    super.key,
    required this.history,
    required this.dockPhotos,
    required this.activeImageId,
    required this.isRemoteDock,
    required this.onSelectImage,
    required this.onSelectDockPhoto,
    required this.onDeleteDockPhoto,
    required this.onAddImage,
  });

  bool get _useDockPhotos => dockPhotos.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final itemCount = _useDockPhotos ? dockPhotos.length : history.length;

    return Row(
      children: [
        // Add Photo button
        InkWell(
          onTap: onAddImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.add_a_photo_outlined,
                size: 18, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),

        // Sync indicator (cloud icon for remote dock)
        if (isRemoteDock) ...[
          const Icon(Icons.cloud_done_outlined,
              size: 16, color: AppColors.accentGold),
          const SizedBox(width: 6),
        ],

        Container(width: 1, height: 28, color: AppColors.border),
        const SizedBox(width: 8),

        // Thumbnail strip
        Expanded(
          child: SizedBox(
            height: 52,
            child: itemCount == 0
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No photos yet',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: itemCount,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (_useDockPhotos) {
                        final photo = dockPhotos[index];
                        return _DockPhotoThumbnail(
                          photo: photo,
                          isSelected: photo.id == activeImageId,
                          // The open room beats a heartbeat for the photo it
                          // is using, which keeps resetting the server's
                          // clock — so a countdown on that one would sit at
                          // twenty minutes forever and read as broken.
                          held: isRemoteDock && photo.id == activeImageId,
                          onTap: () => onSelectDockPhoto?.call(photo),
                          onLongPress: onDeleteDockPhoto != null
                              ? () => onDeleteDockPhoto!.call(photo)
                              : null,
                        );
                      }
                      final item = history[index];
                      return _LegacyThumbnail(
                        record: item,
                        isSelected: item.id == activeImageId,
                        onTap: onSelectImage == null
                            ? null
                            : () => onSelectImage!(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// A dock photo thumbnail with a result-count badge and an expiry countdown.
class _DockPhotoThumbnail extends StatelessWidget {
  final DockPhoto photo;
  final bool isSelected;

  /// True when this room is holding the photo open, so it will not expire
  /// while the screen is up.
  final bool held;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _DockPhotoThumbnail({
    required this.photo,
    required this.isSelected,
    this.held = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 46,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Photo circle
            Positioned(
              top: 3,
              left: 3,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accentGold : AppColors.border,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: ClipOval(
                  child: _buildThumbImage(photo.imageUrl),
                ),
              ),
            ),

            // Active indicator dot
            if (isSelected)
              Positioned(
                right: 4,
                top: 34,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Result count badge
            if (photo.resultCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: _CountBadge(text: '${photo.resultCount}'),
              ),

            // Expiry countdown — the twenty-minute privacy window.
            if (photo.lastUsedAt != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ExpiryBadge(lastUsedAt: photo.lastUsedAt!, held: held),
              ),
          ],
        ),
      ),
    );
  }
}

/// Legacy thumbnail (used when dock photos are not available).
class _LegacyThumbnail extends StatelessWidget {
  final SelfieRecord record;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LegacyThumbnail({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 3,
              left: 3,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accentGold : AppColors.border,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: ClipOval(
                  child: _buildThumbImage(record.imageUrl),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 4,
                top: 34,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ExpiryBadge(lastUsedAt: record.lastUsedAt),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Tried-outfits strip
// ═══════════════════════════════════════════════════════════════════════

class _OutfitStrip extends StatelessWidget {
  final List<DockGarment> garments;
  final String? activeAssetId;
  final ValueChanged<DockGarment>? onSelect;
  final ValueChanged<DockGarment>? onDelete;

  const _OutfitStrip({
    super.key,
    required this.garments,
    required this.activeAssetId,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: garments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final garment = garments[index];
          return _GarmentThumbnail(
            garment: garment,
            isSelected: garment.primaryAssetId == activeAssetId,
            onTap: () => onSelect?.call(garment),
            onLongPress:
                onDelete != null ? () => onDelete!.call(garment) : null,
          );
        },
      ),
    );
  }
}

/// A tried garment: square tile (it is a product, not a face), the try-on
/// count as a badge, and how long ago it was last tried underneath.
class _GarmentThumbnail extends StatelessWidget {
  final DockGarment garment;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _GarmentThumbnail({
    required this.garment,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: garment.title.isEmpty ? 'Try this' : garment.title,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: 46,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 3,
                left: 3,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGold
                          : AppColors.border,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RemoteImage(
                    url: garment.imageUrl,
                    fallbackIcon: Icons.checkroom,
                  ),
                ),
              ),
              if (garment.tryOnCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: _CountBadge(text: '${garment.tryOnCount}'),
                ),
              if (garment.lastTriedAt != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MicroLabel(text: _ago(garment.lastTriedAt!)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Badges
// ═══════════════════════════════════════════════════════════════════════

class _CountBadge extends StatelessWidget {
  final String text;
  const _CountBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// "⏱ 18m" — minutes left in the photo's twenty-minute window.
///
/// The window is a sliding one: twenty minutes since the photo was last
/// *used*, not since it was uploaded, so that a customer being fitted for
/// half an hour does not lose their photo part-way through. Generating,
/// picking the photo, and the open room's heartbeat all count as use and
/// restart it.
///
/// Which is why [held] exists. While this room is beating for the photo it
/// has open, that clock is reset every thirty seconds, so a countdown on it
/// would read twenty minutes forever and look broken — worse, it looked like
/// the timer was restarting on every refresh. Say what is actually true
/// instead: it is in use and it is not going anywhere.
class _ExpiryBadge extends StatelessWidget {
  final DateTime lastUsedAt;
  final bool held;

  const _ExpiryBadge({required this.lastUsedAt, this.held = false});

  @override
  Widget build(BuildContext context) {
    if (held) return const _MicroLabel(text: '● in use');

    final left = SelfieRecord.expiryDurationMinutes -
        DateTime.now().difference(lastUsedAt).inMinutes;
    final minutes = left.clamp(0, SelfieRecord.expiryDurationMinutes);
    return _MicroLabel(text: '⏱ ${minutes}m');
  }
}

class _MicroLabel extends StatelessWidget {
  final String text;
  const _MicroLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

Widget _buildThumbImage(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('/') || trimmed.startsWith('file:')) {
    final path = trimmed.startsWith('file://') ? trimmed.substring(7) : trimmed;
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.person, size: 20),
    );
  }
  return CachedNetworkImage(
    imageUrl: trimmed,
    fit: BoxFit.cover,
    placeholder: (_, _) => Container(color: AppColors.borderLight),
    errorWidget: (_, _, _) => const Icon(Icons.person, size: 20),
  );
}
