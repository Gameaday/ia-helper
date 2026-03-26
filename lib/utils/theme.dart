import 'package:flutter/material.dart';

/// Internet Archive Helper Material 3 / Material Expressive Theme
///
/// This theme implements Material 3 and Material Expressive design principles
/// with Internet Archive branding colors and modern accessibility standards.
///
/// Material Expressive additions include enhanced component themes for
/// Dialog, BottomSheet, Chip, SnackBar, NavigationBar, SearchBar, Badge,
/// SegmentedButton, and NavigationDrawer.
class AppTheme {
  // Internet Archive brand colors
  static const Color internetArchiveBlue = Color(0xFF004B87);
  static const Color internetArchiveOrange = Color(0xFFFF6B35);
  static const Color internetArchiveGray = Color(0xFF666666);

  // Material 3 color tokens
  static const Color primaryColor = internetArchiveBlue;
  static const Color secondaryColor = internetArchiveOrange;
  static const Color tertiaryColor = Color(0xFF0088CC);

  // Semantic colors
  static const Color successColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color infoColor = Color(0xFF0288D1);

  // Light theme with Material 3 design
  static ThemeData get lightTheme {
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      // Override specific colors for Internet Archive branding
      primary: internetArchiveBlue,
      secondary: internetArchiveOrange,
      tertiary: tertiaryColor,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,

      // App Bar with modern Material 3 styling
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        surfaceTintColor: lightColorScheme.surfaceTint,
        iconTheme: IconThemeData(color: lightColorScheme.onSurface),
      ),

