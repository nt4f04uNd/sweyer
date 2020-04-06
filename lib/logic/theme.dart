/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'dart:async';

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// TODO: add system theme setting
abstract class ThemeControl {
  static Brightness _brightness;

  /// App theme  brightness
  static Brightness get brightness => _brightness;

  /// Returns a brightness, opposite to the main brightness
  static Brightness get contrastBrightness =>
      isDark ? Brightness.light : Brightness.dark;

  /// True if [brightness] is dark
  static bool get isDark => _brightness == Brightness.dark;

  /// True if [brightness] is fetched or not
  static bool get isReady => _brightness != null;

  /// Changes theme to opposite and saves new value to pref
  ///
  /// By default performs an animation of system ui to [Constants.AppSystemUIThemes.allScreens].
  /// Optional [systemUiOverlayStyle] allows change that behavior.
  static void switchTheme(
      {SystemUiOverlayStyleControl systemUiOverlayStyle}) async {
    _brightness =
        _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    Settings.darkThemeBool.setPref(value: _brightness == Brightness.dark);
    emitThemeChange(_brightness);

    await SystemUiOverlayStyleControl.animateSystemUiOverlay(
      to: systemUiOverlayStyle ??
          Constants.AppSystemUIThemes.allScreens.autoBr(_brightness),
      curve: Curves.easeIn,
      settings: AnimationControllerSettings(
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Inits theme, fetches brightness from [PrefKeys]
  ///
  /// NOTE that this does NOT call [emitThemeChange], cause it will trigger theme switch transition with low fps,
  /// but I rather want to have a listener for [LaunchControl.onLaunch] in `main.dart` to update the entire [MaterialApp] to have just a short blink
  /// FIXME even this way transition is triggered
  static Future<void> init() async {
    try {
      final savedBrightness = await Settings.darkThemeBool.getPref();
      _brightness = savedBrightness ? Brightness.dark : Brightness.light;
    } catch (e, stackTrace) {
      CatcherErrorBridge.add(CaughtError(e, stackTrace));
    } finally {
      SystemUiOverlayStyleControl.setSystemUiOverlay(
        Constants.AppSystemUIThemes.mainScreen.autoBr(_brightness),
        saveToHistory: false,
      );
      // emitThemeChange();
    }
  }

  static final StreamController<Brightness> _controller =
      StreamController<Brightness>.broadcast();

  /// Gets stream of changes on theme
  static Stream<Brightness> get onThemeChange => _controller.stream;

  /// Emit theme change into stream
  static void emitThemeChange(Brightness value) {
    _controller.add(value);
  }
}
