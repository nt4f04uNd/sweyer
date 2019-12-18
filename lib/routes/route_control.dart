/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter_music_player/flutter_music_player.dart';
import 'package:flutter_music_player/constants.dart' as Constants;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Class to control how routes are created
abstract class RouteControl {
  // Var to show toast in `_handleHomePop`
  static DateTime _currentBackPressTime;

  /// Needed to disable animations on some routes
  static String _currentRoute = Constants.Routes.main.value;

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
            _currentRouteEquals(Constants.Routes.settings.value) ||
            _currentRouteEquals(Constants.Routes.extendedSettings.value),
        checkEntAnimationEnabled: () => false,
        maintainState: true,
        routeSystemUI: () =>
            Constants.AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        checkEnterSystemUI: () =>
            Constants.AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
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
    else if (settings.name == Constants.Routes.player.value) {
      return createRouteTransition(
        playMaterial: true,
        materialAnimationStyle: MaterialRouteTransitionStyle.expand,
        entIgnoreEventsForward: true,
        entCurve: Curves.fastOutSlowIn,
        entBegin: Offset(0.0, 1.0),
        checkExitAnimationEnabled: () => _currentRouteEquals(Constants.Routes.exif.value),
        checkEnterSystemUI: () =>
            Constants.AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        checkExitSystemUI: () =>
            Constants.AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        route: PlayerRoute(),
      );
    } else if (settings.name == Constants.Routes.settings.value)
      return createRouteTransition(
        checkEnterSystemUI: () =>
            Constants.AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        checkExitSystemUI: () =>
            Constants.AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        route: SettingsRoute(),
      );
    else if (settings.name == Constants.Routes.extendedSettings.value)
      return createRouteTransition(
        checkEnterSystemUI: () =>
            Constants.AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        checkExitSystemUI: () =>
            Constants.AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        route: ExtendedSettingsRoute(),
      );
    else if (settings.name == Constants.Routes.exif.value)
      return createRouteTransition(
        route: AnnotatedRegion<SystemUiOverlayStyle>(
          value: Constants.AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
          child: ExifRoute(),
        ),
      );
    else if (settings.name == Constants.Routes.debug.value)
      return createRouteTransition(
        checkEnterSystemUI: () =>
            Constants.AppSystemUIThemes.allScreens.autoBr(ThemeControl.brightness),
        checkExitSystemUI: () =>
            Constants.AppSystemUIThemes.mainScreen.autoBr(ThemeControl.brightness),
        route:  DebugRoute(),
      );
    else if (settings.name == Constants.Routes.search.value)
      return (settings.arguments as Map<String, Route>)["route"];

    // FIXME: add unknown route
    return null;
  }
}