/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Class to control how routes are created
abstract class RouteControl {
  /// Needed to disable animations on some routes
  static String _currentRoute = Constants.Routes.main.value;

  /// Changes the value of [_currentRoute]
  static void _setCurrentRoute(String newValue) {
    _currentRoute = newValue;
  }

  /// Check the equality of [_currentRoute] to some value
  static bool _currentRouteEquals(String value) {
    return _currentRoute == value;
  }

  static Route<dynamic> handleOnUnknownRoute(RouteSettings settings) {
    //******** Unknown ********
    return StackFadeRouteTransition(
      checkEntAnimationEnabled: () => false,
      maintainState: true,
      routeType: Constants.Routes.unknown,
      exitIgnoreEventsForward: false,
      checkSystemUi: () => Constants.AppSystemUIThemes.allScreens
          .autoBr(ThemeControl.brightness),
      route: Scaffold(
        // TODO: move to separate file
        body: Center(
          child: Text("Unknown route!"),
        ),
      ),
    );
  }

  static List<Route<dynamic>> handleOnGenerateInitialRoutes(String routeName) {
    // TODO: check out why this returns a list when docs release
    return [
      //******** Initial ********
      StackFadeRouteTransition(
        checkEntAnimationEnabled: () => false,
        shouldCheckSystemUiEnt: () =>
            _currentRouteEquals(Constants.Routes.player.value),
        maintainState: true,
        checkSystemUi: () => Constants.AppSystemUIThemes.mainScreen
            .autoBr(ThemeControl.brightness),
        exitIgnoreEventsForward: false,
        route: InitialRoute(),
      )
    ];
  }

  static Route<dynamic> handleOnGenerateRoute(RouteSettings settings) {
    _setCurrentRoute(settings.name);

    //******** Debug ********
    if (settings.name == Constants.Routes.debug.value) {
      return StackFadeRouteTransition(
        routeType: Constants.Routes.debug,
        checkSystemUi: () => Constants.AppSystemUIThemes.allScreens
            .autoBr(ThemeControl.brightness),
        route: DebugRoute(),
      );
    }
    //******** Exif ********
    else if (settings.name == Constants.Routes.exif.value) {
      return StackFadeRouteTransition(
        routeType: Constants.Routes.exif,
        checkSystemUi: () => Constants.AppSystemUIThemes.allScreens
            .autoBr(ThemeControl.brightness),
        route: ExifRoute(),
      );
    }
    //******** Extended settings ********
    else if (settings.name == Constants.Routes.extendedSettings.value) {
      return StackFadeRouteTransition(
        routeType: Constants.Routes.extendedSettings,
        checkSystemUi: () => Constants.AppSystemUIThemes.allScreens
            .autoBr(ThemeControl.brightness),
        route: ExtendedSettingsRoute(),
      );
    }
    //******** Player ********
    else if (settings.name == Constants.Routes.player.value) {
      // return RouteExpandTransition(route: PlayerRoute());
      return ExpandUpRouteTransition(
        routeType: Constants.Routes.player,
        opaque: true,
        transitionDuration: const Duration(milliseconds: 550),
        checkExitAnimationEnabled: () => false,
        entIgnoreEventsForward: true,
        checkSystemUi: () => Constants.AppSystemUIThemes.allScreens
            .autoBr(ThemeControl.brightness),
        route: PlayerRoute(),
      );
    }
    //******** Search ********
    else if (settings.name == Constants.Routes.search.value) {
      return (settings.arguments as Route);
    }
    //******** Settings ********
    else if (settings.name == Constants.Routes.settings.value) {
      return StackFadeRouteTransition(
        routeType: Constants.Routes.settings,
        checkSystemUi: () => Constants.AppSystemUIThemes.allScreens
            .autoBr(ThemeControl.brightness),
        route: SettingsRoute(),
      );
    }
    
    return null;
  }
}
