// lib/core/utils/layout_utils.dart
import 'package:flutter/material.dart';

/// Layout & breakpoint helpers for adaptive UI.

class LayoutUtils {
  const LayoutUtils._();

  /// Basic width-based breakpoints.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.shortestSide;
    return width >= 600;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Suggested grid columns for given width.
  static int gridColumnsForWidth(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  /// Default horizontal padding depending on form factor.
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  }
}
