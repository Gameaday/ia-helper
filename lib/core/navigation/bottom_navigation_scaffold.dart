import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/home_screen.dart';
import '../../screens/library_screen.dart';
import '../../screens/discover_screen.dart';
import '../../screens/transfers_screen.dart';
import '../../screens/more_screen.dart';
import '../../utils/animation_constants.dart';
import 'navigation_state.dart';

/// Material Design 3 bottom navigation scaffold
///
/// Implements a 5-tab bottom navigation bar with per-tab navigation stacks.
/// Each tab maintains its own navigation history and state.
///
/// Tabs:
/// 0. 🏠 Home - Quick identifier search
/// 1. 📚 Library - Downloads, collections, and favorites
/// 2. 🔍 Discover - Keyword search and trending content
/// 3. 🔄 Transfers - Download/upload management
/// 4. ⋯ More - Settings and additional options
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
          child: Scaffold(
            body: _buildBody(navigationState),
            bottomNavigationBar: _buildNavigationBar(navigationState),
          ),
        );
      },
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
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: navigationState.currentTabIndex,
      onDestinationSelected: navigationState.changeTab,
      backgroundColor: colorScheme.surface,
      elevation: 3,
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
