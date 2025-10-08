import 'package:flutter/material.dart';

/// Material Design 3 Spacing System
///
/// Provides standardized spacing constants following the Material Design 8dp grid system.
/// All spacing values are multiples of 4dp (half of 8dp) or 8dp to maintain visual consistency.
///
/// Reference: https://m3.material.io/foundations/layout/applying-layout/spacing
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // ============================================================================
  // CORE SPACING SCALE (8dp Grid System)
  // ============================================================================

  /// No spacing (0dp)
  static const double none = 0.0;

  /// Extra extra small spacing (2dp)
  /// Use for: Minimal separation, icon padding within badges
  static const double xxs = 2.0;

  /// Extra small spacing (4dp)
  /// Use for: Tight spacing, small chip padding, badge padding
  static const double xs = 4.0;

  /// Small spacing (8dp) - BASE UNIT
  /// Use for: Standard compact spacing, list item vertical padding
  static const double sm = 8.0;

  /// Medium spacing (12dp)
  /// Use for: Moderate spacing between elements
  static const double md = 12.0;

  /// Large spacing (16dp) - MOST COMMON
  /// Use for: Standard padding for cards, lists, containers
  static const double lg = 16.0;

  /// Extra large spacing (24dp)
  /// Use for: Section padding, dialog content padding
  static const double xl = 24.0;

  /// Extra extra large spacing (32dp)
  /// Use for: Large section separation, prominent spacing
  static const double xxl = 32.0;

  /// Extra extra extra large spacing (40dp)
  /// Use for: Major section breaks, hero element spacing
  static const double xxxl = 40.0;

  // ============================================================================
  // EDGEINSETS OBJECTS (Pre-constructed for better performance)
  // ============================================================================

  // All-sides padding
  static const EdgeInsets allNone = EdgeInsets.all(none);
  static const EdgeInsets allXxs = EdgeInsets.all(xxs);
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);
  static const EdgeInsets allXxxl = EdgeInsets.all(xxxl);

  // Horizontal symmetric padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: xxl);

  // Vertical symmetric padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets verticalXxl = EdgeInsets.symmetric(vertical: xxl);

  // Common combined padding patterns
  static const EdgeInsets cardPadding = EdgeInsets.all(lg); // 16dp all sides
  static const EdgeInsets dialogPadding = EdgeInsets.all(xl); // 24dp all sides
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  ); // 24h × 12v
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  ); // 8h × 4v
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  ); // 16h × 8v
  static const EdgeInsets screenPadding = EdgeInsets.all(lg); // 16dp all sides
  static const EdgeInsets sectionPadding = EdgeInsets.all(xl); // 24dp all sides

  // ============================================================================
  // SIZEDBOX WIDGETS (Vertical/Horizontal Spacing)
  // ============================================================================

  static const SizedBox verticalSpaceXxs = SizedBox(height: xxs);
  static const SizedBox verticalSpaceXs = SizedBox(height: xs);
  static const SizedBox verticalSpaceSm = SizedBox(height: sm);
  static const SizedBox verticalSpaceMd = SizedBox(height: md);
  static const SizedBox verticalSpaceLg = SizedBox(height: lg);
  static const SizedBox verticalSpaceXl = SizedBox(height: xl);
  static const SizedBox verticalSpaceXxl = SizedBox(height: xxl);
  static const SizedBox verticalSpaceXxxl = SizedBox(height: xxxl);

  static const SizedBox horizontalSpaceXxs = SizedBox(width: xxs);
  static const SizedBox horizontalSpaceXs = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSm = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMd = SizedBox(width: md);
  static const SizedBox horizontalSpaceLg = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXl = SizedBox(width: xl);
  static const SizedBox horizontalSpaceXxl = SizedBox(width: xxl);
  static const SizedBox horizontalSpaceXxxl = SizedBox(width: xxxl);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Creates EdgeInsets with custom values (use sparingly, prefer constants)
  static EdgeInsets custom({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    } else if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    } else {
      return EdgeInsets.only(
        left: left ?? 0,
        top: top ?? 0,
        right: right ?? 0,
        bottom: bottom ?? 0,
      );
    }
  }

  /// Creates a vertical SizedBox with custom height
  static SizedBox verticalSpace(double height) => SizedBox(height: height);

  /// Creates a horizontal SizedBox with custom width
  static SizedBox horizontalSpace(double width) => SizedBox(width: width);

  // ============================================================================
  // COMPONENT-SPECIFIC SPACING GUIDELINES
  // ============================================================================

  /// Button padding: 24h × 12v (MD3 specification)
  /// - Filled buttons: 24h × 12v
  /// - Outlined buttons: 24h × 12v
  /// - Text buttons: 12h × 8v (tighter)
  static const EdgeInsets filledButtonPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );
  static const EdgeInsets textButtonPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// Card spacing
  /// - Card padding: 16dp all sides
  /// - Card margin: 8dp between cards
  static const EdgeInsets cardContentPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardMargin = EdgeInsets.all(sm);

  /// List item spacing
  /// - List item padding: 16h × 8v
  /// - List item content padding: 8h × 4v (for nested content)
  static const EdgeInsets listItemContentPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
  static const EdgeInsets listItemNestedPadding = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );

  /// Dialog spacing
  /// - Dialog padding: 24dp all sides
  /// - Dialog title padding: 24dp all sides
  /// - Dialog content padding: 24h × 16v
  static const EdgeInsets dialogContentPadding = EdgeInsets.all(xl);
  static const EdgeInsets dialogTitlePadding = EdgeInsets.all(xl);
  static const EdgeInsets dialogActionPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Screen/Page spacing
  /// - Screen edge padding: 16dp (mobile), 24dp (tablet)
  /// - Section spacing: 24dp
  static const EdgeInsets mobileScreenPadding = EdgeInsets.all(lg);
  static const EdgeInsets tabletScreenPadding = EdgeInsets.all(xl);

  /// Chip/Badge spacing
  /// - Chip padding: 8h × 4v
  /// - Badge padding: 4dp all sides
  static const EdgeInsets badgePadding = EdgeInsets.all(xs);

  /// Input field spacing
  /// - Text field content padding: 16h × 12v
  /// - Text field horizontal padding: 16dp
  static const EdgeInsets textFieldPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // ============================================================================
  // USAGE EXAMPLES
  // ============================================================================

  /// Example usage:
  /// ```dart
  /// // Using pre-defined constants
  /// Container(
  ///   padding: AppSpacing.allLg, // 16dp all sides
  /// )
  ///
  /// // Using component-specific constants
  /// Card(
  ///   margin: AppSpacing.cardMargin,
  ///   child: Padding(
  ///     padding: AppSpacing.cardPadding,
  ///     child: content,
  ///   ),
  /// )
  ///
  /// // Using SizedBox for spacing between widgets
  /// Column(
  ///   children: [
  ///     Widget1(),
  ///     AppSpacing.verticalSpaceMd, // 12dp vertical spacing
  ///     Widget2(),
  ///   ],
  /// )
  ///
  /// // Using custom values (sparingly)
  /// Container(
  ///   padding: AppSpacing.custom(horizontal: 20, vertical: 10),
  /// )
  /// ```
}
