import 'package:flutter/material.dart';

import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';

/// Modal bottom sheet for editing vendor business details.
///
/// Parity with web frontend's `VendorProfileModal.jsx`.
class VendorProfileEditSheet extends StatefulWidget {
  const VendorProfileEditSheet({super.key});

  /// Displays the sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VendorProfileEditSheet(),
    );
  }

  @override
  State<VendorProfileEditSheet> createState() => _VendorProfileEditSheetState();
}

class _VendorProfileEditSheetState extends State<VendorProfileEditSheet> {
  final AuthRepository _authRepo = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyController;
  late TextEditingController _businessTypeController;
  late TextEditingController _mobileController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final session = AuthSession.instance;
    _companyController = TextEditingController(text: session.vendorCompanyName ?? '');
    _businessTypeController = TextEditingController(text: session.vendorBusinessType ?? '');
    _mobileController = TextEditingController(text: session.vendorMobileNumber ?? '');

    // Refresh profile in background to get latest server values
    _authRepo.getProfile().then((res) {
      if (res.success && res.data != null && mounted) {
        final u = res.data!;
        setState(() {
          if (_companyController.text.isEmpty && u.companyName != null) {
            _companyController.text = u.companyName!;
          }
          if (_businessTypeController.text.isEmpty && u.businessType != null) {
            _businessTypeController.text = u.businessType!;
          }
          if (_mobileController.text.isEmpty && u.phone != null) {
            _mobileController.text = u.phone!;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _businessTypeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final res = await _authRepo.updateProfile(
      companyName: _companyController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
    );

    if (!mounted) return;

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated successfully! 🎉'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorMessage = res.error ?? 'Failed to update profile.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSession.instance;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
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
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Business Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Update your studio and contact details for customers and invoices.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Read-only email badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        session.vendorEmail ?? 'No email',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Text(
                      'Account Email',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Company Name Field
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'Company / Business Name',
                  hintText: 'e.g. Silk Heritage Boutique',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Business Type Field
              TextFormField(
                controller: _businessTypeController,
                decoration: InputDecoration(
                  labelText: 'Business Type',
                  hintText: 'e.g. Boutique, Designer, Wholesaler',
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Contact Mobile Number Field
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Phone Number',
                  hintText: '+91 98765 43210',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Save CTA
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
