// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element, unnecessary_cast

part of 'app_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppThemeTailorMixin on ThemeExtension<AppTheme> {
  Color get artColorForBlend;
  Color get currentIndicatorBackgroundColorWithDefaultArt;
  Color get sliderInactiveColor;
  Color get appBarBorderColor;
  Color get drawerMenuItemColor;
  Color get contrast;
  Color get contrastInverse;
  Color get glowSplashColor;
  Color get glowSplashColorOnContrast;

  @override
  AppTheme copyWith({
    Color? artColorForBlend,
    Color? currentIndicatorBackgroundColorWithDefaultArt,
    Color? sliderInactiveColor,
    Color? appBarBorderColor,
    Color? drawerMenuItemColor,
    Color? contrast,
    Color? contrastInverse,
    Color? glowSplashColor,
    Color? glowSplashColorOnContrast,
  }) {
    return AppTheme(
      artColorForBlend: artColorForBlend ?? this.artColorForBlend,
      currentIndicatorBackgroundColorWithDefaultArt:
          currentIndicatorBackgroundColorWithDefaultArt ?? this.currentIndicatorBackgroundColorWithDefaultArt,
      sliderInactiveColor: sliderInactiveColor ?? this.sliderInactiveColor,
      appBarBorderColor: appBarBorderColor ?? this.appBarBorderColor,
      drawerMenuItemColor: drawerMenuItemColor ?? this.drawerMenuItemColor,
      contrast: contrast ?? this.contrast,
      contrastInverse: contrastInverse ?? this.contrastInverse,
      glowSplashColor: glowSplashColor ?? this.glowSplashColor,
      glowSplashColorOnContrast: glowSplashColorOnContrast ?? this.glowSplashColorOnContrast,
    );
  }

  @override
  AppTheme lerp(covariant ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this as AppTheme;
    return AppTheme(
      artColorForBlend: Color.lerp(artColorForBlend, other.artColorForBlend, t)!,
      currentIndicatorBackgroundColorWithDefaultArt: Color.lerp(
          currentIndicatorBackgroundColorWithDefaultArt, other.currentIndicatorBackgroundColorWithDefaultArt, t)!,
      sliderInactiveColor: Color.lerp(sliderInactiveColor, other.sliderInactiveColor, t)!,
      appBarBorderColor: Color.lerp(appBarBorderColor, other.appBarBorderColor, t)!,
      drawerMenuItemColor: Color.lerp(drawerMenuItemColor, other.drawerMenuItemColor, t)!,
      contrast: Color.lerp(contrast, other.contrast, t)!,
      contrastInverse: Color.lerp(contrastInverse, other.contrastInverse, t)!,
      glowSplashColor: Color.lerp(glowSplashColor, other.glowSplashColor, t)!,
      glowSplashColorOnContrast: Color.lerp(glowSplashColorOnContrast, other.glowSplashColorOnContrast, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppTheme &&
            const DeepCollectionEquality().equals(artColorForBlend, other.artColorForBlend) &&
            const DeepCollectionEquality().equals(
                currentIndicatorBackgroundColorWithDefaultArt, other.currentIndicatorBackgroundColorWithDefaultArt) &&
            const DeepCollectionEquality().equals(sliderInactiveColor, other.sliderInactiveColor) &&
            const DeepCollectionEquality().equals(appBarBorderColor, other.appBarBorderColor) &&
            const DeepCollectionEquality().equals(drawerMenuItemColor, other.drawerMenuItemColor) &&
            const DeepCollectionEquality().equals(contrast, other.contrast) &&
            const DeepCollectionEquality().equals(contrastInverse, other.contrastInverse) &&
            const DeepCollectionEquality().equals(glowSplashColor, other.glowSplashColor) &&
            const DeepCollectionEquality().equals(glowSplashColorOnContrast, other.glowSplashColorOnContrast));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(artColorForBlend),
      const DeepCollectionEquality().hash(currentIndicatorBackgroundColorWithDefaultArt),
      const DeepCollectionEquality().hash(sliderInactiveColor),
      const DeepCollectionEquality().hash(appBarBorderColor),
      const DeepCollectionEquality().hash(drawerMenuItemColor),
      const DeepCollectionEquality().hash(contrast),
      const DeepCollectionEquality().hash(contrastInverse),
      const DeepCollectionEquality().hash(glowSplashColor),
      const DeepCollectionEquality().hash(glowSplashColorOnContrast),
    );
  }
}

extension AppThemeBuildContextProps on BuildContext {
  AppTheme get appTheme => Theme.of(this).extension<AppTheme>()!;

  /// Primary application color adjusted for blending into album arts.
  Color get artColorForBlend => appTheme.artColorForBlend;
  Color get currentIndicatorBackgroundColorWithDefaultArt => appTheme.currentIndicatorBackgroundColorWithDefaultArt;
  Color get sliderInactiveColor => appTheme.sliderInactiveColor;
  Color get appBarBorderColor => appTheme.appBarBorderColor;
  Color get drawerMenuItemColor => appTheme.drawerMenuItemColor;

  /// Color that contrasts with the [ColorScheme.surface].
  /// Black and white.
  Color get contrast => appTheme.contrast;
  Color get contrastInverse => appTheme.contrastInverse;

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
  Color get glowSplashColor => appTheme.glowSplashColor;

  /// A [glowSplashColor] to draw over contrasting colors, like primary or [contrast].
  Color get glowSplashColorOnContrast => appTheme.glowSplashColorOnContrast;
}
