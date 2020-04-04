/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'route_transitions.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Creates customizable stack route transition with fade, very similar to Telegram app
class StackFadeRouteTransition<T extends Widget> extends RouteTransition<T> {
  @override
  final T route;
  @override
  final Constants.Routes routeType;
  @override
  BoolFunction checkEntAnimationEnabled;
  @override
  final Curve entCurve;
  @override
  final Curve entReverseCurve;
  @override
  final bool entIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsReverse;
  @override
  UIFunction checkSystemUi;

  StackFadeRouteTransition({
    @required this.route,
    this.routeType = Constants.Routes.main,
    this.checkEntAnimationEnabled = defBoolFunc,
    this.entCurve = Curves.easeOutCubic,
    this.entReverseCurve = Curves.easeInCubic,
    this.entIgnoreEventsForward = false,
    this.exitIgnoreEventsForward = false,
    this.exitIgnoreEventsReverse = false,
    this.checkSystemUi,
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
      handleChecks(animation, secondaryAnimation);
      return route;
    };
    transitionsBuilder = (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final slideAnimation = animation.status == AnimationStatus.forward
          // Move in on enter
          ? Tween<Offset>(begin: const Offset(0.16, 0.0), end: Offset.zero)
              .animate(
              CurvedAnimation(
                parent: animation,
                curve: entCurve,
              ),
            )
          // Move out on enter reverse
          : animation.status == AnimationStatus.reverse
              ? Tween(begin: const Offset(0.2, 0.0), end: Offset.zero).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: entCurve,
                    reverseCurve: entReverseCurve,
                  ),
                )
              // Stand still in other cases
              : Tween(begin: Offset.zero, end: Offset.zero).animate(animation);

      final fadeAnimation = animation.status == AnimationStatus.forward
          // Fade in on enter
          ? Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                  curve: Interval(
                    0.0,
                    0.7,
                    curve: Curves.ease,
                  ),
                  parent: animation),
            )
          // Fade out on exit
          : animation.status == AnimationStatus.reverse
              ? Tween<double>(begin: -0.5, end: 1.0).animate(animation)
              // Do not fade in other cases
              : constTween.animate(animation);

      return TurnableSlideTransition(
        enabled: entAnimationEnabled,
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: IgnorePointer(
            // Disable any touch events on enter while in transition
            ignoring: ignore,
            child: IgnorePointer(
              // Disable any touch events on exit while in transition
              ignoring: secondaryIgnore,
              child: child,
            ),
          ),
        ),
      );
    };
  }
}
