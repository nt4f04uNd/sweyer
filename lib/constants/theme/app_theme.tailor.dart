// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_element

part of 'app_theme.dart';

// **************************************************************************
// ThemeTailorGenerator
// **************************************************************************

class AppTheme extends ThemeExtension<AppTheme> {
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

  final Color artColorForBlend;
  final Color currentIndicatorBackgroundColorWithDefaultArt;
  final Color sliderInactiveColor;
  final Color appBarBorderColor;
  final Color drawerMenuItemColor;
  final Color contrast;
  final Color contrastInverse;
  final Color glowSplashColor;
  final Color glowSplashColorOnContrast;

  static final AppTheme light = AppTheme(
    artColorForBlend: _$AppTheme.artColorForBlend[0],
    currentIndicatorBackgroundColorWithDefaultArt:
        _$AppTheme.currentIndicatorBackgroundColorWithDefaultArt[0],
    sliderInactiveColor: _$AppTheme.sliderInactiveColor[0],
    appBarBorderColor: _$AppTheme.appBarBorderColor[0],
    drawerMenuItemColor: _$AppTheme.drawerMenuItemColor[0],
    contrast: _$AppTheme.contrast[0],
    contrastInverse: _$AppTheme.contrastInverse[0],
    glowSplashColor: _$AppTheme.glowSplashColor[0],
    glowSplashColorOnContrast: _$AppTheme.glowSplashColorOnContrast[0],
  );

  static final AppTheme dark = AppTheme(
    artColorForBlend: _$AppTheme.artColorForBlend[1],
    currentIndicatorBackgroundColorWithDefaultArt:
        _$AppTheme.currentIndicatorBackgroundColorWithDefaultArt[1],
    sliderInactiveColor: _$AppTheme.sliderInactiveColor[1],
    appBarBorderColor: _$AppTheme.appBarBorderColor[1],
    drawerMenuItemColor: _$AppTheme.drawerMenuItemColor[1],
    contrast: _$AppTheme.contrast[1],
    contrastInverse: _$AppTheme.contrastInverse[1],
    glowSplashColor: _$AppTheme.glowSplashColor[1],
    glowSplashColorOnContrast: _$AppTheme.glowSplashColorOnContrast[1],
  );

  static final themes = [
    light,
    dark,
  ];

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
          currentIndicatorBackgroundColorWithDefaultArt ??
              this.currentIndicatorBackgroundColorWithDefaultArt,
      sliderInactiveColor: sliderInactiveColor ?? this.sliderInactiveColor,
      appBarBorderColor: appBarBorderColor ?? this.appBarBorderColor,
      drawerMenuItemColor: drawerMenuItemColor ?? this.drawerMenuItemColor,
      contrast: contrast ?? this.contrast,
      contrastInverse: contrastInverse ?? this.contrastInverse,
      glowSplashColor: glowSplashColor ?? this.glowSplashColor,
      glowSplashColorOnContrast:
          glowSplashColorOnContrast ?? this.glowSplashColorOnContrast,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      artColorForBlend:
          Color.lerp(artColorForBlend, other.artColorForBlend, t)!,
      currentIndicatorBackgroundColorWithDefaultArt: Color.lerp(
          currentIndicatorBackgroundColorWithDefaultArt,
          other.currentIndicatorBackgroundColorWithDefaultArt,
          t)!,
      sliderInactiveColor:
          Color.lerp(sliderInactiveColor, other.sliderInactiveColor, t)!,
      appBarBorderColor:
          Color.lerp(appBarBorderColor, other.appBarBorderColor, t)!,
      drawerMenuItemColor:
          Color.lerp(drawerMenuItemColor, other.drawerMenuItemColor, t)!,
      contrast: Color.lerp(contrast, other.contrast, t)!,
      contrastInverse: Color.lerp(contrastInverse, other.contrastInverse, t)!,
      glowSplashColor: Color.lerp(glowSplashColor, other.glowSplashColor, t)!,
      glowSplashColorOnContrast: Color.lerp(
          glowSplashColorOnContrast, other.glowSplashColorOnContrast, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppTheme &&
            const DeepCollectionEquality()
                .equals(artColorForBlend, other.artColorForBlend) &&
            const DeepCollectionEquality().equals(
                currentIndicatorBackgroundColorWithDefaultArt,
                other.currentIndicatorBackgroundColorWithDefaultArt) &&
            const DeepCollectionEquality()
                .equals(sliderInactiveColor, other.sliderInactiveColor) &&
            const DeepCollectionEquality()
                .equals(appBarBorderColor, other.appBarBorderColor) &&
            const DeepCollectionEquality()
                .equals(drawerMenuItemColor, other.drawerMenuItemColor) &&
            const DeepCollectionEquality().equals(contrast, other.contrast) &&
            const DeepCollectionEquality()
                .equals(contrastInverse, other.contrastInverse) &&
            const DeepCollectionEquality()
                .equals(glowSplashColor, other.glowSplashColor) &&
            const DeepCollectionEquality().equals(
                glowSplashColorOnContrast, other.glowSplashColorOnContrast));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(artColorForBlend),
        const DeepCollectionEquality()
            .hash(currentIndicatorBackgroundColorWithDefaultArt),
        const DeepCollectionEquality().hash(sliderInactiveColor),
        const DeepCollectionEquality().hash(appBarBorderColor),
        const DeepCollectionEquality().hash(drawerMenuItemColor),
        const DeepCollectionEquality().hash(contrast),
        const DeepCollectionEquality().hash(contrastInverse),
        const DeepCollectionEquality().hash(glowSplashColor),
        const DeepCollectionEquality().hash(glowSplashColorOnContrast));
  }
}

extension AppThemeBuildContextProps on BuildContext {
  AppTheme get _appTheme => Theme.of(this).extension<AppTheme>()!;
  Color get artColorForBlend => _appTheme.artColorForBlend;
  Color get currentIndicatorBackgroundColorWithDefaultArt =>
      _appTheme.currentIndicatorBackgroundColorWithDefaultArt;
  Color get sliderInactiveColor => _appTheme.sliderInactiveColor;
  Color get appBarBorderColor => _appTheme.appBarBorderColor;
  Color get drawerMenuItemColor => _appTheme.drawerMenuItemColor;
  Color get contrast => _appTheme.contrast;
  Color get contrastInverse => _appTheme.contrastInverse;
  Color get glowSplashColor => _appTheme.glowSplashColor;
  Color get glowSplashColorOnContrast => _appTheme.glowSplashColorOnContrast;
}
