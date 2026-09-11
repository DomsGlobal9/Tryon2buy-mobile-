import 'package:flutter/material.dart';

import '../../../../core/session/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../catalog/presentation/screens/catalog_browser_screen.dart';
import '../../../landing/presentation/screens/landing_screen.dart';
import '../../../library/presentation/screens/customer_library_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Lets a descendant switch shell tabs without knowing about the shell.
///
/// Screens inside the shell (the home hero's "Try On", the profile's "My
/// Looks") should move between tabs rather than pushing a full-screen route
/// on top, which would cover the bottom bar. Screens reached by a real push
/// find no scope and fall back to normal navigation.
class MainShellScope extends InheritedWidget {
  final ValueChanged<int> goToTab;

  const MainShellScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>();

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => false;
}

/// The app's persistent navigation shell: Home · Discover · My Looks · Profile.
///
/// All four tabs stay mounted in an [IndexedStack] so switching back preserves
/// scroll position and fetched data. Merchant access lives on the Profile tab
/// and the home screen rather than taking a tab of its own.
class MainShellScreen extends StatefulWidget {
  /// Tab to open on first build. 0 Home · 1 Discover · 2 My Looks · 3 Profile.
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  static const int tabCount = 4;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  /// Clamped: an out-of-range index would make [IndexedStack] throw on build.
  late int _index = widget.initialIndex.clamp(0, MainShellScreen.tabCount - 1);

  @override
  void initState() {
    super.initState();
    // Warm the session so Profile and My Looks have account state on first
    // paint instead of flashing a signed-out layout.
    AuthSession.instance.refresh();
  }

  void _onTabSelected(int next) {
    if (next == _index) return;
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      goToTab: _onTabSelected,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            // `IndexedStack` keeps every tab mounted, so offscreen tabs would
            // keep animating. `TickerMode` freezes the tickers of whichever
            // tab is not visible, so animation work only runs for the tab
            // you are actually looking at.
            _KeepAlive(active: _index == 0, child: const LandingScreen()),
            _KeepAlive(active: _index == 1, child: const CatalogBrowserScreen()),
            _KeepAlive(active: _index == 2, child: const CustomerLibraryScreen()),
            _KeepAlive(active: _index == 3, child: const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          index: _index,
          onSelected: _onTabSelected,
        ),
      ),
    );
  }
}

/// Mounts [child] permanently but only lets it animate while [active].
class _KeepAlive extends StatelessWidget {
  final bool active;
  final Widget child;

  const _KeepAlive({required this.active, required this.child});

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: active, child: child);
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;

  const _BottomNav({required this.index, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.brandOrangeLight,
            surfaceTintColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => AppTypography.bodyMedium.copyWith(
                fontSize: 11.5,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 23,
                color: states.contains(WidgetState.selected)
                    ? AppColors.brandOrange
                    : AppColors.textSecondary,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onSelected,
            height: 64,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.checkroom_outlined),
                selectedIcon: Icon(Icons.checkroom_rounded),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.collections_bookmark_outlined),
                selectedIcon: Icon(Icons.collections_bookmark_rounded),
                label: 'My Looks',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
