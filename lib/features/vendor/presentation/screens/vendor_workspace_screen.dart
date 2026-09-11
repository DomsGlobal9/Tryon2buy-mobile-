import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/session/auth_session.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/credit_dialogs.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../routes/app_router.dart';
import '../../../shop/data/shop_repository.dart';
import '../../data/studio_catalog.dart';
import '../../data/vendor_repository.dart';
import '../widgets/garment_slot_card.dart';
import '../widgets/sample_materials_sheet.dart';
import '../widgets/workspace_result_preview.dart';

/// The merchant studio — the website's `/workspace` ("Virtual Fitting Room").
///
/// 1. Select category · 2. Upload garment (per-slot, with sample materials
/// and, for lehengas, a dupatta drape style) · 3. Select model · Generate.
/// Then Regenerate / Save to Library. Guests may generate up to the server's
/// free-tier limit; saving asks them to create an account.
class VendorWorkspaceScreen extends StatefulWidget {
  const VendorWorkspaceScreen({super.key});

  @override
  State<VendorWorkspaceScreen> createState() => _VendorWorkspaceScreenState();
}

/// One upload slot's content: a picked file, or a hosted sample URL.
class SlotUpload {
  final File? file;
  final String? url;

  const SlotUpload({this.file, this.url});

  String? get previewUrl => url;
}

class _VendorWorkspaceScreenState extends State<VendorWorkspaceScreen> {
  final _vendorRepo = VendorRepository();

  String _category = StudioCatalog.saree;
  final Map<String, SlotUpload> _uploads = {};
  String? _dupattaStyleUrl;
  late StudioModel _model = StudioCatalog.modelsFor(_category).first;

  bool _isGenerating = false;
  String? _resultImageUrl;
  String? _generationId;
  bool _isSaved = false;
  bool _isSaving = false;

  bool get _isGuest => !AuthSession.instance.isVendorSignedIn;

  List<UploadSlot> get _slots => StudioCatalog.slotsFor(_category);

