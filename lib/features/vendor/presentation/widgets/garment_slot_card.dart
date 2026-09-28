import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../data/studio_catalog.dart';
import '../screens/vendor_workspace_screen.dart' show SlotUpload;

/// One dashed upload slot from the studio ("Saree *", "Top *", …): gallery
/// and camera buttons when empty, the picked image with Remove when filled.
class GarmentSlotCard extends StatelessWidget {
  final UploadSlot slot;
  final SlotUpload? upload;
  final ValueChanged<File> onPicked;
  final VoidCallback onRemoved;

  const GarmentSlotCard({
    super.key,
    required this.slot,
    required this.upload,
    required this.onPicked,
    required this.onRemoved,
  });

  static const _gold = Color(0xFF7F5700);

  Future<void> _pick(bool camera) async {
    final file = camera
        ? await ImagePickerHelper.captureFromCamera()
        : await ImagePickerHelper.pickFromGallery();
    if (file != null) onPicked(file);
  }

  @override
  Widget build(BuildContext context) {
    final filled = upload != null;

    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? _gold.withValues(alpha: 0.5) : const Color(0xFFDCD6CC),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.monoLabel(size: 12.5, letterSpacing: 1.2),
                  children: [
                    TextSpan(text: slot.label.toUpperCase()),
                    if (slot.required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 32, 10, 10),
            child: filled ? _filled() : _empty(),
          ),
        ],
      ),
    );
  }

  Widget _filled() {
    final u = upload!;
    return Column(
      children: [
        SizedBox(
          height: 96,
          child: u.file != null
              ? Image.file(u.file!, fit: BoxFit.contain)
              : RemoteImage(url: u.url, fit: BoxFit.contain, fallbackIcon: Icons.checkroom),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRemoved,
          icon: const Icon(Icons.close_rounded, size: 14),
          label: Text('REMOVE', style: AppTypography.monoLabel(size: 11.5, color: const Color(0xFFEF4444), letterSpacing: 0.8)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    Widget action(IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2EFE9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: _gold),
              ),
              const SizedBox(height: 6),
              Text(label.toUpperCase(), style: AppTypography.monoLabel(size: 11, letterSpacing: 1.0)),
            ],
          ),
        );

    return Column(
      children: [
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              action(Icons.upload_rounded, 'Gallery', () => _pick(false)),
              const SizedBox(width: 16),
              action(Icons.camera_alt_outlined, 'Camera', () => _pick(true)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'JPG, PNG • Max 10MB',
          style: AppTypography.bodyMedium.copyWith(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
