/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'route_transitions.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Creates customizable fade in transition
///
/// By default acts pretty same as [FadeUpwardsPageTransitionsBuilder] - creates upwards fade in transition
class RouteFadeInTransition<T extends Widget> extends RouteTransition<T> {
  @override
  final T route;
  @override
  final Constants.Routes routeType;
  @override
  BoolFunction checkEntAnimationEnabled;
  @override
  BoolFunction checkExitAnimationEnabled;
  @override
  final Curve entCurve;
  @override
  final Curve entReverseCurve;
  @override
  final Curve exitCurve;
  @override
  final Curve exitReverseCurve;
  @override
  final bool entIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsReverse;
  @override
  RouteTransitionsBuilder transitionsBuilder;
  @override
  UIFunction checkSystemUi;
  @override
  BoolFunction shouldCheckSystemUiEnt;
  @override
  BoolFunction shouldCheckSystemUiExitRev;

  /// Begin offset for enter animation
  ///
  /// Defaults to [const Offset(1.0, 0.0)]
  final Offset entBegin;

  /// End offset for enter animation
  ///
  /// Defaults to [Offset.zero]
  final Offset entEnd;

  /// Begin offset for exit animation
  ///
  /// Defaults to [Offset.zero]
  final Offset exitBegin;

  /// End offset for exit animation
  ///
  /// Defaults to [const Offset(-0.3, 0.0)]
  final Offset exitEnd;

  RouteFadeInTransition({
    @required this.route,
    this.routeType = Constants.Routes.main,
    this.checkEntAnimationEnabled = defBoolFunc,
    this.checkExitAnimationEnabled = defBoolFunc,
    this.entCurve = Curves.linearToEaseOut,
    this.entReverseCurve = Curves.easeInToLinear,
    this.exitCurve = Curves.linearToEaseOut,
    this.exitReverseCurve = Curves.easeInToLinear,
    this.entIgnoreEventsForward = false,
    this.exitIgnoreEventsForward = false,
    this.exitIgnoreEventsReverse = false,
    this.checkSystemUi,
    this.shouldCheckSystemUiEnt = defBoolFunc,
    this.shouldCheckSystemUiExitRev = defBoolFunc,
    this.entBegin = const Offset(1.0, 0.0),
    this.entEnd = Offset.zero,
    this.exitBegin = Offset.zero,
    this.exitEnd = const Offset(-0.2, 0.0),
    Duration transitionDuration = kSMMRouteTransitionDuration,
    RouteSettings settings,
    bool opaque = true,
    bool maintainState = false,
  }) : super(
          route: route,
          transitionDuration: transitionDuration,
          settings: settings,
          opaque: opaque,
          maintainState: maintainState,
        ) {
    pageBuilder = (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      handleSystemUi(animation, secondaryAnimation);
      return route;
    };
    transitionsBuilder = (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final bool entEnabled = checkEntAnimationEnabled();
      final bool exitEnabled = checkExitAnimationEnabled();

      final bool ignore =
          entIgnoreEventsForward && animation.status == AnimationStatus.forward;
      final bool secondaryIgnore = exitIgnoreEventsForward &&
              secondaryAnimation.status == AnimationStatus.forward ||
          exitIgnoreEventsReverse &&
              secondaryAnimation.status == AnimationStatus.reverse;

      /// Wrap child for to use with material routes (difference from default child is that is has animation status completed check, that brakes theme ui switch)
      final Container materialWrappedChild = Container(
        foregroundDecoration: BoxDecoration(
          color: // Dim exit page from 0 to 0.7
              Colors.black.withOpacity(exitEnabled
                  ? secondaryAnimation.status == AnimationStatus.forward
                      ? secondaryAnimation.value / 1.3
                      : secondaryAnimation.value / 2.9
                  : 0),
        ),
        child: IgnorePointer(
          // Disable any touch events on enter while in transition
          ignoring: ignore,
          child: IgnorePointer(
            // Disable any touch events on exit while in transition
            ignoring: secondaryIgnore,
            child: child,
          ),
        ),
      );

      return TurnableSlideTransition(
        enabled: entEnabled,
        position: Tween(begin: entBegin, end: entEnd).animate(CurvedAnimation(
            parent: animation, curve: entCurve, reverseCurve: entReverseCurve)),
        child: FadeTransition(
          opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
              reverseCurve: entReverseCurve),
          child: TurnableSlideTransition(
            enabled: exitEnabled,
            position: Tween(begin: exitBegin, end: exitEnd).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: exitCurve,
                reverseCurve: exitReverseCurve,
              ),
            ),
            child: materialWrappedChild,
          ),
        ),
      );
    };
  }
}
