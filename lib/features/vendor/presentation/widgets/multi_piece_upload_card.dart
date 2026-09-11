import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_picker_helper.dart';

class MultiPieceUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final File? selectedFile;
  final String? uploadedUrl;
  final ValueChanged<File> onFileSelected;

  const MultiPieceUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.selectedFile,
    this.uploadedUrl,
    required this.onFileSelected,
  });

  Future<void> _pickImage(BuildContext context) async {
    final file = await ImagePickerHelper.pickFromGallery();
    if (file != null) {
      onFileSelected(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedFile != null || (uploadedUrl != null && uploadedUrl!.isNotEmpty);

    return InkWell(
      onTap: () => _pickImage(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppColors.accentGold : AppColors.border,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: selectedFile != null
                          ? Image.file(selectedFile!, fit: BoxFit.cover)
                          : RemoteImage(url: uploadedUrl, fallbackIcon: Icons.checkroom),
                    )
                  : const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodyMedium),
                ],
              ),
            ),
            Icon(
              hasImage ? Icons.check_circle : Icons.add_circle_outline,
              color: hasImage ? AppColors.accentGold : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
