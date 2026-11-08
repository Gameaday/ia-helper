import 'package:flutter/material.dart';

/// Semantic colors for consistent UI patterns across light and dark themes
///
/// This class provides theme-aware colors for common semantic meanings like
/// success, warning, info, etc. Use these instead of hardcoded Colors.* values
/// to ensure proper theme support and accessibility.
class SemanticColors {
  SemanticColors._(); // Private constructor - this is a utility class

  // ============================================================================
  // STATE COLORS (Theme-independent, but carefully chosen for accessibility)
  // ============================================================================

  /// Success state color (green) - use for completed downloads, success messages
  ///
  /// Material Design 3 Green/500 - works in both light and dark themes
  static const Color success = Color(0xFF4CAF50);

  /// Warning/caution state color (orange) - use for warnings, pending states
  ///
  /// Material Design 3 Orange/700 - high contrast in both themes
  static const Color warning = Color(0xFFFB8C00);

  /// Information state color (blue) - use for info messages, progress
  ///
  /// Material Design 3 Blue/500 - accessible in both themes
  static const Color info = Color(0xFF2196F3);

  // ============================================================================
  // THEME-AWARE SEMANTIC VARIANTS
  // ============================================================================
  //
  // The constants above are tuned for light surfaces. These helpers return a
  // lighter tone in dark mode so success, warning, and info stay legible on
  // dark surfaces without washing out.

  /// Success color adapted to the current theme
  ///
  /// Light: deep brand green. Dark: soft green that keeps contrast on ink.
  static Color successOf(BuildContext context) =>
      AppSemanticColors.of(context).success;

  /// Warning color adapted to the current theme
  static Color warningOf(BuildContext context) =>
      AppSemanticColors.of(context).warning;

  /// Info color adapted to the current theme
  static Color infoOf(BuildContext context) =>
      AppSemanticColors.of(context).info;

  // ============================================================================
  // THEME-AWARE COLORS (Get from ColorScheme for proper theme support)
  // ============================================================================

  /// Error color from theme - use for error states, error messages
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// Color for text/icons on error backgrounds
  static Color onError(BuildContext context) =>
      Theme.of(context).colorScheme.onError;

  /// Primary theme color - use for primary actions, emphasis
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Color for text/icons on primary backgrounds
  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  /// Secondary theme color - use for secondary actions
  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  /// Tertiary theme color - use for tertiary actions, warnings
  static Color tertiary(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;

  /// Surface color - use for cards, sheets, dialogs
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Color for text/icons on surface backgrounds
  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  // ============================================================================
  // NEUTRAL/GREY COLORS (Theme-aware opacity-based colors)
  // ============================================================================

  /// Disabled text/icon color (38% opacity)
  ///
  /// Use for disabled buttons, disabled text, inactive states
  /// Material Design 3 spec: 38% opacity for disabled elements
  static Color disabled(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

  /// Hint/placeholder text color (60% opacity)
  ///
  /// Use for text field hints, placeholder text, helper text
  /// Material Design 3 spec: Medium emphasis text
  static Color hint(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Subtitle/secondary text color (60% opacity)
  ///
  /// Use for subtitles, captions, secondary information
  /// Material Design 3 spec: Medium emphasis text
  static Color subtitle(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60);

  /// Border/divider color (12% opacity)
  ///
  /// Use for borders, dividers, separators
  /// Material Design 3 spec: Light emphasis for boundaries
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

  /// Icon color for secondary/non-emphasized icons
  ///
  /// Use for toolbar icons, list item icons, etc.
  static Color iconSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}

/// Semantic state colors as real theme tokens.
///
/// Success, warning, and info have no slots in [ColorScheme], so they are
/// usually hardcoded. Registering this [ThemeExtension] on the app theme
/// makes them first-class: they resolve through [Theme.of], interpolate
/// correctly during light/dark transitions, and can be themed per platform
/// without runtime brightness checks.
///
/// Light values match the brand constants in the Reading Room scheme
/// (`AppTheme.successColor` / `warningColor` / `infoColor`); dark values
/// match the tuned tones the Stacks at Night scheme uses for legibility on
/// ink surfaces.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// Success state: completed downloads, confirmed actions.
  final Color success;

  /// Icons and text drawn on top of [success].
  final Color onSuccess;

  /// Low-emphasis success surface (chips, banners, filled states).
  final Color successContainer;

  /// Icons and text drawn on top of [successContainer].
  final Color onSuccessContainer;

  /// Warning state: pending transfers, recoverable problems.
  final Color warning;

  /// Icons and text drawn on top of [warning].
  final Color onWarning;

  /// Low-emphasis warning surface.
  final Color warningContainer;

  /// Icons and text drawn on top of [warningContainer].
  final Color onWarningContainer;

  /// Information state: tips, neutral progress indicators.
  final Color info;

  /// Icons and text drawn on top of [info].
  final Color onInfo;

  /// Low-emphasis info surface.
  final Color infoContainer;

  /// Icons and text drawn on top of [infoContainer].
  final Color onInfoContainer;

  /// Reading Room (light) semantic palette.
  ///
  /// Deep brand-adjacent tones on paper surfaces: legible in bright light,
  /// containers stay soft so state color never shouts.
  static const AppSemanticColors light = AppSemanticColors(
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFC8E6C9),
    onSuccessContainer: Color(0xFF1B5E20),
    warning: Color(0xFFED6C02),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFE0B2),
    onWarningContainer: Color(0xFFE65100),
    info: Color(0xFF0288D1),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFB3E5FC),
    onInfoContainer: Color(0xFF01579B),
  );

  /// Stacks at Night (dark) semantic palette.
  ///
  /// Lightened tones that hold contrast on ink surfaces, with deep
  /// containers and pale on-container text, mirroring how the dark
  /// ColorScheme pairs container roles.
  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF00390A),
    successContainer: Color(0xFF1B5E20),
    onSuccessContainer: Color(0xFFC8E6C9),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF4A2800),
    warningContainer: Color(0xFF8F5000),
    onWarningContainer: Color(0xFFFFE0B2),
    info: Color(0xFF4FC3F7),
    onInfo: Color(0xFF00344D),
    infoContainer: Color(0xFF0277BD),
    onInfoContainer: Color(0xFFB3E5FC),
  );

  /// Resolves the registered semantic palette for [context], falling back
  /// to the brightness-appropriate constant if the theme has no extension
  /// (for example in widget tests that build a bare `ThemeData`).
  static AppSemanticColors of(BuildContext context) {
    final resolved = Theme.of(context).extension<AppSemanticColors>();
    if (resolved != null) {
      return resolved;
    }
    return Theme.of(context).brightness == Brightness.light
        ? AppSemanticColors.light
        : AppSemanticColors.dark;
  }

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}
