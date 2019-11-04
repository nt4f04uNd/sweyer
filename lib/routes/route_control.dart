import 'package:app/components/route_transitions.dart';
import 'package:app/components/show_functions.dart';
import 'package:app/constants/constants.dart';
import 'package:app/player/player.dart';
import 'package:app/player/theme.dart';
import 'package:flutter/material.dart';
import 'package:app/routes/exif_route.dart';
import 'package:app/routes/extendedSettings.dart';
import 'package:app/routes/main_route.dart';
import 'package:app/routes/player_route.dart';
import 'package:app/routes/settings_route.dart';
import 'package:flutter/services.dart';

/// Class to control how routes are created
abstract class RouteControl {
  // Var to show toast in `_handleHomePop`
  static DateTime _currentBackPressTime;

  /// Needed to disable animations on some routes
  static String _currentRoute = Routes.main.value;

  /// Changes the value of `_currentRoute`
  static void _setCurrentRoute(String newValue) {
    _currentRoute = newValue;
  }

  /// Check the equality of `_currentRoute` to some value
  static bool _currentRouteEquals(String value) {
    return _currentRoute == value;
  }

  /// Handles pop in main `'/'` route and shows user toast
  static Future<bool> _handleHomePop() async {
    DateTime now = DateTime.now();
    // Show toast when user presses back button on main route, that asks from user to press again to confirm that he wants to quit the app
    if (_currentBackPressTime == null ||
        now.difference(_currentBackPressTime) > Duration(seconds: 2)) {
      _currentBackPressTime = now;
      ShowFunctions.showToast(msg: 'Нажмите еще раз для выхода');
      return Future.value(false);
    }
    // Stop player before exiting app
    await MusicPlayer.stop();
    return Future.value(true);
  }

  static Route<dynamic> handleOnGenerateRoute(RouteSettings settings) {
    _setCurrentRoute(settings.name);
    // print(_currentRoute);

    if (settings.isInitialRoute)
      return createRouteTransition(
        checkExitAnimationEnabled: () =>
            _currentRouteEquals(Routes.settings.value),
        checkEntAnimationEnabled: () => false,
        exitCurve: Curves.linearToEaseOut,
        exitReverseCurve: Curves.fastOutSlowIn,
        maintainState: true,
        routeSystemUI: () =>
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        enterSystemUI:
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        exitIgnoreEventsForward: true,
        transitionDuration: const Duration(milliseconds: 500),
        route: WillPopScope(
            child:
                // AnnotatedRegion<SystemUiOverlayStyle>(
                //   value: AppSystemUIThemes.mainScreen
                //       .autoBr(_brightness),
                //   child:
                MainRoute(),
            // ),
            onWillPop: _handleHomePop),
      );
    else if (settings.name == Routes.player.value)
      return createRouteTransition(
        playMaterial: true,
        entCurve: Curves.fastOutSlowIn,
        exitCurve: Curves.linearToEaseOut,
        exitReverseCurve: Curves.fastOutSlowIn,
        entBegin: Offset(0.0, 1.0),
        checkExitAnimationEnabled: () => _currentRouteEquals(Routes.exif.value),
        opaque: false,
        enterSystemUI:
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        exitSystemUI: () =>
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        transitionDuration: const Duration(milliseconds: 500),
        route: PlayerRoute(),
      );
    else if (settings.name == Routes.settings.value)
      return createRouteTransition(
        transitionDuration: const Duration(milliseconds: 500),
        enterSystemUI:
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        exitSystemUI: () =>
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        exitCurve: Curves.linearToEaseOut,
        exitReverseCurve: Curves.fastOutSlowIn,
        entCurve: Curves.linearToEaseOut,
        entReverseCurve: Curves.fastOutSlowIn,
        route: SettingsRoute(),
      );
    else if (settings.name == Routes.extendedSettings.value)
      return createRouteTransition(
        transitionDuration: const Duration(milliseconds: 500),
        enterSystemUI:
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        exitSystemUI: () =>
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        entCurve: Curves.linearToEaseOut,
        entReverseCurve: Curves.fastOutSlowIn,
        route: ExtendedSettingsRoute(),
      );
    else if (settings.name == Routes.exif.value)
      return createRouteTransition(
        transitionDuration: const Duration(milliseconds: 500),
        entCurve: Curves.linearToEaseOut,
        entReverseCurve: Curves.fastOutSlowIn,
        route: AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
          child: ExifRoute(),
        ),
      );
    else if (settings.name == Routes.search.value)
      return (settings.arguments as Map<String, Route>)["route"];

    // FIXME: add unknown route
    return null;
  }
}
