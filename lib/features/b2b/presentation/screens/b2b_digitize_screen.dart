import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/presentation/sign_out.dart';
import '../../../vendor/data/studio_catalog.dart';
import '../../../vendor/presentation/screens/vendor_workspace_screen.dart' show SlotUpload;
import '../../../vendor/presentation/widgets/garment_slot_card.dart';
import '../../data/catalog_repository.dart';
import '../widgets/business_profile_sheet.dart';

/// B2B product digitization — the website's `/vendor/upload` wizard.
///
/// Step 1: product details, category (from the vendor's allowed list), the
/// category's upload slots, and for lehengas an optional dupatta style.
/// Generate → Step 2: preview with a summary, "Discard & Retry" (which
/// deletes the preview asset server-side) or "Save to Catalog".
class B2bDigitizeScreen extends StatefulWidget {
  const B2bDigitizeScreen({super.key});

  @override
  State<B2bDigitizeScreen> createState() => _B2bDigitizeScreenState();
}

class _B2bDigitizeScreenState extends State<B2bDigitizeScreen> {
  static const _gold = Color(0xFF7F5700);

  final _catalogRepo = CatalogRepository();

  final _titleController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _allowedCategories = const [];
  String _category = '';
  final Map<String, SlotUpload> _uploads = {};
  String? _dupattaStyleUrl;

  bool _loadingProfile = true;
  String? _profileError;
  bool _busy = false;
  String? _error;

  // Step 2
  String? _resultImageUrl;
  String? _generationId;

