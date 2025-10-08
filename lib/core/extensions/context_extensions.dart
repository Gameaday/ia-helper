import 'package:flutter/material.dart';
import '../../utils/animation_constants.dart';

/// Material Design 3 transition types for navigation
enum MD3TransitionType {
  /// Fade through transition for forward navigation (default)
  fadeThrough,
  /// Shared axis transition for lateral navigation
  sharedAxis,
  /// Container transform for element-to-page transitions
  containerTransform,
}

/// BuildContext extensions for easier access to common properties
extension ContextExtensions on BuildContext {
  /// Returns Theme.of(context)
  ThemeData get theme => Theme.of(this);

  /// Returns Theme.of(context).textTheme
  TextTheme get textTheme => theme.textTheme;

  /// Returns Theme.of(context).colorScheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns MediaQuery.of(context)
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns screen size
  Size get screenSize => mediaQuery.size;

  /// Returns screen width
  double get screenWidth => screenSize.width;

  /// Returns screen height
  double get screenHeight => screenSize.height;

  /// Returns Navigator.of(context)
  NavigatorState get navigator => Navigator.of(this);

  /// Checks if device is in landscape mode
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  /// Checks if device is in portrait mode
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  /// Hides keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Shows snackbar with message
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  /// Navigates to route with Material Design 3 transitions
  /// 
  /// Uses fadeThrough by default (forward navigation).
  /// Use [transitionType] to specify sharedAxis (lateral) or containerTransform.
  Future<T?> push<T>(
    Widget page, {
    MD3TransitionType transitionType = MD3TransitionType.fadeThrough,
    RouteSettings? settings,
  }) {
    final Route<T> route;
    
    switch (transitionType) {
      case MD3TransitionType.fadeThrough:
        route = MD3PageTransitions.fadeThrough(page: page, settings: settings);
        break;
      case MD3TransitionType.sharedAxis:
        route = MD3PageTransitions.sharedAxis(page: page, settings: settings);
        break;
      case MD3TransitionType.containerTransform:
        route = MD3PageTransitions.containerTransform(page: page, settings: settings);
        break;
    }
    
    return navigator.push<T>(route);
  }

  /// Convenience method for fadeThrough transition (forward navigation)
  Future<T?> pushFade<T>(Widget page, {RouteSettings? settings}) {
    return push<T>(page, transitionType: MD3TransitionType.fadeThrough, settings: settings);
  }

  /// Convenience method for sharedAxis transition (lateral navigation)
  Future<T?> pushShared<T>(Widget page, {RouteSettings? settings}) {
    return push<T>(page, transitionType: MD3TransitionType.sharedAxis, settings: settings);
  }

  /// Convenience method for containerTransform transition (element-to-page)
  Future<T?> pushTransform<T>(Widget page, {RouteSettings? settings}) {
    return push<T>(page, transitionType: MD3TransitionType.containerTransform, settings: settings);
  }

  /// Pops current route
  void pop<T>([T? result]) {
    navigator.pop(result);
  }
}
