/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:nt4f04unds_widgets/nt4f04unds_widgets.dart';
import 'package:sweyer/sweyer.dart';
import 'package:sweyer/constants.dart' as Constants;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The class to control over the how routes are created.
abstract class RouteControl {
  static Widget get barrier => Container(
        color: ThemeControl.isDark ? Colors.black54 : Colors.black26,
      );
  static final defaultTransitionSetttings = StackFadeRouteTransitionSettings(
    opaque: false,
    dismissible: true,
    dismissBarrier: barrier,
  );

  static Route<dynamic> handleOnUnknownRoute(RouteSettings settings) {
    return StackFadeRouteTransition(
      route: const UnknownRoute(),
      transitionSettings: defaultTransitionSetttings,
    );
  }

  static List<Route<dynamic>> handleOnGenerateInitialRoutes(String routeName) {
    return [
      StackFadeRouteTransition(
        route: const HomeRoute(),
        transitionSettings: StackFadeRouteTransitionSettings(
          checkEntAnimationEnabled: () => false,
          maintainState: true,
          checkSystemUi: () => MainScreen.shown
              ? Constants.UiTheme.grey.auto
              : Constants.UiTheme.black.auto,
        ),
      ),
    ];
  }

  static Route<dynamic> handleOnGenerateRoute(RouteSettings settings) {
    if (settings.name == Constants.Routes.dev.value) {
      return StackFadeRouteTransition(
        route: const DevRoute(),
        transitionSettings: defaultTransitionSetttings,
      );
    } else if (settings.name == Constants.Routes.settings.value) {
      return StackFadeRouteTransition(
        route: const SettingsRoute(),
        transitionSettings: defaultTransitionSetttings,
      );
    }

    return null;
  }
}
