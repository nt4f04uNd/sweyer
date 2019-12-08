import 'package:app/components/route_transitions.dart';
import 'package:app/components/show_functions.dart';
import 'package:app/constants/constants.dart';
import 'package:app/logic/player/player.dart';
import 'package:app/logic/theme.dart';
import 'package:flutter/cupertino.dart';
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

    if (settings.isInitialRoute)
      return createRouteTransition(
        checkExitAnimationEnabled: () =>
            _currentRouteEquals(Routes.settings.value) ||
                _currentRouteEquals(Routes.extendedSettings.value),
        checkEntAnimationEnabled: () => false,
        maintainState: true,
        
        routeSystemUI: () =>
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        enterSystemUI:
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        exitIgnoreEventsForward: false,
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
    else if (settings.name == Routes.player.value) {
      return createRouteTransition(
        playMaterial: true,
        materialAnimationStyle: MaterialRouteTransitionStyle.expand,
        entCurve: Curves.fastOutSlowIn,
        exitCurve: Curves.linearToEaseOut,
        exitReverseCurve: Curves.fastOutSlowIn,
        entBegin: Offset(0.0, 1.0),
        checkExitAnimationEnabled: () => _currentRouteEquals(Routes.exif.value),
        enterSystemUI:
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        exitSystemUI: () =>
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        route: PlayerRoute(),
      );
    } else if (settings.name == Routes.settings.value)
      return createRouteTransition(
        enterSystemUI:
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        exitSystemUI: () =>
            AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        route: SettingsRoute(),
      );
    else if (settings.name == Routes.extendedSettings.value)
      return createRouteTransition(
        enterSystemUI:
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        exitSystemUI: () =>
            AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        route: ExtendedSettingsRoute(),
      );
    else if (settings.name == Routes.exif.value)
      return createRouteTransition(
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
