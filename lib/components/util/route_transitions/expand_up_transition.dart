/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'route_transitions.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

// Used by all of the transition animations.
const Curve _transitionCurve = Cubic(0.20, 0.00, 0.00, 1.00);

// The new page slides upwards just a little as its clip
// rectangle exposes the page from bottom to top.
final Tween<Offset> _primaryTranslationTween = Tween<Offset>(
  begin: const Offset(0.0, 0.05),
  end: Offset.zero,
);

// The old page slides upwards a little as the new page appears.
final Tween<Offset> _secondaryTranslationTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(0.0, -0.025),
);

// The scrim obscures the old page by becoming increasingly opaque.
final Tween<double> _scrimOpacityTween = Tween<double>(
  begin: 0.0,
  end: 0.25,
);

/// Creates customizable expand up route transition
///
/// By default acts pretty same as [OpenUpwardsPageTransitionsBuilder] - creates upwards expand in transition
class ExpandUpRouteTransition<T extends Widget>
    extends RouteTransition<T> {
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
  UIFunction checkSystemUi;
  @override
  BoolFunction shouldCheckSystemUiEnt;
  @override
  BoolFunction shouldCheckSystemUiExitRev;

  /// Begin offset for exit animation
  ///
  /// Defaults to [Offset.zero]
  final Offset exitBegin;

  /// End offset for exit animation
  ///
  /// Defaults to [const Offset(-0.3, 0.0)]
  final Offset exitEnd;

  /// If true, default material exit animation will be played
  final bool playMaterialExit;

  ExpandUpRouteTransition({
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
    this.exitBegin = Offset.zero,
    this.exitEnd = const Offset(-0.2, 0.0),
    Duration transitionDuration = kSMMRouteTransitionDuration,
    RouteSettings settings,
    bool opaque = true,
    bool maintainState = false,
    this.playMaterialExit = false,
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

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = constraints.biggest;

          final CurvedAnimation primaryAnimation = CurvedAnimation(
            parent: animation,
            curve: _transitionCurve,
            reverseCurve: _transitionCurve.flipped,
          );

          // Gradually expose the new page from bottom to top.
          final Animation<double> clipAnimation = Tween<double>(
            begin: 0.0,
            end: size.height,
          ).animate(primaryAnimation);

          final Animation<double> opacityAnimation =
              _scrimOpacityTween.animate(primaryAnimation);
          final Animation<Offset> primaryTranslationAnimation =
              _primaryTranslationTween.animate(primaryAnimation);

          final Animation<Offset> secondaryTranslationAnimation =
              _secondaryTranslationTween.animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: _transitionCurve,
              reverseCurve: _transitionCurve.flipped,
            ),
          );

          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget child) {
              return Container(
                color: Colors.black.withOpacity(opacityAnimation.value),
                alignment: Alignment.bottomLeft,
                child: ClipRect(
                  child: SizedBox(
                    height: clipAnimation.value,
                    child: OverflowBox(
                      alignment: Alignment.bottomLeft,
                      maxHeight: size.height,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: playMaterialExit
                ? AnimatedBuilder(
                    animation: secondaryAnimation,
                    child: FractionalTranslation(
                      translation: primaryTranslationAnimation.value,
                      child: child,
                    ),
                    builder: (BuildContext context, Widget child) {
                      return FractionalTranslation(
                        translation: secondaryTranslationAnimation.value,
                        child: materialWrappedChild,
                      );
                    },
                  )
                : TurnableSlideTransition(
                    enabled: exitEnabled,
                    position: Tween(begin: exitBegin, end: exitEnd).animate(
                        CurvedAnimation(
                            parent: secondaryAnimation,
                            curve: exitCurve,
                            reverseCurve: exitReverseCurve)),
                    child: materialWrappedChild,
                  ),
          );
        },
      );
    };
  }
}
