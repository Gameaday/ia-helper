import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/home_screen.dart';
import '../../screens/library_screen.dart';
import '../../screens/discover_screen.dart';
import '../../screens/transfers_screen.dart';
import '../../screens/more_screen.dart';
import '../../utils/animation_constants.dart';
import '../../utils/responsive_utils.dart';
import 'navigation_state.dart';

/// Adaptive Material Design 3 navigation shell.
///
/// Implements a 5-tab navigation with per-tab navigation stacks.
/// Each tab maintains its own navigation history and state.
///
/// The shell adapts to the window size (Material 3 window size classes):
/// - Compact (phones): bottom [NavigationBar]
/// - Medium / Expanded (tablets and larger): [NavigationRail] on the side,
///   with inline labels on expanded windows, so content keeps a comfortable
///   reading width and the chrome matches the NavigationRail theme in AppTheme.
///
/// Tabs:
/// 0. Home - Quick identifier search
/// 1. Library - Downloads, collections, and favorites
/// 2. Discover - Keyword search and trending content
/// 3. Transfers - Download/upload management
/// 4. More - Settings and additional options
class BottomNavigationScaffold extends StatefulWidget {
  const BottomNavigationScaffold({super.key});

  @override
  State<BottomNavigationScaffold> createState() =>
      _BottomNavigationScaffoldState();
}

class _BottomNavigationScaffoldState extends State<BottomNavigationScaffold> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationState>(
      builder: (context, navigationState, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // Try to pop current tab's navigator
            final handled = await navigationState.handleSystemBack();
            if (!handled && context.mounted) {
              // Already at root, show exit confirmation or exit
              // For now, just exit. Could show dialog here.
              Navigator.of(context).pop();
            }
          },
          child: ResponsiveUtils.isTabletOrLarger(context)
              ? _buildRailScaffold(navigationState)
              : _buildBottomBarScaffold(navigationState),
        );
      },
    );
  }

  /// Compact window: bottom NavigationBar under the content.
  Widget _buildBottomBarScaffold(NavigationState navigationState) {
    return Scaffold(
      body: _buildBody(navigationState),
      bottomNavigationBar: _buildNavigationBar(navigationState),
    );
  }

  /// Medium/expanded window: NavigationRail beside the content.
  Widget _buildRailScaffold(NavigationState navigationState) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(navigationState),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _buildBody(navigationState)),
        ],
      ),
    );
  }

  Widget _buildBody(NavigationState navigationState) {
    // Use IndexedStack to keep all tab states alive
    return IndexedStack(
      index: navigationState.currentTabIndex,
      children: [
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(0),
          rootScreen: const HomeScreen(),
        ),
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(1),
          rootScreen: const LibraryScreen(),
        ),
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(2),
          rootScreen: const DiscoverScreen(),
        ),
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(3),
          rootScreen: const TransfersScreen(),
        ),
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(4),
          rootScreen: const MoreScreen(),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(NavigationState navigationState) {
    // Colors/elevation/height come from the NavigationBarTheme in AppTheme
    // (surfaceContainer, pill indicator) so the bottom bar matches the
    // NavigationRail used on tablets.
    return NavigationBar(
      selectedIndex: navigationState.currentTabIndex,
      onDestinationSelected: navigationState.changeTab,
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      animationDuration: MD3Durations.medium,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
          tooltip: 'Search and discover archives',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: 'Library',
          tooltip: 'Downloaded content and collections',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
          tooltip: 'Search and explore trending archives',
        ),
        NavigationDestination(
          icon: Icon(Icons.swap_vert_outlined),
          selectedIcon: Icon(Icons.swap_vert),
          label: 'Transfers',
          tooltip: 'Download and upload management',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz),
          label: 'More',
          tooltip: 'Settings and more options',
        ),
      ],
    );
  }

  /// Material 3 NavigationRail for tablet and desktop windows.
  Widget _buildNavigationRail(NavigationState navigationState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extended = ResponsiveUtils.isExpanded(context);

    return NavigationRail(
      selectedIndex: navigationState.currentTabIndex,
      onDestinationSelected: navigationState.changeTab,
      extended: extended,
      minExtendedWidth: 220,
      // Label pills under icons on medium windows; inline labels when the
      // rail is extended (labelType must be null while extended).
      labelType: extended ? null : NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: extended
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_library_outlined,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Internet Archive Helper',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              )
            : Icon(
                Icons.local_library_outlined,
                size: 28,
                color: colorScheme.primary,
              ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: 'Library',
        ),
        NavigationRailDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        NavigationRailDestination(
          icon: Icon(Icons.swap_vert_outlined),
          selectedIcon: Icon(Icons.swap_vert),
          label: 'Transfers',
        ),
        NavigationRailDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }
}

/// Per-tab navigator widget
///
/// Each tab has its own Navigator to maintain independent navigation stacks.
class _TabNavigator extends StatelessWidget {
  const _TabNavigator({required this.navigatorKey, required this.rootScreen});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget rootScreen;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => rootScreen,
          settings: settings,
        );
      },
    );
  }
}
