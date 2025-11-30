// lib/core/theme/tokens.dart
import 'package:flutter/material.dart';

/// Design tokens for YS Media Player Pro.
/// Central place for spacing, radii, typography scale, icon sizes, etc.
class YSSpacing {
  const YSSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class YSRadii {
  const YSRadii._();

  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class YSElevation {
  const YSElevation._();

  static const double low = 1;
  static const double mid = 3;
  static const double high = 6;
}

class YSIconSizes {
  const YSIconSizes._();

  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;

}

/// Extension on ThemeData to expose YS design tokens easily.
extension YSThemeExt on ThemeData {
  YSSpacing get space => const YSSpacing._();
  YSRadii get radius => const YSRadii._();
  YSElevation get elevation => const YSElevation._();
  YSIconSizes get icons => const YSIconSizes._();
}
