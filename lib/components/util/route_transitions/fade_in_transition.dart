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
class FadeInRouteTransition<T extends Widget> extends RouteTransition<T> {
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

  FadeInRouteTransition({
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
      handleChecks(animation, secondaryAnimation);
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
        color: Colors.black,
        child: FadeTransition(
          opacity: secondaryAnimation.status == AnimationStatus.forward
              // Dim route on exit
              ? exitDimTween.animate(
                  secondaryAnimation,
                )
              // Dim route on exit reverse, but less a little bit than on forward
              : secondaryAnimation.status == AnimationStatus.reverse
                  ? exitRevDimTween.animate(
                      secondaryAnimation,
                    )
                  // Do not dim in other cases
                  : constTween.animate(secondaryAnimation),
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
