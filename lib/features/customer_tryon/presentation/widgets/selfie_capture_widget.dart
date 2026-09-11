import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/widgets/remote_image.dart';

/// The website's upload area: a dashed orange box that turns into a preview
/// with Replace / Remove once a photo is chosen.
class SelfieCaptureWidget extends StatelessWidget {
  final File? selectedFile;
  final String? previewUrl;
  final ValueChanged<File> onFileSelected;

  /// Shown as "Remove" once a photo is chosen. Null hides the button.
  final VoidCallback? onRemove;

  /// Smaller preview for the result screen.
  final bool compact;

  const SelfieCaptureWidget({
    super.key,
    this.selectedFile,
    this.previewUrl,
    required this.onFileSelected,
    this.onRemove,
    this.compact = false,
  });

  static const _orange = Color(0xFFDD6B20);
  static const _orangeLight = Color(0xFFF6AD55);

  Future<void> _pickFromCamera() async {
    final file = await ImagePickerHelper.captureFromCamera();
    if (file != null) onFileSelected(file);
  }

  Future<void> _pickFromGallery() async {
    final file = await ImagePickerHelper.pickFromGallery();
    if (file != null) onFileSelected(file);
  }

  bool get _hasImage =>
      selectedFile != null || (previewUrl != null && previewUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orangeLight, width: 2),
      ),
      child: _hasImage ? _preview() : _empty(),
    );
  }

  Widget _preview() {
    final image = selectedFile != null
        ? Image.file(selectedFile!, fit: BoxFit.contain)
        : RemoteImage(url: previewUrl, fit: BoxFit.contain, fallbackIcon: Icons.person_outline);

    return Column(
      children: [
        if (!compact) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFEFCBF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, size: 14, color: _orange),
                const SizedBox(width: 6),
                Text(
                  'Photo saved for all try-ons (Expires 20m)',
                  style: AppTypography.titleMedium.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: compact ? 120 : 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmallAction(
                icon: Icons.refresh_rounded,
                label: 'Replace',
                color: AppColors.textSecondary,
                onTap: _pickFromGallery,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _SmallAction(
                  icon: Icons.close_rounded,
                  label: 'Remove',
                  color: const Color(0xFFDC2626),
                  background: const Color(0xFFFEF2F2),
                  onTap: onRemove!,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _empty() {
    return Column(
      children: [
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFAF0),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cloud_upload_outlined, size: 24, color: _orange),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your photo',
          style: AppTypography.titleMedium.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: _pickFromCamera,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OutlineAction(
                icon: Icons.folder_open_outlined,
                label: 'Browse Files',
                onTap: _pickFromGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'PNG, JPG, HEIC · Max 10 MB',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 9,
            color: const Color(0xFFA0AEC0),
          ),
        ),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: AppTypography.titleMedium.copyWith(fontSize: 10, color: SelfieCaptureWidget._orange)),
      style: OutlinedButton.styleFrom(
        foregroundColor: SelfieCaptureWidget._orange,
        side: const BorderSide(color: SelfieCaptureWidget._orange),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? background;
  final VoidCallback onTap;

  const _SmallAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 12),
      label: Text(label.toUpperCase(), style: AppTypography.monoLabel(size: 9, color: color, letterSpacing: 1)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: background ?? Colors.white,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
