/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:sweyer/constants.dart' as Constants;

abstract class ThemeControl {
  static bool _ready = false;
  static late Color _colorForBlend;
  static late Brightness _brightness;

  /// Whether the start up ui animation has ended.
  static bool get ready => _ready;

  /// Primary application color adjusted for blending into album arts.
  static Color get colorForBlend => _colorForBlend;

  /// App theme  brightness
  static Brightness get brightness => _brightness;

  /// Returns a brightness, opposite to the main brightness
  static Brightness get contrastBrightness => isDark ? Brightness.light : Brightness.dark;

  /// True if [brightness] is light
  static bool get isLight => _brightness == Brightness.light;

  /// True if [brightness] is dark
  static bool get isDark => _brightness == Brightness.dark;

  static ThemeData get theme => isLight ? Constants.Theme.app.light : Constants.Theme.app.dark;

  /// Returns primary or onBackground color, depending on:
  /// * the current primary
  /// * light mode option
  ///
  /// In some cases primary may look good with one combination of these,
  /// in some - the opposite. So this function decides what's better.
  static Color get primaryOrOnBackgroundColor {
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
  static Future<void> init() async {
    final lightTheme = await Settings.lightThemeBool.get();
    _brightness = lightTheme ? Brightness.light : Brightness.dark;
    final primaryColor = Color(await Settings.primaryColorInt.get());
    _applyPrimaryColor(primaryColor);
  }

  /// This is needed to show start up application animation.
  static Future<void> initSystemUi() async {
    // Show purple ui firstly.
    SystemUiStyleController.setSystemUiOverlay(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.deepPurpleAccent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.deepPurpleAccent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ));
    await Future.delayed(const Duration(milliseconds: 500));
    if (SystemUiStyleController.lastUi.systemNavigationBarColor != Constants.UiTheme.black.auto.systemNavigationBarColor) {
      final ui = Constants.UiTheme.grey.auto;
      await SystemUiStyleController.animateSystemUiOverlay(
        to: ui,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 550),
      );
    }
    _ready = true;
  }

  /// Changes theme to opposite and saves new value to pref.
  static Future<void> switchTheme() async {
    _rebuildOperation?.cancel();
    _brightness = _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    Settings.lightThemeBool.set(_brightness == Brightness.light);
    App.nfThemeData = App.nfThemeData.copyWith(
      systemUiStyle: Constants.UiTheme.black.auto,
      modalSystemUiStyle: Constants.UiTheme.modal.auto,
      bottomSheetSystemUiStyle: Constants.UiTheme.bottomSheet.auto,
    );

    AppRouter.instance.updateTransitionSettings(themeChanged: true);

    emitThemeChange(true);
    _rebuildOperation = CancelableOperation.fromFuture(() async {
      await Future.delayed(dilate(const Duration(milliseconds: 300)));
      App.rebuildAllChildren();
      await Future.delayed(dilate(const Duration(milliseconds: 20)));
      emitThemeChange(false);
    }());
    await SystemUiStyleController.animateSystemUiOverlay(
      to: Constants.UiTheme.black.auto,
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 160),
    );
  }

  /// Accepts new primary color, updates [colorForBlend] and changes theme dependent on it.
  static void changePrimaryColor(Color color) {
    _rebuildOperation?.cancel();
    _applyPrimaryColor(color);
    Settings.primaryColorInt.set(color.value);
    emitThemeChange(true);
    MusicPlayer.instance.updateServiceMediaItem();
    // _rebuildOperation = CancelableOperation.fromFuture(() async {
    //   await Future.delayed(dilate(primaryColorChangeDuration));
    //   App.rebuildAllChildren();
    //   await Future.delayed(dilate(const Duration(milliseconds: 20)));
    //   emitThemeChange(false);
    // }());
    // TODO: test this
    _rebuildOperation = CancelableOperation<void>.fromFuture(
      Future.delayed(dilate(primaryColorChangeDuration))
    )
    ..valueOrCancellation()
    .then((value) async {
      App.rebuildAllChildren();
      await Future.delayed(dilate(const Duration(milliseconds: 20)));
    })
    .then((value) => emitThemeChange(false));
  }

  static void _applyPrimaryColor(Color color) {
    AppRouter.instance.updateTransitionSettings(themeChanged: true);
    _colorForBlend = getColorForBlend(color);
    Constants.Theme.app = Constants.Theme.app.copyWith(
      light: Constants.Theme.app.light.copyWith(
        primaryColor: color,
        colorScheme: Constants.Theme.app.light.colorScheme.copyWith(
          primary: color,
          onSecondary: color,
          // todo: temporarily used for text in [NFButtons], remove when it's removed
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

  static final StreamController<bool> _controller = StreamController<bool>.broadcast();
  static const Duration primaryColorChangeDuration = Duration(milliseconds: 240);
  static CancelableOperation<void>? _rebuildOperation;

  /// Gets stream of changes on theme.
  ///
  /// Boolean value emitted to the stream indicates that theme animation is now playing and
  /// some interface that can be hidden for the animation optimization.
  static Stream<bool> get onThemeChange => _controller.stream;
  static bool get themeChaning => _themeChaning;

  /// Whether the theme is curretly chaning.
  static bool _themeChaning = false;

  /// Emit theme change into stream
  ///
  /// The [value] indicates that theme animation is now playing and
  /// some interface that can be hidden for the animation optimization.
  static void emitThemeChange(bool value) {
    _themeChaning = value;
    _controller.add(value);
  }
}
