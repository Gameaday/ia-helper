// Widget tests for the adaptive navigation shell (#88).
//
// The shell's root screens are injectable, so these tests pump the real
// BottomNavigationScaffold (real NavigationBar, NavigationRail, IndexedStack,
// NavigationState wiring) with lightweight placeholder screens instead of the
// full screen/service stack.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/core/navigation/bottom_navigation_scaffold.dart';
import 'package:internet_archive_helper/core/navigation/navigation_state.dart';
import 'package:provider/provider.dart';

void main() {
  late NavigationState navigationState;

  /// Pumps the shell inside the providers it needs (just NavigationState)
  /// at the given logical window size (physical size = logical size with a
  /// device pixel ratio of 1.0, so the M3 window-size classes resolve
  /// predictably).
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    navigationState = NavigationState();

    await tester.pumpWidget(
      ChangeNotifierProvider<NavigationState>.value(
        value: navigationState,
        child: MaterialApp(
          home: BottomNavigationScaffold(
            rootScreens: [
              for (var i = 0; i < 5; i++)
                Scaffold(
                  key: ValueKey('tab-$i'),
                  body: Center(child: Text('Tab $i root')),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('compact window uses a NavigationBar with five destinations', (
    WidgetTester tester,
  ) async {
    // Phone portrait: 390 logical dp wide (< 600dp M3 medium breakpoint).
    await pumpShell(tester, logicalSize: const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    // All five destinations are present with their labels (NavigationBar
    // wraps destinations in internal widgets at runtime, so assert on the
    // visible labels rather than the NavigationDestination type).
    for (final label in ['Home', 'Library', 'Discover', 'Transfers', 'More']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byIcon(Icons.home_outlined), findsAtLeastNWidgets(1));
  });

  testWidgets('compact window switches tabs through the bottom bar', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, logicalSize: const Size(390, 844));

    expect(navigationState.currentTabIndex, 0);
    expect(find.text('Tab 0 root'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(navigationState.currentTabIndex, 1);
    expect(find.text('Tab 1 root'), findsOneWidget);
    // IndexedStack keeps the other tabs' state alive off-stage.
    expect(find.text('Tab 0 root', skipOffstage: false), findsOneWidget);
  });

  testWidgets('medium window uses a NavigationRail with label pills', (
    WidgetTester tester,
  ) async {
    // Tablet portrait: 768 logical dp wide (>= 600dp, < 840dp).
    await pumpShell(tester, logicalSize: const Size(768, 1024));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    // Label pills: all five destinations show their labels.
    for (final label in ['Home', 'Library', 'Discover', 'Transfers', 'More']) {
      expect(find.text(label), findsOneWidget);
    }
    // Inline app title only shows on the extended rail.
    expect(find.text('Internet Archive Helper'), findsNothing);
  });

  testWidgets('medium window switches tabs through the rail', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, logicalSize: const Size(768, 1024));

    await tester.tap(find.text('Transfers'));
    await tester.pumpAndSettle();

    expect(navigationState.currentTabIndex, 3);
    expect(find.text('Tab 3 root'), findsOneWidget);
    expect(find.text('Tab 0 root', skipOffstage: false), findsOneWidget);
  });

  testWidgets('expanded window extends the rail with the inline app title', (
    WidgetTester tester,
  ) async {
    // Tablet landscape: 1280 logical dp wide (>= 840dp M3 expanded breakpoint).
    await pumpShell(tester, logicalSize: const Size(1280, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.text('Internet Archive Helper'), findsOneWidget);
    for (final label in ['Home', 'Library', 'Discover', 'Transfers', 'More']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping the current tab keeps the tab selected', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, logicalSize: const Size(768, 1024));

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(navigationState.currentTabIndex, 2);

    // Tapping the already-selected destination pops to root and stays put.
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(navigationState.currentTabIndex, 2);
    expect(find.text('Tab 2 root'), findsOneWidget);
  });
}
