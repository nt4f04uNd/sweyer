// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element

part of 'app_theme.dart';

// **************************************************************************
// ThemeTailorGenerator
// **************************************************************************

class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({
    required this.appBarBorderColor,
    required this.artColorForBlend,
    required this.contrast,
    required this.contrastInverse,
    required this.currentIndicatorBackgroundColorWithDefaultArt,
    required this.drawerMenuItemColor,
    required this.glowSplashColor,
    required this.glowSplashColorOnContrast,
    required this.sliderInactiveColor,
  });

  final dynamic appBarBorderColor;

  /// Primary application color adjusted for blending into album arts.
  final dynamic artColorForBlend;

  /// Color that contrasts with the [ColorScheme.background].
  /// Black and white.
  final dynamic contrast;
  final dynamic contrastInverse;
  final dynamic currentIndicatorBackgroundColorWithDefaultArt;
  final dynamic drawerMenuItemColor;

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
  final dynamic glowSplashColor;

  /// A [glowSplashColor] to draw over contrasting colors, like primary or [contrast].
  final dynamic glowSplashColorOnContrast;
  final dynamic sliderInactiveColor;

  static final AppTheme light = AppTheme(
    appBarBorderColor: _$AppTheme.appBarBorderColor[0],
    artColorForBlend: _$AppTheme.artColorForBlend[0],
    contrast: _$AppTheme.contrast[0],
    contrastInverse: _$AppTheme.contrastInverse[0],
    currentIndicatorBackgroundColorWithDefaultArt: _$AppTheme.currentIndicatorBackgroundColorWithDefaultArt[0],
    drawerMenuItemColor: _$AppTheme.drawerMenuItemColor[0],
    glowSplashColor: _$AppTheme.glowSplashColor[0],
    glowSplashColorOnContrast: _$AppTheme.glowSplashColorOnContrast[0],
    sliderInactiveColor: _$AppTheme.sliderInactiveColor[0],
  );

  static final AppTheme dark = AppTheme(
    appBarBorderColor: _$AppTheme.appBarBorderColor[1],
    artColorForBlend: _$AppTheme.artColorForBlend[1],
    contrast: _$AppTheme.contrast[1],
    contrastInverse: _$AppTheme.contrastInverse[1],
    currentIndicatorBackgroundColorWithDefaultArt: _$AppTheme.currentIndicatorBackgroundColorWithDefaultArt[1],
    drawerMenuItemColor: _$AppTheme.drawerMenuItemColor[1],
    glowSplashColor: _$AppTheme.glowSplashColor[1],
    glowSplashColorOnContrast: _$AppTheme.glowSplashColorOnContrast[1],
    sliderInactiveColor: _$AppTheme.sliderInactiveColor[1],
  );

  static final themes = [
    light,
    dark,
  ];

  @override
  AppTheme copyWith({
    dynamic appBarBorderColor,
    dynamic artColorForBlend,
    dynamic contrast,
    dynamic contrastInverse,
    dynamic currentIndicatorBackgroundColorWithDefaultArt,
    dynamic drawerMenuItemColor,
    dynamic glowSplashColor,
    dynamic glowSplashColorOnContrast,
    dynamic sliderInactiveColor,
  }) {
    return AppTheme(
      appBarBorderColor: appBarBorderColor ?? this.appBarBorderColor,
      artColorForBlend: artColorForBlend ?? this.artColorForBlend,
      contrast: contrast ?? this.contrast,
      contrastInverse: contrastInverse ?? this.contrastInverse,
      currentIndicatorBackgroundColorWithDefaultArt:
          currentIndicatorBackgroundColorWithDefaultArt ?? this.currentIndicatorBackgroundColorWithDefaultArt,
      drawerMenuItemColor: drawerMenuItemColor ?? this.drawerMenuItemColor,
      glowSplashColor: glowSplashColor ?? this.glowSplashColor,
      glowSplashColorOnContrast: glowSplashColorOnContrast ?? this.glowSplashColorOnContrast,
      sliderInactiveColor: sliderInactiveColor ?? this.sliderInactiveColor,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      appBarBorderColor: t < 0.5 ? appBarBorderColor : other.appBarBorderColor,
      artColorForBlend: t < 0.5 ? artColorForBlend : other.artColorForBlend,
      contrast: t < 0.5 ? contrast : other.contrast,
      contrastInverse: t < 0.5 ? contrastInverse : other.contrastInverse,
      currentIndicatorBackgroundColorWithDefaultArt:
          t < 0.5 ? currentIndicatorBackgroundColorWithDefaultArt : other.currentIndicatorBackgroundColorWithDefaultArt,
      drawerMenuItemColor: t < 0.5 ? drawerMenuItemColor : other.drawerMenuItemColor,
      glowSplashColor: t < 0.5 ? glowSplashColor : other.glowSplashColor,
      glowSplashColorOnContrast: t < 0.5 ? glowSplashColorOnContrast : other.glowSplashColorOnContrast,
      sliderInactiveColor: t < 0.5 ? sliderInactiveColor : other.sliderInactiveColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppTheme &&
            const DeepCollectionEquality().equals(appBarBorderColor, other.appBarBorderColor) &&
            const DeepCollectionEquality().equals(artColorForBlend, other.artColorForBlend) &&
            const DeepCollectionEquality().equals(contrast, other.contrast) &&
            const DeepCollectionEquality().equals(contrastInverse, other.contrastInverse) &&
            const DeepCollectionEquality().equals(
                currentIndicatorBackgroundColorWithDefaultArt, other.currentIndicatorBackgroundColorWithDefaultArt) &&
            const DeepCollectionEquality().equals(drawerMenuItemColor, other.drawerMenuItemColor) &&
            const DeepCollectionEquality().equals(glowSplashColor, other.glowSplashColor) &&
            const DeepCollectionEquality().equals(glowSplashColorOnContrast, other.glowSplashColorOnContrast) &&
            const DeepCollectionEquality().equals(sliderInactiveColor, other.sliderInactiveColor));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(appBarBorderColor),
        const DeepCollectionEquality().hash(artColorForBlend),
        const DeepCollectionEquality().hash(contrast),
        const DeepCollectionEquality().hash(contrastInverse),
        const DeepCollectionEquality().hash(currentIndicatorBackgroundColorWithDefaultArt),
        const DeepCollectionEquality().hash(drawerMenuItemColor),
        const DeepCollectionEquality().hash(glowSplashColor),
        const DeepCollectionEquality().hash(glowSplashColorOnContrast),
        const DeepCollectionEquality().hash(sliderInactiveColor));
  }
}

extension AppThemeBuildContextProps on BuildContext {
  AppTheme get _appTheme => Theme.of(this).extension<AppTheme>()!;
  dynamic get appBarBorderColor => _appTheme.appBarBorderColor;

  /// Primary application color adjusted for blending into album arts.
  dynamic get artColorForBlend => _appTheme.artColorForBlend;

  /// Color that contrasts with the [ColorScheme.background].
  /// Black and white.
  dynamic get contrast => _appTheme.contrast;
  dynamic get contrastInverse => _appTheme.contrastInverse;
  dynamic get currentIndicatorBackgroundColorWithDefaultArt => _appTheme.currentIndicatorBackgroundColorWithDefaultArt;
  dynamic get drawerMenuItemColor => _appTheme.drawerMenuItemColor;

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
  dynamic get glowSplashColor => _appTheme.glowSplashColor;

  /// A [glowSplashColor] to draw over contrasting colors, like primary or [contrast].
  dynamic get glowSplashColorOnContrast => _appTheme.glowSplashColorOnContrast;
  dynamic get sliderInactiveColor => _appTheme.sliderInactiveColor;
}
