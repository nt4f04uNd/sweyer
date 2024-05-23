import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';
import 'package:sweyer/constants.dart' as constants;

import '../colors.dart';

part 'app_theme.tailor.dart';

@TailorMixin()
class AppTheme extends ThemeExtension<AppTheme> with _$AppThemeTailorMixin {
  const AppTheme({
    required this.artColorForBlend,
    required this.currentIndicatorBackgroundColorWithDefaultArt,
    required this.sliderInactiveColor,
    required this.appBarBorderColor,
    required this.drawerMenuItemColor,
    required this.contrast,
    required this.contrastInverse,
    required this.glowSplashColor,
    required this.glowSplashColorOnContrast,
  });

  /// Primary application color adjusted for blending into album arts.
  @override
  final Color artColorForBlend;
  @override
  final Color currentIndicatorBackgroundColorWithDefaultArt;
  @override
  final Color sliderInactiveColor;
  @override
  final Color appBarBorderColor;
  @override
  final Color drawerMenuItemColor;

  /// Color that contrasts with the [ColorScheme.surface].
  /// Black and white.
  @override
  final Color contrast;
  @override
  final Color contrastInverse;

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
  @override
  final Color glowSplashColor;

  /// A [glowSplashColor] to draw over contrasting colors, like primary or [contrast].
  @override
  final Color glowSplashColorOnContrast;

  static final AppTheme light = AppTheme(
    appBarBorderColor: AppColors.eee,
    artColorForBlend: ContentArt.getColorToBlendInDefaultArt(constants.Theme.defaultPrimaryColor),
    contrast: Colors.black,
    contrastInverse: Colors.white,
    currentIndicatorBackgroundColorWithDefaultArt: constants.Theme.defaultPrimaryColor,
    drawerMenuItemColor: const Color(0xff3d3e42),
    glowSplashColor: constants.Theme.lightThemeSplashColor,
    glowSplashColorOnContrast: Colors.white.withOpacity(0.13),
    sliderInactiveColor: Colors.black.withOpacity(0.2),
  );

  static final AppTheme dark = AppTheme(
    appBarBorderColor: const Color(0xff191b1a),
    artColorForBlend: ContentArt.getColorToBlendInDefaultArt(constants.Theme.defaultPrimaryColor),
    contrast: Colors.white,
    contrastInverse: Colors.black,
    currentIndicatorBackgroundColorWithDefaultArt: constants.Theme.defaultPrimaryColor,
    drawerMenuItemColor: Colors.white,
    glowSplashColor: Colors.white.withOpacity(0.1),
    glowSplashColorOnContrast: Colors.white.withOpacity(0.13),
    sliderInactiveColor: Colors.white.withOpacity(0.2),
  );
}
