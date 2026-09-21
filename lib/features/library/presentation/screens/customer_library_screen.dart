import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/animations/pressable.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../routes/app_router.dart';
import '../../../customer_tryon/data/datasources/tryon_results_local_data_source.dart';
import '../../../customer_tryon/domain/entities/tryon_result.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';
import '../../../vendor/presentation/screens/vendor_gallery_screen.dart';

/// "My Looks".
///
/// The website keeps a shopper's try-ons on the device for twenty minutes
/// (its IndexedDB result store) and has no server-side library for them, so
/// guests see their recent results here. A signed-in merchant sees the
/// vendor gallery instead — that *is* their library.
class CustomerLibraryScreen extends StatefulWidget {
  const CustomerLibraryScreen({super.key});

  @override
  State<CustomerLibraryScreen> createState() => _CustomerLibraryScreenState();
}

class _CustomerLibraryScreenState extends State<CustomerLibraryScreen> {
  final _store = TryonResultsLocalDataSource();

  bool _isLoading = true;
  List<TryonResult> _looks = const [];

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onSession);
    // The studio writes results while this tab sits mounted in the shell's
    // IndexedStack; without this, "My Looks" showed the old list until a
    // manual refresh.
    TryonResultsLocalDataSource.revision.addListener(_onResultsChanged);
    _load();
  }

  @override
  void dispose() {
    TryonResultsLocalDataSource.revision.removeListener(_onResultsChanged);
    AuthSession.instance.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  void _onResultsChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    // Keep the current grid visible while reloading; only a first load or
    // an empty list shows the spinner.
    setState(() => _isLoading = _looks.isEmpty);
    final looks = await _store.allResults();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _looks = looks;
    });
  }

  void _browseCatalog() {
    final shell = MainShellScope.maybeOf(context);
    if (shell != null) {
      shell.goToTab(1);
    } else {
      Navigator.pushNamed(context, AppRouter.catalog);
    }
  }

  Future<void> _delete(TryonResult look) async {
    final ok = await UiHelpers.confirm(
      context,
      title: 'Remove this look?',
      message: 'It will be removed from this device.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    await _store.removeAnywhere(look.generationId);
    if (mounted) _load();
  }

  Future<void> _share(TryonResult look) async {
    await Clipboard.setData(
      ClipboardData(text: ApiEndpoints.shareLink(look.generationId)),
    );
    if (mounted) UiHelpers.showSnackBar(context, 'Link copied.');
  }

  void _preview(TryonResult look) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.ink.withValues(alpha: 0.95),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: InteractiveViewer(
              child: RemoteImage(url: look.resultImageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A merchant's library is their gallery.
    if (AuthSession.instance.isVendorSignedIn && !AuthSession.instance.isB2bPortal) {
      return const VendorGalleryScreen(embedded: true);
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('My Looks', style: AppTypography.display(size: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_looks.isEmpty) {
      return EmptyStateView(
        icon: Icons.auto_awesome_outlined,
        title: 'No looks yet',
        message:
            'Try on any piece from the collection and it will appear here. '
            'Looks stay on this device for 20 minutes after their last use.',
        actionLabel: 'Browse collection',
        onAction: _browseCatalog,
      );
    }

    return RefreshIndicator(
      color: AppColors.brandOrange,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _looks.length,
        itemBuilder: (context, index) {
          final look = _looks[index];
          return FadeSlideIn(
            key: ValueKey(look.generationId),
            delay: AppMotion.staggerFor(index),
            child: _LookTile(
              look: look,
              onTap: () => _preview(look),
              onShare: () => _share(look),
              onDelete: () => _delete(look),
            ),
          );
        },
      ),
    );
  }
}

class _LookTile extends StatelessWidget {
  final TryonResult look;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _LookTile({
    required this.look,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RemoteImage(url: look.resultImageUrl, fallbackIcon: Icons.broken_image_outlined),
            if (look.category != null)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.glassDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    look.category!.toUpperCase(),
                    style: AppTypography.eyebrow(size: 11.5, color: AppColors.textWhite, letterSpacing: 1),
                  ),
                ),
              ),
            Positioned(
              right: 4,
              top: 4,
              child: Row(
                children: [
                  _RoundAction(icon: Icons.link_rounded, onTap: onShare),
                  const SizedBox(width: 4),
                  _RoundAction(icon: Icons.delete_outline, onTap: onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.textWhite),
        ),
      ),
    );
  }
}