  int get _step => _resultImageUrl == null ? 1 : 2;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onSession);
    _loadProfile();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onSession);
    _titleController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// True once the user chose Logout here, so the session listener does not
  /// race it to the navigator: sign-out notifies before `_logout` resumes,
  /// and two `pushNamedAndRemoveUntil` calls in one frame left a login
  /// screen flashing under the home screen.
  bool _leaving = false;

  /// The token was dropped by `ApiClient` (expired, or rejected with 401).
  /// Nothing on this screen works without it, so go back to the portal.
  void _onSession() {
    if (!mounted || _leaving || AuthSession.instance.isVendorSignedIn) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.b2bLogin, (_) => false);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    final res = await _catalogRepo.fetchVendorProfile();
    if (!mounted) return;
    if (!res.success) {
      // Do not fall back to the default category list as if signed in. A 401
      // has already signed the client out (see _onSession); anything else
      // gets a retry.
      setState(() {
        _loadingProfile = false;
        _profileError = res.error ?? 'Could not load your profile.';
      });
      return;
    }
    setState(() {
      final raw = res.data?['allowedCategories'];
      _allowedCategories = raw is List && raw.isNotEmpty
          ? raw.map((e) => e.toString()).toList()
          : StudioCatalog.categories.map((c) => c.key).toList();
      _category = _allowedCategories.first;
      _loadingProfile = false;
    });
  }

  List<UploadSlot> get _slots => StudioCatalog.slotsFor(_category);

  bool get _requiredFilled =>
      _slots.every((s) => !s.required || _uploads.containsKey(s.id));

  // ── Actions ────────────────────────────────────────────────────────

  Future<void> _generate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _category.isEmpty) {
      setState(() => _error = 'Please provide a Product Title and Category.');
      return;
    }
    if (!_requiredFilled) {
      setState(() => _error = 'Please upload all required garment images.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final urls = <String, String>{};
      for (final slot in _slots) {
        final u = _uploads[slot.id];
        if (u == null) continue;
        if (u.file != null) {
          final res = await _catalogRepo.uploadGarmentImage(u.file!);
          if (!res.success || res.data == null) {
            throw Exception(res.error ?? 'Image upload failed.');
          }
          urls[slot.id] = res.data!;
        } else if (u.url != null) {
          urls[slot.id] = u.url!;
        }
      }

      // Website: a saree with no blouse is sent as a plain URL.
      final payload = (_category == StudioCatalog.saree && !urls.containsKey('blouse'))
          ? urls['saree']!
          : jsonEncode(urls);

      final res = await _catalogRepo.generateCatalogPreview(
        garmentSlots: payload,
        category: _category,
        dupattaStyleUrl: _dupattaStyleUrl,
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        throw Exception(res.error ?? 'Generation failed.');
      }
      setState(() {
        _resultImageUrl = res.data!['result_image_url'] as String?;
        _generationId = res.data!['generation_id'] as String?;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final id = _generationId;
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final res = await _catalogRepo.saveToCatalog(
      generationId: id,
      title: _titleController.text.trim(),
      category: _category,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
    );
    if (!mounted) return;

    if (res.success) {
      Navigator.pushReplacementNamed(context, AppRouter.b2bCatalog);
      return;
    }
    setState(() {
      _busy = false;
      _error = res.error ?? 'Failed to save to catalog.';
    });
  }

  Future<void> _discard() async {
    setState(() => _busy = true);
    final id = _generationId;
    if (id != null) await _catalogRepo.discardPreview(id);
    if (!mounted) return;
    setState(() {
      _resultImageUrl = null;
      _generationId = null;
      _busy = false;
    });
  }

  Future<void> _logout() => signOutAndLeave(
        context,
        title: 'Logout?',
        message: 'You will return to the welcome screen. Sign back in any time.',
        confirmLabel: 'Logout',
        beforeSignOut: () => _leaving = true,
      );

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: _StepIndicator(step: _step),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, size: 20),
            tooltip: 'View Catalog',
            onPressed: () => Navigator.pushNamed(context, AppRouter.b2bCatalog),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 20),
            tooltip: 'Business Profile',
            onPressed: () => BusinessProfileSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _profileError != null
              ? EmptyStateView.error(
                  title: 'Could not load your workspace',
                  message: _profileError!,
                  onAction: _loadProfile,
                )
              : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _error!,
                      style: AppTypography.grotesk(size: 13, color: const Color(0xFFB91C1C)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_step == 1) ..._stepOne() else ..._stepTwo(),
              ],
            ),
    );
  }

  List<Widget> _stepOne() {
    final isSaree = _category == StudioCatalog.saree;
    final isLehanga = _category == StudioCatalog.lehanga;

    Widget slot(String id) {
      final s = _slots.firstWhere((x) => x.id == id);
      return GarmentSlotCard(
        slot: s,
        upload: _uploads[id],
        onPicked: (f) => setState(() => _uploads[id] = SlotUpload(file: f)),
        onRemoved: () => setState(() => _uploads.remove(id)),
      );
    }

    return [
      _Card(
        icon: Icons.description_outlined,
        title: 'Product Details',
        children: [
          CustomTextField(
            label: 'PRODUCT TITLE *',
            hint: 'e.g. Midnight Blue Silk Saree',
            controller: _titleController,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'SKU / PRODUCT ID',
            hint: 'e.g. SAREE-MB-001',
            controller: _skuController,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'DESCRIPTION',
            hint: 'Product details, fabric info, styling notes...',
            controller: _descriptionController,
          ),
          const SizedBox(height: 14),
          Text('CATEGORY *', style: AppTypography.grotesk(size: 11, weight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [
              for (final c in _allowedCategories)
                DropdownMenuItem(
                  value: c,
                  child: Text(_titleCase(c), style: AppTypography.grotesk()),
                ),
            ],
            onChanged: (c) {
              if (c == null) return;
              setState(() {
                _category = c;
                _uploads.clear();
                _dupattaStyleUrl = null;
              });
            },
            decoration: const InputDecoration(fillColor: Color(0xFFFDFCF9)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Card(
        icon: Icons.image_outlined,
        title: 'Garment Assets',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(_category, style: AppTypography.grotesk(size: 12, weight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1)),
        ),
        children: [
          if (isSaree)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: slot('saree')),
                const SizedBox(width: 12),
                Expanded(child: slot('blouse')),
              ],
            )
          else ...[
            _rule('Full garment'),
            const SizedBox(height: 10),
            slot('full'),
            const SizedBox(height: 16),
            _rule(isLehanga ? 'Garment parts & dupatta style (optional)' : 'Garment parts'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: slot('top')),
                const SizedBox(width: 12),
                Expanded(child: slot('bottom')),
              ],
            ),
            if (isLehanga) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < DupattaStyle.all.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _DupattaOption(
                        style: DupattaStyle.all[i],
                        selected: _dupattaStyleUrl == DupattaStyle.all[i].url,
                        onTap: () => setState(() {
                          _dupattaStyleUrl = _dupattaStyleUrl == DupattaStyle.all[i].url
                              ? null
                              : DupattaStyle.all[i].url;
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
          const SizedBox(height: 24),
          CustomButton(
            text: _busy ? 'Generating Preview...' : 'Generate Preview',
            isLoading: _busy,
            onPressed: _generate,
          ),
        ],
      ),
    ];
  }

  List<Widget> _stepTwo() {
    Widget field(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppTypography.grotesk(size: 11.5, weight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(value, style: AppTypography.grotesk(size: 14)),
            ],
          ),
        );

    return [
      _Card(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.creamBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RemoteImage(url: _resultImageUrl, fallbackIcon: Icons.checkroom),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 12, color: _gold),
                          const SizedBox(width: 6),
                          Text(_category, style: AppTypography.grotesk(size: 12, weight: FontWeight.w700, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Card(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF16A34A)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generation Complete!', style: AppTypography.grotesk(size: 20, weight: FontWeight.w700)),
                    Text('Review the high-fidelity drape.', style: AppTypography.grotesk(size: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.creamBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                field('Product Title', _titleController.text.trim()),
                if (_skuController.text.trim().isNotEmpty) field('SKU / Product ID', _skuController.text.trim()),
                if (_descriptionController.text.trim().isNotEmpty) field('Description', _descriptionController.text.trim()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _busy ? 'Discarding...' : 'Discard & Retry',
                  isSecondary: true,
                  onPressed: _busy ? null : _discard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: _busy ? 'Saving...' : 'Save to Catalog',
                  backgroundColor: _gold,
                  onPressed: _busy ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  Widget _rule(String text) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.creamBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(text.toUpperCase(), style: AppTypography.grotesk(size: 12, weight: FontWeight.w700, letterSpacing: 2)),
          ),
          const Expanded(child: Divider(color: AppColors.creamBorder)),
        ],
      );

  static String _titleCase(String s) => s.isEmpty ? s : s[0] + s.substring(1).toLowerCase();
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget dot(int n, String label) {
      final on = step >= n;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: on ? const Color(0xFF7F5700) : const Color(0xFFE5E7EB),
            child: Text('$n', style: AppTypography.grotesk(size: 11, weight: FontWeight.w700, color: on ? Colors.white : AppColors.textMuted)),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.grotesk(size: 12, color: on ? AppColors.ink : AppColors.textMuted)),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(1, 'Upload'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: Color(0xFFD1D5DB)),
        ),
        dot(2, 'Preview & Save'),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  const _Card({this.icon, this.title, this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: const Color(0xFF7F5700)),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(title!, style: AppTypography.grotesk(size: 17, weight: FontWeight.w700))),
                ?trailing,
              ],
            ),
            const SizedBox(height: 18),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _DupattaOption extends StatelessWidget {
  final DupattaStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _DupattaOption({required this.style, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFF7F5700);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? gold : AppColors.creamBorder, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RemoteImage(url: style.url, fallbackIcon: Icons.image_outlined),
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
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                style.name.toUpperCase(),
                style: AppTypography.grotesk(size: 12, weight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(radius: 10, backgroundColor: gold, child: Icon(Icons.check, size: 12, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
