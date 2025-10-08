import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/home_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/settings_screen.dart';
import '../../utils/animation_constants.dart';
import 'navigation_state.dart';

/// Material Design 3 bottom navigation scaffold
///
/// Implements a 5-tab bottom navigation bar with per-tab navigation stacks.
/// Each tab maintains its own navigation history and state.
///
/// Tabs:
/// 0. 🏠 Home - Search and discovery
/// 1. 📚 Library - Downloaded content and collections
/// 2. ⭐ Favorites - Starred archives
/// 3. 🔄 Transfers - Download/upload management
/// 4. ⚙️ Settings - App configuration
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
          rootScreen: _buildLibraryPlaceholder(),
        ),
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(2),
          rootScreen: const FavoritesScreen(),
        ),
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(3),
          rootScreen: _buildTransfersPlaceholder(),
        ),
        _TabNavigator(
          navigatorKey: navigationState.getNavigatorKey(4),
          rootScreen: const SettingsScreen(),
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
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favorites',
          tooltip: 'Starred archives',
        ),
        NavigationDestination(
          icon: Icon(Icons.swap_vert_outlined),
          selectedIcon: Icon(Icons.swap_vert),
          label: 'Transfers',
          tooltip: 'Download and upload management',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
          tooltip: 'App configuration',
        ),
      ],
    );
  }

  // Temporary placeholders until we create the actual screens
  Widget _buildLibraryPlaceholder() {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Library Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon in Phase 2',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransfersPlaceholder() {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfers')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_vert, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Transfers Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon in Phase 2',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
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
