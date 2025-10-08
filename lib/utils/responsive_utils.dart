// Responsive design utilities for tablet and desktop layouts
//
// Material Design 3 breakpoints:
// - Compact: 0-599dp (phones in portrait)
// - Medium: 600-839dp (tablets in portrait, phones in landscape)
// - Expanded: 840dp+ (tablets in landscape, desktops)

import 'package:flutter/material.dart';

class ResponsiveUtils {
  /// Material Design 3 breakpoint for tablet portrait / phone landscape
  static const double tabletBreakpoint = 600.0;

  /// Material Design 3 breakpoint for tablet landscape / desktop
  static const double desktopBreakpoint = 840.0;

  /// Get current screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Check if device is in compact mode (phone portrait)
  static bool isCompact(BuildContext context) {
    return getScreenWidth(context) < tabletBreakpoint;
  }

  /// Check if device is in medium mode (tablet portrait, phone landscape)
  static bool isMedium(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is in expanded mode (tablet landscape, desktop)
  static bool isExpanded(BuildContext context) {
    return getScreenWidth(context) >= desktopBreakpoint;
  }

  /// Check if device is tablet or larger (medium or expanded)
  static bool isTabletOrLarger(BuildContext context) {
    return getScreenWidth(context) >= tabletBreakpoint;
  }

  /// Get number of columns for grid layouts based on screen size
  static int getGridColumns(
    BuildContext context, {
    int compactColumns = 1,
    int mediumColumns = 2,
    int expandedColumns = 3,
  }) {
    if (isExpanded(context)) return expandedColumns;
    if (isMedium(context)) return mediumColumns;
    return compactColumns;
  }

  /// Get master-detail split ratio (for split view layouts)
  /// Returns ratio for master panel (detail will be 1.0 - ratio)
  static double getMasterDetailRatio(BuildContext context) {
    if (isExpanded(context)) return 0.35; // 35% master, 65% detail
    if (isMedium(context)) return 0.4; // 40% master, 60% detail
    return 1.0; // Full screen for compact
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isExpanded(context)) {
      return const EdgeInsets.all(24.0);
    }
    if (isMedium(context)) {
      return const EdgeInsets.all(16.0);
    }
    return const EdgeInsets.all(8.0);
  }

  /// Get responsive card width for constrained layouts
  static double? getMaxCardWidth(BuildContext context) {
    if (isExpanded(context)) {
      return 1200.0; // Max width for desktop
    }
    if (isMedium(context)) {
      return 840.0; // Max width for tablet
    }
    return null; // Full width for phone
  }

  /// Get responsive horizontal spacing
  static double getHorizontalSpacing(BuildContext context) {
    if (isExpanded(context)) return 24.0;
    if (isMedium(context)) return 16.0;
    return 8.0;
  }

  /// Get responsive vertical spacing
  static double getVerticalSpacing(BuildContext context) {
    if (isExpanded(context)) return 16.0;
    if (isMedium(context)) return 12.0;
    return 8.0;
  }

  /// Build a responsive layout with different builders for each size
  static Widget buildResponsive(
    BuildContext context, {
    required WidgetBuilder compactBuilder,
    WidgetBuilder? mediumBuilder,
    WidgetBuilder? expandedBuilder,
  }) {
    if (isExpanded(context) && expandedBuilder != null) {
      return expandedBuilder(context);
    }
    if (isMedium(context) && mediumBuilder != null) {
      return mediumBuilder(context);
    }
    return compactBuilder(context);
  }

  /// Build a master-detail layout for tablet/desktop
  /// Returns a Row with master panel on left and detail panel on right
  static Widget buildMasterDetail(
    BuildContext context, {
    required Widget master,
    required Widget detail,
    bool showDetail = true,
  }) {
    if (!isTabletOrLarger(context) || !showDetail) {
      // On phone or when detail hidden, show only master
      return master;
    }

    final ratio = getMasterDetailRatio(context);

    return Row(
      children: [
        // Master panel (left)
        Expanded(flex: (ratio * 100).round(), child: master),
        // Divider
        Container(width: 1, color: Theme.of(context).dividerColor),
        // Detail panel (right)
        Expanded(flex: ((1.0 - ratio) * 100).round(), child: detail),
      ],
    );
  }

  /// Build a two-column layout for tablet/desktop
  /// Returns Row on tablet+, Column on phone
  static Widget buildTwoColumn(
    BuildContext context, {
    required Widget left,
    required Widget right,
    double? leftFlex,
    double? rightFlex,
  }) {
    if (!isTabletOrLarger(context)) {
      // Single column on phone
      return Column(children: [left, right]);
    }

    // Two columns on tablet+
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex?.round() ?? 1, child: left),
        SizedBox(width: getHorizontalSpacing(context)),
        Expanded(flex: rightFlex?.round() ?? 1, child: right),
      ],
    );
  }

  /// Build a responsive grid
  static Widget buildGrid(
    BuildContext context, {
    required List<Widget> children,
    int? compactColumns,
    int? mediumColumns,
    int? expandedColumns,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
  }) {
    final columns = getGridColumns(
      context,
      compactColumns: compactColumns ?? 1,
      mediumColumns: mediumColumns ?? 2,
      expandedColumns: expandedColumns ?? 3,
    );

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: mainAxisSpacing ?? getVerticalSpacing(context),
      crossAxisSpacing: crossAxisSpacing ?? getHorizontalSpacing(context),
      padding: getScreenPadding(context),
      children: children,
    );
  }
}
