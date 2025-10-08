// Material Design 3 Animation Constants
//
// Provides standardized curves, durations, and builders for animations
// throughout the app following Material Design 3 motion guidelines.
//
// References:
// - https://m3.material.io/styles/motion/easing-and-duration/tokens-specs
// - https://m3.material.io/styles/motion/transitions/transition-patterns

import 'package:flutter/material.dart';

/// Material Design 3 Animation Curves
///
/// Use these curves for consistent motion throughout the app.
class MD3Curves {
  MD3Curves._();

  /// Emphasized easing - Used for expressive, distinctive motion
  /// Perfect for: Hero transitions, page transitions, important state changes
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Standard easing - Used for most animations
  /// Perfect for: Widget state changes, list items, minor transitions
  static const Curve standard = Curves.easeInOutCubic;

  /// Decelerate easing - Elements entering the screen
  /// Perfect for: Fade in, slide in, expand
  static const Curve decelerate = Curves.easeOut;

  /// Accelerate easing - Elements exiting the screen
  /// Perfect for: Fade out, slide out, collapse
  static const Curve accelerate = Curves.easeIn;

  /// Linear - Used for continuous, ongoing motion
  /// Perfect for: Progress indicators, loading animations
  static const Curve linear = Curves.linear;
}

/// Material Design 3 Animation Durations
///
/// Standard durations for different types of motion.
class MD3Durations {
  MD3Durations._();

  /// Extra short - 50ms
  /// Use for: Icon state changes, small ripples
  static const Duration extraShort = Duration(milliseconds: 50);

  /// Short - 100ms
  /// Use for: Simple transitions, fade in/out
  static const Duration short = Duration(milliseconds: 100);

  /// Medium - 200ms
  /// Use for: Most transitions, widget state changes
  static const Duration medium = Duration(milliseconds: 200);

  /// Long - 300ms
  /// Use for: Complex transitions, page transitions
  static const Duration long = Duration(milliseconds: 300);

  /// Extra long - 500ms
  /// Use for: Emphasized transitions, hero animations
  static const Duration extraLong = Duration(milliseconds: 500);
}

/// Material Design 3 Page Transitions
///
/// Pre-built page route builders for consistent navigation.
class MD3PageTransitions {
  MD3PageTransitions._();

  /// Fade through transition - Material Design 3 standard
  ///
  /// The incoming page fades in while the outgoing page fades out.
  static PageRouteBuilder<T> fadeThrough<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming page fades in
        final incomingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.35, 1.0, curve: MD3Curves.decelerate),
          ),
        );

        // Scale outgoing page slightly
        final outgoingScale = Tween<double>(begin: 1.0, end: 0.92).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Interval(0.0, 0.35, curve: MD3Curves.emphasized),
          ),
        );

        // Scale incoming page from slightly larger
        final incomingScale = Tween<double>(begin: 1.08, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.35, 1.0, curve: MD3Curves.emphasized),
          ),
        );

        return Stack(
          children: [
            // Outgoing page
            if (secondaryAnimation.status != AnimationStatus.dismissed)
              FadeTransition(
                opacity: ReverseAnimation(secondaryAnimation),
                child: ScaleTransition(scale: outgoingScale, child: child),
              ),
            // Incoming page
            FadeTransition(
              opacity: incomingOpacity,
              child: ScaleTransition(scale: incomingScale, child: child),
            ),
          ],
        );
      },
    );
  }

  /// Shared axis transition - For hierarchical navigation
  ///
  /// Pages slide horizontally with a fade.
  static PageRouteBuilder<T> sharedAxis<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.3, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: MD3Curves.emphasized)),
        );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: MD3Curves.emphasized,
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
    );
  }

  /// Container transform - For element-to-page transitions
  ///
  /// Works with Hero widgets for seamless transitions.
  static PageRouteBuilder<T> containerTransform<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
    Color? backgroundColor,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: backgroundColor ?? Colors.black54,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: MD3Curves.emphasized,
        );

        final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: MD3Curves.emphasized),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }
}

/// Animated list item builder with staggered animation
///
/// Use this for smooth list item appearances.
class StaggeredListAnimation extends StatelessWidget {
  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.child,
    this.duration = MD3Durations.medium,
    this.delay = const Duration(milliseconds: 50),
  });

  final int index;
  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: MD3Curves.decelerate,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Smooth state change animation wrapper
///
/// Wraps any widget with smooth transitions for property changes.
class SmoothStateChange extends StatelessWidget {
  const SmoothStateChange({
    super.key,
    required this.child,
    this.duration = MD3Durations.medium,
    this.curve = MD3Curves.standard,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
