import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/catalog_repository.dart';

/// Modal bottom sheet for viewing / editing the B2B client's business profile.
///
/// Delegates to [CatalogRepository.fetchBusinessProfile] and
/// [CatalogRepository.updateBusinessProfile].
class BusinessProfileSheet extends StatefulWidget {
  const BusinessProfileSheet._();

  /// Convenience opener — matches the project convention of static `show*`
  /// methods on modal widgets.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const BusinessProfileSheet._(),
    );
  }

  @override
  State<BusinessProfileSheet> createState() => _BusinessProfileSheetState();
}

class _BusinessProfileSheetState extends State<BusinessProfileSheet> {
  final _catalogRepo = CatalogRepository();

  final _companyController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _phoneController = TextEditingController();

  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _businessTypeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _catalogRepo.fetchBusinessProfile();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        final data = res.data!;
        _email = data['email'] as String? ?? '';
        _companyController.text = data['companyName'] as String? ??
            data['storeName'] as String? ??
            '';
        _businessTypeController.text = data['businessType'] as String? ?? '';
        _phoneController.text = data['mobileNumber'] as String? ?? '';
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final res = await _catalogRepo.updateBusinessProfile(
      companyName: _companyController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      mobileNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res.success) {
      UiHelpers.showSnackBar(context, 'Profile updated.');
      Navigator.pop(context);
    } else {
      UiHelpers.showSnackBar(
        context,
        res.error ?? 'Could not update profile.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet so the sheet doesn't cover the keyboard.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.business_outlined, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            Text('Business Profile', style: AppTypography.titleLarge),
            const SizedBox(height: 20),

            if (_isLoading) ...[
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              // Read-only email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: AppTypography.titleMedium.copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  _email.isNotEmpty ? _email : '—',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Company Name',
                hint: 'e.g. Silk Heritage Studio',
                controller: _companyController,
                prefixIcon: const Icon(Icons.business_outlined, size: 20),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Business Type',
                hint: 'e.g. Wholesaler, Boutique',
                controller: _businessTypeController,
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Mobile Number',
                hint: '+91 9876543210',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
