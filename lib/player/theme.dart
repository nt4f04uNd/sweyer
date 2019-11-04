import 'package:app/player/manual_stream_controller.dart';
import 'package:app/player/prefs.dart';
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
  static void switchTheme() async {
    _brightness =
        _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    Prefs.byKey.themeBrightnessBool.setPref(_brightness == Brightness.dark);
    emitThemeChange();
    await Future.delayed(Duration(milliseconds: 400));
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
  static Stream<void> get onThemeChange => _controller.stream;
  static void emitThemeChange() {
    _controller.emitEvent();
  }
}
