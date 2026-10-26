import 'package:flutter/material.dart';

/// Internet Archive Helper Material 3 Expressive Theme
///
/// This theme implements Material 3 Expressive design principles with a
/// hand-authored Internet Archive identity. Two purpose-built color schemes
/// define the brand:
///
/// - **Reading Room** (light): warm paper surfaces, deep Internet Archive
///   ink blue, burnt-orange wayfinding, and teal accents.
/// - **Stacks at Night** (dark): blue-ink surfaces instead of flat grey, with
///   lantern-warm secondary tones that stay legible after dark.
///
/// The schemes are hand-authored rather than seed-generated so the brand reads
/// the same on every device instead of drifting toward device wallpaper tones.
///
/// Light and dark themes are built from a single [_buildTheme] helper so both
/// brightness modes stay perfectly symmetric. Component coverage includes
/// AppBar, Card, all button variants (filled, elevated, text, outlined),
/// InputDecorator, TabBar, Checkbox, Radio, Switch, Slider, Dialog,
/// BottomSheet, Chip, SnackBar, NavigationBar, NavigationRail, NavigationDrawer,
/// Badge, SegmentedButton, SearchBar, SearchView, PopupMenu, DropdownMenu,
/// MenuButton, Tooltip, FAB, ListTile, Divider, and ProgressIndicator.
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

  /// **Reading Room** light scheme: warm paper, IA ink blue, burnt orange.
  ///
  /// Hand-authored so the palette is the brand, not a seed algorithm's guess.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF004B87),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD5E3F7),
    onPrimaryContainer: Color(0xFF002E52),
    secondary: Color(0xFFB9480F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDCC2),
    onSecondaryContainer: Color(0xFF4A2000),
    tertiary: Color(0xFF00696E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF9CEDEE),
    onTertiaryContainer: Color(0xFF00363A),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFCF8F1),
    onSurface: Color(0xFF1D1B16),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F2E9),
    surfaceContainer: Color(0xFFF1ECE2),
    surfaceContainerHigh: Color(0xFFECE7DC),
    surfaceContainerHighest: Color(0xFFE6E1D6),
    surfaceDim: Color(0xFFDED9CE),
    surfaceBright: Color(0xFFFCF8F1),
    onSurfaceVariant: Color(0xFF4A463F),
    outline: Color(0xFF7B776E),
    outlineVariant: Color(0xFFCDC8BB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF322F27),
    onInverseSurface: Color(0xFFF5F0E6),
    inversePrimary: Color(0xFFA8C8F0),
    surfaceTint: Color(0xFF004B87),
  );

  /// **Stacks at Night** dark scheme: blue-ink surfaces, never flat grey.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA3C9F0),
    onPrimary: Color(0xFF00325C),
    primaryContainer: Color(0xFF1B4A7A),
    onPrimaryContainer: Color(0xFFD5E3F7),
    secondary: Color(0xFFFFB68C),
    onSecondary: Color(0xFF572400),
    secondaryContainer: Color(0xFF7E3B0D),
    onSecondaryContainer: Color(0xFFFFDCC2),
    tertiary: Color(0xFF80D4D8),
    onTertiary: Color(0xFF00363A),
    tertiaryContainer: Color(0xFF004F54),
    onTertiaryContainer: Color(0xFF9CEDEE),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF15181F),
    onSurface: Color(0xFFE4E1D9),
    surfaceContainerLowest: Color(0xFF0F1217),
    surfaceContainerLow: Color(0xFF1D2027),
    surfaceContainer: Color(0xFF21252D),
    surfaceContainerHigh: Color(0xFF262B33),
    surfaceContainerHighest: Color(0xFF2B3039),
    surfaceDim: Color(0xFF15181F),
    surfaceBright: Color(0xFF3B3F48),
    onSurfaceVariant: Color(0xFFC7C5BD),
    outline: Color(0xFF918F87),
    outlineVariant: Color(0xFF464844),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE4E1D9),
    onInverseSurface: Color(0xFF31302B),
    inversePrimary: Color(0xFF004B87),
    surfaceTint: Color(0xFFA3C9F0),
  );

  // Light theme: the Reading Room
  static ThemeData get lightTheme => _buildTheme(lightScheme);

  // Dark theme: Stacks at Night
  static ThemeData get darkTheme => _buildTheme(darkScheme);

  /// Expressive type ramp: confident, slightly tight display and headline
  /// styles with semibold weights, so screens feel designed at any size.
  static TextTheme _expressiveTextTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }

  /// Builds a complete Material 3 Expressive [ThemeData] from [colorScheme],
  /// keeping light and dark modes structurally identical.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _expressiveTextTheme(colorScheme.brightness),

      // App Bar with Material 3 Expressive styling
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards rest flat on tinted paper with generous 20dp corners
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.hardEdge,
      ),

      // Filled buttons: full-pill shapes with confident labels
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input fields: soft filled wells that focus with a bold ink ring
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Bottom navigation (legacy widget support)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 3,
      ),

      // FAB with Material 3 Expressive styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),

      // Lists
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),

      // Material Expressive: Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 6,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Material Expressive: Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 1,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(
          alpha: 0.4,
        ),
      ),

      // Material Expressive: Chip theme, pills without fussy outlines
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onSecondaryContainer,
        ),
        showCheckmark: true,
        checkmarkColor: colorScheme.onSecondaryContainer,
      ),

      // Material Expressive: SnackBar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
        elevation: 6,
      ),

      // Material 3: Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        dividerColor: colorScheme.outlineVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Material 3: Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Material 3: Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // Material Expressive: Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline;
        }),
      ),

      // Material 3: Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        trackHeight: 4,
      ),

      // Material Expressive: NavigationBar theme
      // (MD3 replacement for BottomNavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onSecondaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        elevation: 2,
        height: 80,
      ),

      // Material Expressive: NavigationRail theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        indicatorColor: colorScheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
      ),

      // Material Expressive: NavigationDrawer theme
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 1,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // Material Expressive: Badge theme
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
      ),

      // Material Expressive: SegmentedButton theme
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.secondaryContainer;
            }
            return colorScheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onSecondaryContainer;
            }
            return colorScheme.onSurface;
          }),
        ),
      ),

      // Material Expressive: SearchBar theme
      searchBarTheme: SearchBarThemeData(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface),
        ),
      ),

      // Material Expressive: SearchView theme
      searchViewTheme: SearchViewThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        dividerColor: colorScheme.outlineVariant,
      ),

      // Material 3: PopupMenu theme
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),

      // Material 3: DropdownMenu theme
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
          elevation: const WidgetStatePropertyAll(2),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),

      // Material 3: MenuButton theme
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHigh,
          foregroundColor: colorScheme.onSurface,
        ),
      ),

      // Material Expressive: Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }
}
