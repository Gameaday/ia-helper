// Automated WCAG 2.1 contrast checks for both IA Helper themes (#88).
//
// Material 3 pairs that carry text are asserted against the AA threshold
// (4.5:1); component/border pairs against the component threshold (3:1).
// If a future palette tweak regresses any pair, this test names it.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/utils/theme.dart';

/// WCAG 2.1 relative luminance of a color.
double _luminance(Color c) {
  double channel(double s) {
    return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 2.1 contrast ratio between two colors (>= 1.0).
double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  void expectPair(
    String name,
    Color foreground,
    Color background,
    double minRatio,
  ) {
    final ratio = _contrast(foreground, background);
    expect(
      ratio >= minRatio,
      isTrue,
      reason:
          '$name: contrast ${ratio.toStringAsFixed(2)} '
          'is below the required $minRatio',
    );
  }

  test('Reading Room (light) scheme meets WCAG AA contrast', () {
    final scheme = AppTheme.lightScheme;

    // Body text on surfaces.
    expectPair('onSurface/surface', scheme.onSurface, scheme.surface, 4.5);
    expectPair(
      'onSurfaceVariant/surface',
      scheme.onSurfaceVariant,
      scheme.surface,
      4.5,
    );
    expectPair(
      'onSurface/surfaceContainerLow (cards)',
      scheme.onSurface,
      scheme.surfaceContainerLow,
      4.5,
    );
    expectPair(
      'onSurface/surfaceContainer (navigation bar)',
      scheme.onSurface,
      scheme.surfaceContainer,
      4.5,
    );
    expectPair(
      'onSurface/surfaceContainerHigh (dialogs)',
      scheme.onSurface,
      scheme.surfaceContainerHigh,
      4.5,
    );
    expectPair(
      'onSurfaceVariant/surfaceContainerHigh (dialog content)',
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHigh,
      4.5,
    );

    // On-color pairs.
    expectPair('onPrimary/primary', scheme.onPrimary, scheme.primary, 4.5);
    expectPair(
      'onPrimaryContainer/primaryContainer',
      scheme.onPrimaryContainer,
      scheme.primaryContainer,
      4.5,
    );
    expectPair(
      'onSecondaryContainer/secondaryContainer (nav indicator)',
      scheme.onSecondaryContainer,
      scheme.secondaryContainer,
      4.5,
    );
    expectPair(
      'onTertiaryContainer/tertiaryContainer',
      scheme.onTertiaryContainer,
      scheme.tertiaryContainer,
      4.5,
    );
    expectPair('onError/error', scheme.onError, scheme.error, 4.5);
    expectPair(
      'onErrorContainer/errorContainer',
      scheme.onErrorContainer,
      scheme.errorContainer,
      4.5,
    );

    // Accent text on plain surfaces (tab labels, links, emphasis).
    expectPair('primary/surface', scheme.primary, scheme.surface, 4.5);
    expectPair('secondary/surface', scheme.secondary, scheme.surface, 4.5);

    // Snackbars (inverse colors).
    expectPair(
      'onInverseSurface/inverseSurface',
      scheme.onInverseSurface,
      scheme.inverseSurface,
      4.5,
    );
    expectPair(
      'inversePrimary/inverseSurface (snackbar action)',
      scheme.inversePrimary,
      scheme.inverseSurface,
      4.5,
    );

    // Component boundary (checkbox/radio outlines): 3:1.
    expectPair('outline/surface (3:1 component)', scheme.outline, scheme.surface, 3.0);
  });

  test('Stacks at Night (dark) scheme meets WCAG AA contrast', () {
    final scheme = AppTheme.darkScheme;

    // Body text on surfaces.
    expectPair('onSurface/surface', scheme.onSurface, scheme.surface, 4.5);
    expectPair(
      'onSurfaceVariant/surface',
      scheme.onSurfaceVariant,
      scheme.surface,
      4.5,
    );
    expectPair(
      'onSurface/surfaceContainerLow (cards)',
      scheme.onSurface,
      scheme.surfaceContainerLow,
      4.5,
    );
    expectPair(
      'onSurface/surfaceContainer (navigation bar)',
      scheme.onSurface,
      scheme.surfaceContainer,
      4.5,
    );
    expectPair(
      'onSurface/surfaceContainerHigh (dialogs)',
      scheme.onSurface,
      scheme.surfaceContainerHigh,
      4.5,
    );
    expectPair(
      'onSurfaceVariant/surfaceContainerHigh (dialog content)',
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHigh,
      4.5,
    );

    // On-color pairs.
    expectPair('onPrimary/primary', scheme.onPrimary, scheme.primary, 4.5);
    expectPair(
      'onPrimaryContainer/primaryContainer',
      scheme.onPrimaryContainer,
      scheme.primaryContainer,
      4.5,
    );
    expectPair(
      'onSecondaryContainer/secondaryContainer (nav indicator)',
      scheme.onSecondaryContainer,
      scheme.secondaryContainer,
      4.5,
    );
    expectPair(
      'onTertiaryContainer/tertiaryContainer',
      scheme.onTertiaryContainer,
      scheme.tertiaryContainer,
      4.5,
    );
    expectPair('onError/error', scheme.onError, scheme.error, 4.5);
    expectPair(
      'onErrorContainer/errorContainer',
      scheme.onErrorContainer,
      scheme.errorContainer,
      4.5,
    );

    // Accent text on plain surfaces (tab labels, links, emphasis).
    expectPair('primary/surface', scheme.primary, scheme.surface, 4.5);
    expectPair('secondary/surface', scheme.secondary, scheme.surface, 4.5);

    // Snackbars (inverse colors).
    expectPair(
      'onInverseSurface/inverseSurface',
      scheme.onInverseSurface,
      scheme.inverseSurface,
      4.5,
    );
    expectPair(
      'inversePrimary/inverseSurface (snackbar action)',
      scheme.inversePrimary,
      scheme.inverseSurface,
      4.5,
    );

    // Component boundary (checkbox/radio outlines): 3:1.
    expectPair('outline/surface (3:1 component)', scheme.outline, scheme.surface, 3.0);
  });
}
