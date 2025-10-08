import 'package:flutter/material.dart';

/// Material Design 3 compliant navigation state management
///
/// Manages the bottom navigation bar state and per-tab navigation stacks.
/// Each tab maintains its own navigation history using separate navigator keys.
///
/// Features:
/// - 5-tab bottom navigation (Home, Library, Favorites, Transfers, Settings)
/// - Per-tab navigation stacks with state preservation
/// - Tap current tab to pop to root
/// - Deep linking support
/// - State restoration
class NavigationState extends ChangeNotifier {
  int _currentTabIndex = 0;

  /// Navigator keys for each tab to maintain separate navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(debugLabel: 'HomeNavigator'),
    GlobalKey<NavigatorState>(debugLabel: 'LibraryNavigator'),
    GlobalKey<NavigatorState>(debugLabel: 'FavoritesNavigator'),
    GlobalKey<NavigatorState>(debugLabel: 'TransfersNavigator'),
    GlobalKey<NavigatorState>(debugLabel: 'SettingsNavigator'),
  ];

  /// Current selected tab index (0-4)
  int get currentTabIndex => _currentTabIndex;

  /// Navigator key for current tab
  GlobalKey<NavigatorState> get currentNavigatorKey =>
      _navigatorKeys[_currentTabIndex];

  /// Get navigator key for specific tab
  GlobalKey<NavigatorState> getNavigatorKey(int index) {
    if (index < 0 || index >= _navigatorKeys.length) {
      throw RangeError('Tab index $index is out of range');
    }
    return _navigatorKeys[index];
  }

  /// Change to a different tab
  ///
  /// If tapping the current tab, pops to root of that tab's navigation stack.
  /// Otherwise, switches to the new tab and preserves its navigation state.
  void changeTab(int index) {
    if (index < 0 || index >= _navigatorKeys.length) {
      throw RangeError('Tab index $index is out of range');
    }

    if (index == _currentTabIndex) {
      // Tap on current tab - pop to root
      popToRoot();
    } else {
      // Switch to different tab
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// Pop to root of current tab's navigation stack
  void popToRoot() {
    final navigator = currentNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  /// Pop to root of specific tab
  void popToRootOfTab(int index) {
    final navigator = getNavigatorKey(index).currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  /// Check if current tab can pop
  bool get canPop {
    final navigator = currentNavigatorKey.currentState;
    return navigator?.canPop() ?? false;
  }

  /// Check if specific tab can pop
  bool canPopTab(int index) {
    final navigator = getNavigatorKey(index).currentState;
    return navigator?.canPop() ?? false;
  }

  /// Handle system back button
  ///
  /// Returns true if back was handled (popped a route in current tab),
  /// false if should exit app (already at root of tab).
  Future<bool> handleSystemBack() async {
    final navigator = currentNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return true; // Back was handled
    }
    return false; // Should exit app
  }

  /// Navigate to specific tab and optionally push a route
  void navigateToTab(int index, {Widget? pushRoute}) {
    if (index < 0 || index >= _navigatorKeys.length) {
      throw RangeError('Tab index $index is out of range');
    }

    _currentTabIndex = index;
    notifyListeners();

    if (pushRoute != null) {
      // Wait for navigation to settle, then push route
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = getNavigatorKey(index).currentState;
        if (navigator != null) {
          navigator.push(MaterialPageRoute(builder: (_) => pushRoute));
        }
      });
    }
  }

  /// Tab indices for easy reference
  static const int homeTab = 0;
  static const int libraryTab = 1;
  static const int favoritesTab = 2;
  static const int transfersTab = 3;
  static const int settingsTab = 4;

  @override
  void dispose() {
    // Navigator keys are managed by framework, no need to dispose
    super.dispose();
  }
}
