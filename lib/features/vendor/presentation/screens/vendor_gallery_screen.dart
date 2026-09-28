import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../routes/app_router.dart';
import '../../../shop/data/shop_repository.dart';
import '../../data/vendor_repository.dart';

/// The merchant's own drapes — the website's `/gallery`.
///
/// Shows only finished phase-1 catalogue drapes. Every card can copy its
/// customer share link or open the customer try-on for it, and the whole
/// gallery has a shareable `/shop/:vendorId` link. Deleting is reserved for
/// the master vendor account, as on the web.
class VendorGalleryScreen extends StatefulWidget {
  /// True when shown as the "My Looks" tab body, which swaps this screen out
  /// itself when the merchant signs out.
  final bool embedded;

  const VendorGalleryScreen({super.key, this.embedded = false});

  @override
  State<VendorGalleryScreen> createState() => _VendorGalleryScreenState();
}

class _Drape {
  final String id;
  final String? category;
  final String imageUrl;

  const _Drape({required this.id, required this.category, required this.imageUrl});
}

class _VendorGalleryScreenState extends State<VendorGalleryScreen> {
  static const _masterVendorEmail = 'vendor@store.com';

  final _vendorRepo = VendorRepository();
  bool _isLoading = true;
  String? _error;
  List<_Drape> _drapes = const [];

  bool get _isMasterVendor => AuthSession.instance.vendorEmail == _masterVendorEmail;

  String? get _vendorId => AuthSession.instance.vendorProfile?['id']?.toString();

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onSession);
    _load();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onSession);
    super.dispose();
  }

  /// The token was dropped (expired or rejected). Embedded, the library tab
  /// replaces this screen; pushed standalone, go back to sign-in instead of
  /// leaving a gallery whose every request will 401.
  void _onSession() {
    if (!mounted || widget.embedded || AuthSession.instance.isVendorSignedIn) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.vendorLogin, (_) => false);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await _vendorRepo.fetchVendorGenerations();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!res.success || res.data == null) {
        _error = res.error ?? 'Failed to fetch gallery';
        return;
      }
      // Same filter as the website: vendor drapes with a real AI result.
      _drapes = res.data!
          .whereType<Map<String, dynamic>>()
          .where((g) =>
              (g['mode'] ?? 'with_garment') == 'with_garment' &&
              (g['phase'] ?? 1) == 1 &&
              (g['resultImageUrl'] as String?)?.isNotEmpty == true)
          .map((g) => _Drape(
                id: g['id'].toString(),
                category: g['category'] as String?,
                imageUrl: g['resultImageUrl'] as String,
              ))
          .toList();
    });
  }

  Future<void> _copy(String link, String toast) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) UiHelpers.showSnackBar(context, toast);
  }

  Future<void> _delete(_Drape drape) async {
    // Say what this actually does. It is not a gallery tidy-up: the drape is
    // the product's photograph, so deleting it takes the garment out of the
    // catalogue and breaks the link anyone has been given for it.
    final ok = await UiHelpers.confirm(
      context,
      title: 'Delete this drape from your catalogue?',
      message: 'This is the draped photo of the garment. Deleting it removes '
          'the product from your catalogue too, so nobody can try that garment '
          'on any more. Its share link stops working, and it cannot be undone.',
      confirmLabel: 'Delete product',
      cancelLabel: 'Keep it',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final before = _drapes;
    setState(() => _drapes = _drapes.where((d) => d.id != drape.id).toList());

    final res = await _vendorRepo.deleteVendorGeneration(drape.id);
    if (!mounted) return;
    if (res.success) {
      // The public shop and the demo rail read a 90 s cache.
      ShopRepository.invalidateCache();
    } else {
      setState(() => _drapes = before);
      // Raw server text told the merchant nothing they could act on and
      // leaked internals onto the screen.
      UiHelpers.showSnackBar(
        context,
        'That drape could not be deleted. Please try again.',
        isError: true,
      );
    }
  }

  void _preview(_Drape drape) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.95),
      // A bare dialog route has no Material ancestor, which IconButton needs.
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: InteractiveViewer(
                    child: RemoteImage(url: drape.imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorId = _vendorId;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Vendor Gallery', style: AppTypography.display(size: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR BEAUTIFULLY DRAPED CATALOG READY TO BE SHARED WITH CUSTOMERS.',
                  style: AppTypography.monoLabel(size: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: vendorId == null
                        ? null
                        : () => _copy(ApiEndpoints.shopLink(vendorId), 'Gallery Link Copied!'),
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: Text('SHARE FULL GALLERY', style: AppTypography.monoLabel(size: 12, color: AppColors.ink)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.ink),
                      shape: const RoundedRectangleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyStateView.error(title: 'Could not load your gallery', message: _error!, onAction: _load);
    }
    if (_drapes.isEmpty) {
      return const EmptyStateView(
        icon: Icons.share_outlined,
        title: 'No draped garments yet.',
        message: 'Generate a try-on in the studio and it will appear here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.brandOrange,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _drapes.length,
        itemBuilder: (context, i) => FadeSlideIn(
          key: ValueKey(_drapes[i].id),
          delay: AppMotion.staggerFor(i),
          child: _DrapeCard(
            drape: _drapes[i],
            canDelete: _isMasterVendor,
            onPreview: () => _preview(_drapes[i]),
            onDelete: () => _delete(_drapes[i]),
            onShare: () => _copy(ApiEndpoints.shareLink(_drapes[i].id), 'Copied'),
            onTryOn: () => AppRouter.openStudio(
              context,
              garmentImageUrl: _drapes[i].imageUrl,
              title: _drapes[i].category,
              category: _drapes[i].category,
              generationId: _drapes[i].id,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrapeCard extends StatelessWidget {
  final _Drape drape;
  final bool canDelete;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onTryOn;

  const _DrapeCard({
    required this.drape,
    required this.canDelete,
    required this.onPreview,
    required this.onDelete,
    required this.onShare,
    required this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFF7F5700);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onPreview,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.background,
                    child: RemoteImage(url: drape.imageUrl, fallbackIcon: Icons.checkroom),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      children: [
                        _MiniIcon(icon: Icons.visibility_outlined, onTap: onPreview),
                        if (canDelete) ...[
                          const SizedBox(width: 4),
                          _MiniIcon(icon: Icons.delete_outline, color: const Color(0xFFEF4444), onTap: onDelete),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (drape.category ?? 'Draped Garment').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoLabel(size: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.copy_rounded, size: 13),
                    label: Text('SHARE', style: AppTypography.monoLabel(size: 11, color: AppColors.ink, letterSpacing: 1)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      backgroundColor: AppColors.cream,
                      side: const BorderSide(color: AppColors.ink),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: const RoundedRectangleBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onTryOn,
                  icon: const Icon(Icons.open_in_new_rounded, size: 13),
                  label: Text('TRYON', style: AppTypography.monoLabel(size: 11, color: AppColors.cream, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniIcon({required this.icon, required this.onTap, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
