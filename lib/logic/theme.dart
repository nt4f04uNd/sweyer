import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sweyer/sweyer.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;

class ThemeControl {
  static ThemeControl instance = ThemeControl();

  bool _ready = false;
  late Color _colorForBlend;
  late Brightness _brightness;

  /// Whether the start up ui animation has ended.
  bool get ready => _ready;

  /// Primary application color adjusted for blending into album arts.
  Color get colorForBlend => _colorForBlend;

  /// App theme  brightness
  Brightness get brightness => _brightness;

  /// Returns a brightness, opposite to the main brightness
  Brightness get contrastBrightness => isDark ? Brightness.light : Brightness.dark;

  /// True if [brightness] is light
  bool get isLight => _brightness == Brightness.light;

  /// True if [brightness] is dark
  bool get isDark => _brightness == Brightness.dark;

  ThemeData get theme => isLight ? Constants.Theme.app.light : Constants.Theme.app.dark;

  final Duration themeChangeDuration = const Duration(milliseconds: 300);
  static const Duration primaryColorChangeDuration = Duration(milliseconds: 240);
  CancelableOperation<void>? _rebuildOperation;

  /// If `true` - that means theme animation is now being performed and
  /// some interface can hidden for optimization sake.
  final BehaviorSubject<bool> themeChaning = BehaviorSubject.seeded(false);

  /// Returns primary or onBackground color, depending on:
  /// * the current primary
  /// * light mode option
  ///
  /// In some cases primary may look good with one combination of these,
  /// in some - the opposite. So this function decides what's better.
  Color get primaryOrOnBackgroundColor {
    final primary = theme.colorScheme.primary;
    if (isLight) {
      return primary;
    } else {
      if (primary == Constants.AppColors.deepPurpleAccent) {
        return theme.colorScheme.onBackground;
      }
      return primary;
    }
  }

  /// Inits theme, fetches brightness from [Prefs].
  ///
  /// NOTE that this does NOT call [emitThemeChange].
  void init() {
    final lightTheme = Settings.lightThemeBool.get();
    _brightness = lightTheme ? Brightness.light : Brightness.dark;
    final primaryColor = Color(Settings.primaryColorInt.get());
    _applyPrimaryColor(primaryColor);
  }

  /// This is needed to show start up application animation.
  Future<void> initSystemUi() async {
    // Show purple ui firstly.
    SystemUiStyleController.instance.setSystemUiOverlay(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.deepPurpleAccent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.deepPurpleAccent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ));
    await Future.delayed(const Duration(milliseconds: 500));
    if (SystemUiStyleController.instance.lastUi.systemNavigationBarColor !=
        Constants.UiTheme.black.auto.systemNavigationBarColor) {
      final ui = Constants.UiTheme.grey.auto;
      await SystemUiStyleController.instance.animateSystemUiOverlay(
        to: ui,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 550),
      );
    }
    _ready = true;
  }

  @visibleForTesting
  void setThemeLightMode(bool value) {
    _brightness = value ? Brightness.light : Brightness.dark;
    Settings.lightThemeBool.set(value);
  }

  /// Changes theme to opposite and saves new value to pref.
  Future<void> switchTheme() async {
    _rebuildOperation?.cancel();
    setThemeLightMode(_brightness == Brightness.dark);
    App.nfThemeData = App.nfThemeData.copyWith(
      systemUiStyle: Constants.UiTheme.black.auto,
      modalSystemUiStyle: Constants.UiTheme.modal.auto,
      bottomSheetSystemUiStyle: Constants.UiTheme.bottomSheet.auto,
    );

    AppRouter.instance.updateTransitionSettings(themeChanged: true);

    themeChaning.add(true);
    _rebuildOperation = CancelableOperation<void>.fromFuture(
      Future.delayed(dilate(themeChangeDuration)),
    ).then((value) async {
      App.rebuildAllChildren();
    }).then((value) {
      themeChaning.add(false);
    });

    await SystemUiStyleController.instance.animateSystemUiOverlay(
      to: Constants.UiTheme.black.auto,
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 160),
    );
  }

  /// Accepts new primary color, updates [colorForBlend] and changes theme dependent on it.
  void changePrimaryColor(Color color) {
    _rebuildOperation?.cancel();
    _applyPrimaryColor(color);
    Settings.primaryColorInt.set(color.value);
    themeChaning.add(true);
    MusicPlayer.instance.updateServiceMediaItem();
    _rebuildOperation = CancelableOperation<void>.fromFuture(
      Future.delayed(dilate(primaryColorChangeDuration)),
    ).then((value) async {
      App.rebuildAllChildren();
    }).then((value) {
      themeChaning.add(false);
    });
  }

  void _applyPrimaryColor(Color color) {
    AppRouter.instance.updateTransitionSettings(themeChanged: true);
    _colorForBlend = ContentArt.getColorToBlendInDefaultArt(color);
    Constants.Theme.app = Constants.Theme.app.copyWith(
      light: Constants.Theme.app.light.copyWith(
        primaryColor: color,
        toggleableActiveColor: color,
        colorScheme: Constants.Theme.app.light.colorScheme.copyWith(
          primary: color,
          onSecondary: color,
          // todo: temporarily used for text in [AppButton], remove when ThemeExtenions are in place
        ),
        tooltipTheme: Constants.Theme.app.light.tooltipTheme.copyWith(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(
              Radius.circular(100.0),
            ),
          ),
        ),
        textSelectionTheme: Constants.Theme.app.light.textSelectionTheme.copyWith(
          cursorColor: color,
          selectionColor: color,
          selectionHandleColor: color,
        ),
      ),
      dark: Constants.Theme.app.dark.copyWith(
        // In dark mode I also have splashColor set to be primary
        splashColor: color,
        primaryColor: color,
        toggleableActiveColor: color,
        colorScheme: Constants.Theme.app.dark.colorScheme.copyWith(
          primary: color,
        ),
        tooltipTheme: Constants.Theme.app.light.tooltipTheme.copyWith(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(
              Radius.circular(100.0),
            ),
          ),
        ),
        textSelectionTheme: Constants.Theme.app.dark.textSelectionTheme.copyWith(
          cursorColor: color,
          selectionColor: color,
          selectionHandleColor: color,
        ),
      ),
    );
  }
}
