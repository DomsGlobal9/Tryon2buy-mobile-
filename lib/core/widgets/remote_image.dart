import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Every remote image in the app goes through here.
///
/// Bare `Image.network` has two problems this fixes:
///
///   * **A dead URL throws.** Some seeded links 404, and an unhandled
///     `NetworkImageLoadException` spams the console and paints nothing.
///     Here a 404 degrades to a quiet icon.
///   * **It sizes itself from the decoded bitmap.** Inside a `Row` that means
///     a large image can blow past its constraints. [width]/[height] are
///     applied as a hard `SizedBox` around the image, not just a hint, so the
///     layout is the same whether the image loads, fails, or is still loading.
///
/// [decodeWidth] caps the decoded bitmap. Catalog results are multi-megapixel
/// photos; decoding each at full size for a 160-pixel card is what makes a
/// grid of fifty stutter and get killed for memory. Thumbnails pass a small
/// value; the fitting-room canvas leaves it null for full quality.
class RemoteImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? decodeWidth;

  /// Shown when [url] is null/empty or the fetch fails.
  final IconData fallbackIcon;

  const RemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.decodeWidth,
    this.fallbackIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final String trimmed = url?.trim() ?? '';
    final Widget content;
    if (trimmed.isEmpty) {
      content = _fallback();
    } else if (trimmed.startsWith('assets/')) {
      content = Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: decodeWidth,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    } else if (trimmed.startsWith('/') || trimmed.startsWith('file:')) {
      final path = trimmed.startsWith('file://') ? trimmed.substring(7) : trimmed;
      content = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: decodeWidth,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    } else {
      content = CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: decodeWidth,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholder: (context, url) => _placeholder(),
        errorWidget: (context, url, error) => _fallback(),
      );
    }

    final Widget clipped = borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: content)
        : content;

    // Hard bound: guarantees the slot's size regardless of load state.
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: clipped);
    }
    return clipped;
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.backgroundLight,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppColors.backgroundLight,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: AppColors.textMuted),
      );
}
