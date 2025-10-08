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
