// Material Design 3 Shape System
//
// Provides standardized border radius values following Material Design 3
// shape scale for consistent shapes throughout the app.
//
// Reference: https://m3.material.io/styles/shape/shape-scale-tokens

import 'package:flutter/material.dart';

/// Material Design 3 Shape Scale
///
/// Use these constants for all border radius throughout the app.
class AppShapes {
  AppShapes._();

  // ========== Corner Radius Values ==========

  /// Extra Small - 4dp
  /// Use for: Small chips, badges, avatars
  static const double extraSmallRadius = 4.0;

  /// Small - 8dp
  /// Use for: Buttons, small cards, input fields
  static const double smallRadius = 8.0;

  /// Medium - 12dp
  /// Use for: Cards, dialogs, bottom sheets
  static const double mediumRadius = 12.0;

  /// Large - 16dp
  /// Use for: Large cards, extended FAB
  static const double largeRadius = 16.0;

  /// Extra Large - 28dp
  /// Use for: Extra large containers, hero elements
  static const double extraLargeRadius = 28.0;

  // ========== BorderRadius Objects ==========

  /// Extra Small BorderRadius (4dp)
  static const BorderRadius extraSmall = BorderRadius.all(
    Radius.circular(extraSmallRadius),
  );

  /// Small BorderRadius (8dp)
  static const BorderRadius small = BorderRadius.all(
    Radius.circular(smallRadius),
  );

  /// Medium BorderRadius (12dp)
  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(mediumRadius),
  );

  /// Large BorderRadius (16dp)
  static const BorderRadius large = BorderRadius.all(
    Radius.circular(largeRadius),
  );

  /// Extra Large BorderRadius (28dp)
  static const BorderRadius extraLarge = BorderRadius.all(
    Radius.circular(extraLargeRadius),
  );

  // ========== Circular Radius Objects ==========

  /// Extra Small Circular Radius (4dp)
  static const Radius circularExtraSmall = Radius.circular(extraSmallRadius);

  /// Small Circular Radius (8dp)
  static const Radius circularSmall = Radius.circular(smallRadius);

  /// Medium Circular Radius (12dp)
  static const Radius circularMedium = Radius.circular(mediumRadius);

  /// Large Circular Radius (16dp)
  static const Radius circularLarge = Radius.circular(largeRadius);

  /// Extra Large Circular Radius (28dp)
  static const Radius circularExtraLarge = Radius.circular(extraLargeRadius);

  // ========== Top-only BorderRadius ==========

  /// Extra Small Top Corners (4dp)
  static const BorderRadius topExtraSmall = BorderRadius.only(
    topLeft: circularExtraSmall,
    topRight: circularExtraSmall,
  );

  /// Small Top Corners (8dp)
  static const BorderRadius topSmall = BorderRadius.only(
    topLeft: circularSmall,
    topRight: circularSmall,
  );

  /// Medium Top Corners (12dp)
  static const BorderRadius topMedium = BorderRadius.only(
    topLeft: circularMedium,
    topRight: circularMedium,
  );

  /// Large Top Corners (16dp)
  static const BorderRadius topLarge = BorderRadius.only(
    topLeft: circularLarge,
    topRight: circularLarge,
  );

  /// Extra Large Top Corners (28dp)
  static const BorderRadius topExtraLarge = BorderRadius.only(
    topLeft: circularExtraLarge,
    topRight: circularExtraLarge,
  );

  // ========== Bottom-only BorderRadius ==========

  /// Extra Small Bottom Corners (4dp)
  static const BorderRadius bottomExtraSmall = BorderRadius.only(
    bottomLeft: circularExtraSmall,
    bottomRight: circularExtraSmall,
  );

  /// Small Bottom Corners (8dp)
  static const BorderRadius bottomSmall = BorderRadius.only(
    bottomLeft: circularSmall,
    bottomRight: circularSmall,
  );

  /// Medium Bottom Corners (12dp)
  static const BorderRadius bottomMedium = BorderRadius.only(
    bottomLeft: circularMedium,
    bottomRight: circularMedium,
  );

  /// Large Bottom Corners (16dp)
  static const BorderRadius bottomLarge = BorderRadius.only(
    bottomLeft: circularLarge,
    bottomRight: circularLarge,
  );

  /// Extra Large Bottom Corners (28dp)
  static const BorderRadius bottomExtraLarge = BorderRadius.only(
    bottomLeft: circularExtraLarge,
    bottomRight: circularExtraLarge,
  );

  // ========== Shape Theme Helpers ==========

  /// Get RoundedRectangleBorder for buttons, cards, etc.
  static RoundedRectangleBorder getRoundedRectangleBorder({
    required double radius,
    BorderSide side = BorderSide.none,
  }) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: side,
    );
  }

  /// Get CircleBorder for FAB, avatars, etc.
  static const CircleBorder circle = CircleBorder();

  /// Get StadiumBorder for pills, chips
  static const StadiumBorder stadium = StadiumBorder();
}

/// Material Design 3 Shape Scale Guidelines
///
/// Component recommendations:
///
/// **Extra Small (4dp):**
/// - Badges
/// - Small chips
/// - Small avatars
/// - Status indicators
///
/// **Small (8dp):**
/// - Buttons (text, outlined, filled)
/// - Input fields
/// - Small cards
/// - Dropdown menus
///
/// **Medium (12dp):**
/// - Cards
/// - Dialogs
/// - Bottom sheets
/// - Navigation rail
/// - Snackbars
///
/// **Large (16dp):**
/// - Large cards
/// - Extended FAB
/// - Top app bar (if rounded)
/// - Large chips
///
/// **Extra Large (28dp):**
/// - Extra large containers
/// - Hero elements
/// - Full-screen dialogs (top corners)