      // Cards with Material 3 styling
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
      ),

      // Filled buttons with Material 3 styling
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input fields with Material 3 styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: lightColorScheme.primary,
        linearTrackColor: lightColorScheme.surfaceContainerHighest,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: lightColorScheme.surface,
        selectedItemColor: lightColorScheme.primary,
        unselectedItemColor: lightColorScheme.onSurfaceVariant,
        elevation: 3,
      ),

      // FAB with Material 3 styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.primaryContainer,
        foregroundColor: lightColorScheme.onPrimaryContainer,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: lightColorScheme.outlineVariant,
        thickness: 1,
      ),

      // Lists
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Material Expressive: Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: lightColorScheme.surfaceContainerHigh,
        elevation: 6,
        titleTextStyle: TextStyle(
          color: lightColorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        contentTextStyle: TextStyle(
          color: lightColorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Material Expressive: Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        backgroundColor: lightColorScheme.surfaceContainerLow,
        surfaceTintColor: lightColorScheme.surfaceTint,
        elevation: 1,
        showDragHandle: true,
        dragHandleColor: lightColorScheme.onSurfaceVariant.withValues(
          alpha: 0.4,
        ),
      ),

      // Material Expressive: Chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: lightColorScheme.outline),
        backgroundColor: lightColorScheme.surface,
        selectedColor: lightColorScheme.secondaryContainer,
        labelStyle: TextStyle(color: lightColorScheme.onSurface),
        secondaryLabelStyle: TextStyle(
          color: lightColorScheme.onSecondaryContainer,
        ),
        showCheckmark: true,
        checkmarkColor: lightColorScheme.onSecondaryContainer,
      ),

      // Material Expressive: SnackBar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: lightColorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: lightColorScheme.onInverseSurface),
        actionTextColor: lightColorScheme.inversePrimary,
        elevation: 6,
      ),

      // Material Expressive: NavigationBar theme (MD3 replacement for BottomNavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightColorScheme.surfaceContainer,
        indicatorColor: lightColorScheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: lightColorScheme.onSecondaryContainer);
          }
          return IconThemeData(color: lightColorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: lightColorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: lightColorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        elevation: 2,
        height: 80,
      ),

      // Material Expressive: NavigationRail theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: lightColorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: lightColorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: lightColorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          color: lightColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: lightColorScheme.onSurfaceVariant,
        ),
        indicatorColor: lightColorScheme.secondaryContainer,
      ),

      // Material Expressive: NavigationDrawer theme
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: lightColorScheme.surfaceContainerLow,
        indicatorColor: lightColorScheme.secondaryContainer,
        elevation: 1,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // Material Expressive: Badge theme
      badgeTheme: BadgeThemeData(
        backgroundColor: lightColorScheme.error,
        textColor: lightColorScheme.onError,
      ),

      // Material Expressive: SegmentedButton theme
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return lightColorScheme.secondaryContainer;
            }
            return lightColorScheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return lightColorScheme.onSecondaryContainer;
            }
            return lightColorScheme.onSurface;
          }),
        ),
      ),

      // Material Expressive: Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lightColorScheme.onPrimary;
          }
          return lightColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lightColorScheme.primary;
          }
          return lightColorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return lightColorScheme.outline;
        }),
      ),

      // Material Expressive: Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: lightColorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(color: lightColorScheme.onInverseSurface),
      ),
    );
  }

  // Dark theme with Material 3 / Material Expressive design
  static ThemeData get darkTheme {
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      // Override specific colors for Internet Archive branding
      primary: const Color(0xFF6BB6FF), // Lighter blue for dark theme
      secondary: internetArchiveOrange,
      tertiary: const Color(0xFF64B5F6),
      error: const Color(0xFFFF5449),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,

      // App Bar with dark theme styling
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        surfaceTintColor: darkColorScheme.surfaceTint,
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
      ),

      // Cards with Material 3 dark styling
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
      ),

      // Filled buttons with Material 3 styling
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input fields with Material 3 dark styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: darkColorScheme.primary,
        linearTrackColor: darkColorScheme.surfaceContainerHighest,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkColorScheme.surface,
        selectedItemColor: darkColorScheme.primary,
        unselectedItemColor: darkColorScheme.onSurfaceVariant,
        elevation: 3,
      ),

      // FAB with Material 3 dark styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColorScheme.primaryContainer,
        foregroundColor: darkColorScheme.onPrimaryContainer,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: darkColorScheme.outlineVariant,
        thickness: 1,
      ),

      // Lists
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Material Expressive: Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: darkColorScheme.surfaceContainerHigh,
        elevation: 6,
        titleTextStyle: TextStyle(
          color: darkColorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        contentTextStyle: TextStyle(
          color: darkColorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Material Expressive: Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        backgroundColor: darkColorScheme.surfaceContainerLow,
        surfaceTintColor: darkColorScheme.surfaceTint,
        elevation: 1,
        showDragHandle: true,
        dragHandleColor: darkColorScheme.onSurfaceVariant.withValues(
          alpha: 0.4,
        ),
      ),

      // Material Expressive: Chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: darkColorScheme.outline),
        backgroundColor: darkColorScheme.surface,
        selectedColor: darkColorScheme.secondaryContainer,
        labelStyle: TextStyle(color: darkColorScheme.onSurface),
        secondaryLabelStyle: TextStyle(
          color: darkColorScheme.onSecondaryContainer,
        ),
        showCheckmark: true,
        checkmarkColor: darkColorScheme.onSecondaryContainer,
      ),

      // Material Expressive: SnackBar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: darkColorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: darkColorScheme.onInverseSurface),
        actionTextColor: darkColorScheme.inversePrimary,
        elevation: 6,
      ),

      // Material Expressive: NavigationBar theme (MD3 replacement for BottomNavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkColorScheme.surfaceContainer,
        indicatorColor: darkColorScheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: darkColorScheme.onSecondaryContainer);
          }
          return IconThemeData(color: darkColorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: darkColorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: darkColorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        elevation: 2,
        height: 80,
      ),

      // Material Expressive: NavigationRail theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkColorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: darkColorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: darkColorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: darkColorScheme.onSurfaceVariant,
        ),
        indicatorColor: darkColorScheme.secondaryContainer,
      ),

      // Material Expressive: NavigationDrawer theme
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: darkColorScheme.surfaceContainerLow,
        indicatorColor: darkColorScheme.secondaryContainer,
        elevation: 1,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // Material Expressive: Badge theme
      badgeTheme: BadgeThemeData(
        backgroundColor: darkColorScheme.error,
        textColor: darkColorScheme.onError,
      ),

      // Material Expressive: SegmentedButton theme
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return darkColorScheme.secondaryContainer;
            }
            return darkColorScheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return darkColorScheme.onSecondaryContainer;
            }
            return darkColorScheme.onSurface;
          }),
        ),
      ),

      // Material Expressive: Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.onPrimary;
          }
          return darkColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.primary;
          }
          return darkColorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return darkColorScheme.outline;
        }),
      ),

      // Material Expressive: Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkColorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(color: darkColorScheme.onInverseSurface),
      ),
    );
  }
}
