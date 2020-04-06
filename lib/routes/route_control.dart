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
  static Route<dynamic> handleOnUnknownRoute(RouteSettings settings) {
    //******** Unknown ********
    return StackFadeRouteTransition(
      routeType: Constants.Routes.unknown,
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
        maintainState: true,
        checkSystemUi: () =>
            Constants.AppSystemUIThemes.mainScreen.autoWithoutContext,
        exitIgnoreEventsForward: false,
        route: InitialRoute(),
      )
    ];
  }

  static Route<dynamic> handleOnGenerateRoute(RouteSettings settings) {
    //******** Developer ********
    if (settings.name == Constants.Routes.dev.value) {
      return StackFadeRouteTransition(
        routeType: Constants.Routes.dev,
        route: DevRoute(),
      );
    }
    //******** Exif ********
    else if (settings.name == Constants.Routes.exif.value) {
      return StackFadeRouteTransition(
        routeType: Constants.Routes.exif,
        route: ExifRoute(),
      );
    }
    //******** Extended settings ********
    else if (settings.name == Constants.Routes.extendedSettings.value) {
      return StackFadeRouteTransition(
        routeType: Constants.Routes.extendedSettings,
        route: ExtendedSettingsRoute(),
      );
    }
    //******** Player ********
    else if (settings.name == Constants.Routes.player.value) {
      // return RouteExpandTransition(route: PlayerRoute());
      return ExpandUpRouteTransition(
        routeType: Constants.Routes.player,
        opaque: true,
        transitionDuration: kSMMPlayerRouteTransitionDuration,
        checkExitAnimationEnabled: () => false,
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
        route: SettingsRoute(),
      );
    }

    return null;
  }
}
