import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/customer_tryon/domain/entities/dock_photo.dart';
import '../../features/customer_tryon/domain/entities/selfie_record.dart';
import '../theme/app_colors.dart';

/// The photo dock — a horizontal strip of customer-photo thumbnails with
/// result-count badges and a sync indicator.
///
/// Supports two data shapes:
/// - **Legacy**: `List<SelfieRecord>` (used when `dockPhotos` is empty).
/// - **Unified**: `List<DockPhoto>` from the DockFacade.
///
/// The UI adapts automatically: when [dockPhotos] is non-empty it shows
/// those (with result badges); otherwise it falls back to [history].
class ImageHistoryDock extends StatelessWidget {
  /// Legacy selfie records (guest-only fallback).
  final List<SelfieRecord> history;

  /// Unified dock photos (from DockFacade), with nested try-on results.
  final List<DockPhoto> dockPhotos;

  final String? activeImageId;

  /// Called when a legacy selfie record is tapped.
  final ValueChanged<SelfieRecord> onSelectImage;

  /// Called when a dock photo is tapped.
  final ValueChanged<DockPhoto>? onSelectDockPhoto;

  final VoidCallback onAddImage;

  /// Whether the dock is synced with the server.
  final bool isRemoteDock;

  /// Called on long-press of a dock photo (vendor: delete photo).
  final ValueChanged<DockPhoto>? onDeleteDockPhoto;

  const ImageHistoryDock({
    super.key,
    required this.history,
    this.dockPhotos = const [],
    this.activeImageId,
    required this.onSelectImage,
    this.onSelectDockPhoto,
    required this.onAddImage,
    this.isRemoteDock = false,
    this.onDeleteDockPhoto,
  });

  bool get _useDockPhotos => dockPhotos.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final itemCount = _useDockPhotos ? dockPhotos.length : history.length;
    if (itemCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // The dock fills the width it is given and lets the thumbnail strip
      // scroll inside what is left. A shrink-wrapped strip in a min-width
      // row grew with every photo (ten thumbnails is ~500 px) and overflowed
      // the screen once the history held six or more.
      child: Row(
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
              child: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),

          // Sync indicator (cloud icon for remote dock)
          if (isRemoteDock) ...[
            const Icon(Icons.cloud_done_outlined, size: 16, color: AppColors.accentGold),
            const SizedBox(width: 6),
          ],

          Container(width: 1, height: 28, color: AppColors.border),
          const SizedBox(width: 8),

          // Thumbnail strip
          Expanded(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: itemCount,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (_useDockPhotos) {
                    return _DockPhotoThumbnail(
                      photo: dockPhotos[index],
                      isSelected: dockPhotos[index].id == activeImageId,
                      onTap: () => onSelectDockPhoto?.call(dockPhotos[index]),
                      onLongPress: onDeleteDockPhoto != null
                          ? () => onDeleteDockPhoto!.call(dockPhotos[index])
                          : null,
                    );
                  } else {
                    final item = history[index];
                    return _LegacyThumbnail(
                      record: item,
                      isSelected: item.id == activeImageId,
                      onTap: () => onSelectImage(item),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dock photo thumbnail with a result-count badge.
class _DockPhotoThumbnail extends StatelessWidget {
  final DockPhoto photo;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _DockPhotoThumbnail({
    required this.photo,
    required this.isSelected,
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
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Photo circle
            Center(
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
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.borderLight),
                    errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
                  ),
                ),
              ),
            ),

            // Active indicator dot
            if (isSelected)
              Positioned(
                right: 2,
                bottom: 2,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                  child: Text(
                    '${photo.resultCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
  final VoidCallback onTap;

  const _LegacyThumbnail({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
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
              child: CachedNetworkImage(
                imageUrl: record.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.borderLight),
                errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.accentGold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