  bool get _uploadsValid =>
      _slots.every((s) => !s.required || _uploads.containsKey(s.id));

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onSession);
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onSession);
    super.dispose();
  }

  /// A token that expires mid-session flips the studio to its guest form
  /// (uploads and result intact) instead of leaving stale merchant chrome.
  void _onSession() {
    if (mounted) setState(() {});
  }

  // ── Selection ──────────────────────────────────────────────────────

  void _selectCategory(String key) {
    if (key == _category) return;
    setState(() {
      _category = key;
      _uploads.clear();
      _dupattaStyleUrl = null;
      _model = StudioCatalog.modelsFor(key).first;
      _resultImageUrl = null;
      _generationId = null;
      _isSaved = false;
    });
  }

  void _selectModel(StudioModel model) => setState(() {
        _model = model;
        _resultImageUrl = null;
        _generationId = null;
        _isSaved = false;
      });

  Future<void> _openSamples() async {
    // Picks apply the moment they are tapped, as on the website, so closing
    // the sheet any way (X, swipe, tap outside) keeps them. Only hosted
    // samples show as pre-selected; a slot holding a picked file is left
    // alone unless the user chooses a sample for it.
    await SampleMaterialsSheet.show(
      context,
      category: _category,
      current: {
        for (final e in _uploads.entries)
          if (e.value.url != null) e.key: e.value.url!,
      },
      onPicked: (slots) {
        if (!mounted) return;
        setState(() {
          slots.forEach((slot, url) {
            if (url.isNotEmpty) _uploads[slot] = SlotUpload(url: url);
          });
          _resultImageUrl = null;
          _generationId = null;
          _isSaved = false;
        });
      },
    );
  }

  // ── Generate ───────────────────────────────────────────────────────

  Future<void> _generate() async {
    if (!_uploadsValid || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _isSaved = false;
    });

    try {
      final garmentUrls = <String, String>{};
      for (final slot in _slots) {
        final upload = _uploads[slot.id];
        if (upload == null) continue;
        if (upload.file != null) {
          final res = await _vendorRepo.uploadGarmentImage(upload.file!);
          if (!res.success || res.data == null) {
            throw Exception(res.error ?? 'Failed to upload ${slot.label}.');
          }
          garmentUrls[slot.id] = res.data!;
        } else if (upload.url != null) {
          garmentUrls[slot.id] = upload.url!;
        }
      }

      final res = await _vendorRepo.generateVendorDrape(
        garmentImageUrl: jsonEncode(garmentUrls),
        modelImageUrl: _model.imageFor(_dupattaStyleUrl),
        category: _category,
        dupattaStyleUrl: _dupattaStyleUrl,
      );
      if (!mounted) return;

      if (res.isGuestLimitReached) {
        final signIn = await showLimitReachedDialog(context, vendor: false);
        if (signIn && mounted) await _leaveToLogin();
        return;
      }
      if (res.isInsufficientCredits) {
        await showUpgradeDialog(context);
        return;
      }
      if (!res.success || res.data == null) {
        throw Exception(res.error ?? 'Generation failed');
      }

      setState(() {
        _resultImageUrl = res.data!['result_image_url'] as String?;
        _generationId = res.data!['generation_id'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      UiHelpers.showSnackBar(
        context,
        'Generation failed: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── Save / navigation ──────────────────────────────────────────────

  Future<void> _saveToLibrary() async {
    // A library belongs to an account, so a guest is asked to create one.
    // Signing in from that dialog finishes the save they asked for instead
    // of dropping them back on the result with nothing saved.
    if (_isGuest) {
      final choice = await showGuestSaveDialog(context);
      if (!mounted || choice == null) return;
      if (choice == 'account') {
        final signedIn = await _leaveToLogin();
        if (signedIn && mounted) await _saveToLibrary();
      } else {
        Navigator.pushNamed(context, AppRouter.vendorShop,
            arguments: ShopRepository.demoVendorId);
      }
      return;
    }

    if (_isSaved || _isSaving) return;

    final id = _generationId;
    if (id == null) {
      // Nothing to attach: the drape either failed or predates this result.
      UiHelpers.showSnackBar(
        context,
        'Generate a drape first, then save it to your library.',
        isError: true,
      );
      return;
    }
    setState(() => _isSaving = true);

    final res = await _vendorRepo.saveGenerationToLibrary(id);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isSaved = res.success;
    });
    if (res.success) {
      // The merchant's public shop and the demo rail read a 90 s cache.
      ShopRepository.invalidateCache();
    } else {
      UiHelpers.showSnackBar(context, 'Error saving to library', isError: true);
    }
  }

  /// Sends a guest to the merchant login. If they come back signed in, the
  /// studio simply carries on as their studio — uploads and result intact —
  /// rather than dropping them on the home screen.
  ///
  /// Returns whether a business account is signed in on the way back.
  Future<bool> _leaveToLogin() async {
    final storage = await LocalStorageService.getInstance();
    await storage.setGuestMode(false);
    if (!mounted) return false;
    final ok = await Navigator.pushNamed(context, AppRouter.vendorLogin);
    if (!mounted) return false;
    if (ok != true) {
      // Still a guest: keep the free tier available for the next attempt.
      await storage.setGuestMode(true);
    }
    // The repository refreshed the session on a successful sign-in; read it
    // rather than trusting the pop result alone.
    await AuthSession.instance.refresh();
    if (!mounted) return false;
    setState(() {});
    return AuthSession.instance.isVendorSignedIn;
  }

  void _openGallery() {
    if (_isGuest) {
      Navigator.pushNamed(context, AppRouter.vendorShop,
          arguments: ShopRepository.demoVendorId);
    } else {
      Navigator.pushNamed(context, AppRouter.vendorGallery);
    }
  }

  Future<void> _logout() async {
    if (_isGuest) {
      final storage = await LocalStorageService.getInstance();
      await storage.setGuestMode(false);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
      return;
    }
    final ok = await UiHelpers.confirm(
      context,
      title: 'Logout?',
      message: 'You will return to the merchant login.',
      confirmLabel: 'Logout',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await AuthSession.instance.signOutVendor();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.vendorLogin, (_) => false);
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(
          'VIRTUAL TRY-ON',
          style: AppTypography.monoLabel(size: 12, color: const Color(0xFF7F5700)),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openGallery,
            icon: const Icon(Icons.image_outlined, size: 14),
            label: Text('GALLERY', style: AppTypography.monoLabel(size: 9)),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          ),
          IconButton(
            tooltip: _isGuest ? 'Exit Guest Mode' : 'Logout',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Virtual Fitting Room', style: AppTypography.studioHeading()),
          const SizedBox(height: 18),

          // ── 1. Category ─────────────────────────────────────────
          _StepHeader(number: 1, title: 'Select category'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in StudioCatalog.categories)
                _CategoryChip(
                  label: c.key,
                  selected: c.key == _category,
                  onTap: () => _selectCategory(c.key),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 2. Garment ──────────────────────────────────────────
          _StepHeader(number: 2, title: 'Upload garment'),
          const SizedBox(height: 10),
          _NoteBanner(text: StudioCatalog.uploadNoteFor(_category)),
          const SizedBox(height: 12),
          ..._buildSlots(),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _openSamples,
              icon: const Icon(Icons.image_outlined, size: 14),
              label: Text('SAMPLE MATERIALS', style: AppTypography.monoLabel(size: 9.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                backgroundColor: const Color(0xFFFDFCF9),
                side: const BorderSide(color: Color(0xFFDCD6CC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── 3. Model ────────────────────────────────────────────
          _StepHeader(number: 3, title: 'Select model'),
          const SizedBox(height: 12),
          _ModelGrid(
            models: StudioCatalog.modelsFor(_category),
            selected: _model,
            dupattaStyleUrl: _dupattaStyleUrl,
            onSelect: _selectModel,
          ),
          const SizedBox(height: 24),

          // ── Generate ────────────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _uploadsValid && !_isGenerating ? _generate : null,
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: Text(
                'GENERATE TRY-ON',
                style: AppTypography.cta(
                  color: _uploadsValid ? AppColors.cream : AppColors.textMuted,
                  letterSpacing: 3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.cream,
                disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.2),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ),

          // ── Result ──────────────────────────────────────────────
          WorkspaceResultPreview(
            resultImageUrl: _resultImageUrl,
            isGenerating: _isGenerating,
            modelName: _model.name,
            isSaved: _isSaved,
            isSaving: _isSaving,
            // A guest can generate, but a library needs an account: the
            // button says so instead of promising a save it cannot do.
            isGuest: _isGuest,
            onRegenerate: _generate,
            onSaveToLibrary: _saveToLibrary,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlots() {
    Widget slotCard(UploadSlot slot) => GarmentSlotCard(
          slot: slot,
          upload: _uploads[slot.id],
          onPicked: (file) => setState(() => _uploads[slot.id] = SlotUpload(file: file)),
          onRemoved: () => setState(() => _uploads.remove(slot.id)),
        );

    if (_category == StudioCatalog.saree) {
      return [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _slots.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: slotCard(_slots[i])),
            ],
          ],
        ),
      ];
    }

    final full = _slots.firstWhere((s) => s.id == 'full');
    final top = _slots.firstWhere((s) => s.id == 'top');
    final bottom = _slots.firstWhere((s) => s.id == 'bottom');
    final isLehanga = _category == StudioCatalog.lehanga;

    return [
      const _SectionRule('Full garment'),
      const SizedBox(height: 10),
      slotCard(full),
      const SizedBox(height: 16),
      _SectionRule(
        isLehanga ? 'Garment parts & dupatta style (optional)' : 'Garment parts',
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: slotCard(top)),
          const SizedBox(width: 12),
          Expanded(child: slotCard(bottom)),
        ],
      ),
      if (isLehanga) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < DupattaStyle.all.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _DupattaTile(
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
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private pieces
// ═══════════════════════════════════════════════════════════════════════

class _StepHeader extends StatelessWidget {
  final int number;
  final String title;

  const _StepHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          color: AppColors.ink,
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: AppTypography.mono(size: 10, weight: FontWeight.w700, color: AppColors.cream),
          ),
        ),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: AppTypography.monoLabel(size: 11)),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFF7F5700);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? gold : AppColors.ink.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoLabel(
            size: 10,
            color: selected ? gold : AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _NoteBanner extends StatelessWidget {
  final String text;
  const _NoteBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: const Color(0xFF854D0E)),
          children: [
            TextSpan(
              text: 'Note: ',
              style: AppTypography.titleMedium.copyWith(fontSize: 11, color: const Color(0xFF713F12)),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _SectionRule extends StatelessWidget {
  final String text;
  const _SectionRule(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.creamBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text.toUpperCase(), style: AppTypography.monoLabel(size: 9, letterSpacing: 2)),
        ),
        const Expanded(child: Divider(color: AppColors.creamBorder)),
      ],
    );
  }
}

class _DupattaTile extends StatelessWidget {
  final DupattaStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _DupattaTile({required this.style, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFF7F5700);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? gold : AppColors.creamBorder, width: 2),
          boxShadow: selected
              ? [BoxShadow(color: gold.withValues(alpha: 0.2), blurRadius: 0, spreadRadius: 4)]
              : null,
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
                style: AppTypography.monoLabel(size: 8.5, color: Colors.white, letterSpacing: 1),
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: gold,
                  child: Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelGrid extends StatelessWidget {
  final List<StudioModel> models;
  final StudioModel selected;
  final String? dupattaStyleUrl;
  final ValueChanged<StudioModel> onSelect;

  const _ModelGrid({
    required this.models,
    required this.selected,
    required this.dupattaStyleUrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFF7F5700);
    return Row(
      children: [
        for (var i = 0; i < models.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(models[i]),
              child: Opacity(
                opacity: models[i].name == selected.name ? 1 : 0.75,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: models[i].name == selected.name ? gold : Colors.transparent,
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RemoteImage(
                          url: models[i].imageFor(dupattaStyleUrl),
                          fallbackIcon: Icons.person_outline,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: AppColors.ink.withValues(alpha: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    models[i].name.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoLabel(
                                      size: 7,
                                      color: AppColors.cream,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (models[i].name == selected.name)
                                  const Icon(Icons.check, size: 8, color: AppColors.cream),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
