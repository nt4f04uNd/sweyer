/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:app/utils/async.dart';
import 'package:app/logic/prefs.dart';
import 'package:app/constants/themes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

abstract class ThemeControl {
  static Brightness _brightness = Brightness.dark;

  /// App theme  brightness
  static Brightness get brightness => _brightness;

  /// True if `brightness` is dark
  static bool get isDark => _brightness == Brightness.dark;

  /// Changes theme to opposite and saves new value to pref
  /// 
  /// Optional `delayed` allows to delay color switch by 200ms
  static void switchTheme([bool delayed = false]) async {
    _brightness =
        _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    Prefs.byKey.themeBrightnessBool.setPref(_brightness == Brightness.dark);
    emitThemeChange();
    if(delayed) await Future.delayed(Duration(milliseconds: 200));
    SystemChrome.setSystemUIOverlayStyle(
        AppSystemUIThemes.allScreens.autoBr(_brightness));
  }

  /// Inits theme, fetches brightness from `PrefKeys`
  static Future<void> init() async {
    final savedBrightness = await Prefs.byKey.themeBrightnessBool.getPref();
    if (savedBrightness == null)
      _brightness = Brightness.dark;
    else
      _brightness = savedBrightness ? Brightness.dark : Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
        AppSystemUIThemes.allScreens.autoBr(_brightness));
    emitThemeChange();
  }

  static final ManualStreamController _controller = ManualStreamController();

  /// Gets stream of changes on theme
  static Stream<void> get onThemeChange => _controller.stream;

  /// Emit theme change into stream
  static void emitThemeChange() {
    _controller.emitEvent();
  }
}
