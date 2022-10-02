import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';
import 'package:sweyer/constants.dart' as constants;

import '../colors.dart';

part 'app_theme.tailor.dart';

@tailor
class _$AppTheme {
  /// Primary application color adjusted for blending into album arts.
  static final artColorForBlend = [
    ContentArt.getColorToBlendInDefaultArt(constants.Theme.defaultPrimaryColor),
    ContentArt.getColorToBlendInDefaultArt(constants.Theme.defaultPrimaryColor),
  ];

  static final sliderInactiveColor = [
    Colors.black.withOpacity(0.2),
    Colors.white.withOpacity(0.2),
  ];

  static const appBarBorderColor = [
    AppColors.eee,
    Color(0xff191b1a),
  ];

  static const drawerMenuItemColor = [
    Color(0xff3d3e42),
    Colors.white,
  ];

  /// Color that contrasts with the [ColorScheme.background].
  /// Black and white.
  static const contrast = [
    Colors.black,
    Colors.white,
  ];

  static const contrastInverse = [
    Colors.white,
    Colors.black,
  ];

  /// Additional "glow" splash color aside of the one I put into the [ThemeData.splashColor],
  /// that is the primary splash of the application (see [app]).
  ///
  /// In light mode it's the same as the mentioned above primary splash color.
  ///
  /// This color can be used instead of the [ThemeData.splashColor]
  /// for creating splashes over sold colors (because otherwise splash will be indistinguishable from the color
  /// it's drawn over).
  ///
  /// For example, it can be used for better look of splashes over the primary color in dark mode.
  static final glowSplashColor = [
    constants.Theme.lightThemeSplashColor,
    Colors.white.withOpacity(0.1),
  ];

  /// A [glowSplashColor] to draw over contrasting colors, like primary or [contrast].
  static final glowSplashColorOnContrast = [
    Colors.white.withOpacity(0.13),
    Colors.black.withOpacity(0.13),
  ];
}
