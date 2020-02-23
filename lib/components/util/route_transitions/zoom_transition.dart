/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Flutter Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'route_transitions.dart';
import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Creates customizable fade in transition
///
/// By default acts pretty same as [ZoomPageTransitionsBuilder]
class RouteZoomTransition<T extends Widget> extends RouteTransition<T> {
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
  RoutePageBuilder pageBuilder;
  @override
  UIFunction checkSystemUi;
  @override
  BoolFunction shouldCheckSystemUiEnt;
  @override
  BoolFunction shouldCheckSystemUiExitRev;

  RouteZoomTransition({
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

      return _ZoomPageTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
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
    };
  }
}

// COPIED FROM FLUTTER FRAMEWORK
//
// Zooms and fades a new page in, zooming out the previous page. This transition
// is designed to match the Android 10 activity transition.
class _ZoomPageTransition extends StatefulWidget {
  const _ZoomPageTransition({
    Key key,
    this.animation,
    this.secondaryAnimation,
    this.child,
  }) : super(key: key);

  // The scrim obscures the old page by becoming increasingly opaque.
  static final Tween<double> _scrimOpacityTween = Tween<double>(
    begin: 0.0,
    end: 0.60,
  );

  // A curve sequence that is similar to the 'fastOutExtraSlowIn' curve used in
  // the native transition.
  static final List<TweenSequenceItem<double>>
      fastOutExtraSlowInTweenSequenceItems = <TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.0, end: 0.4)
          .chain(CurveTween(curve: const Cubic(0.05, 0.0, 0.133333, 0.06))),
      weight: 0.166666,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.4, end: 1.0)
          .chain(CurveTween(curve: const Cubic(0.208333, 0.82, 0.25, 1.0))),
      weight: 1.0 - 0.166666,
    ),
  ];
  static final TweenSequence<double> _scaleCurveSequence =
      TweenSequence<double>(fastOutExtraSlowInTweenSequenceItems);
  static final FlippedTweenSequence _flippedScaleCurveSequence =
      FlippedTweenSequence(fastOutExtraSlowInTweenSequenceItems);

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  __ZoomPageTransitionState createState() => __ZoomPageTransitionState();
}

class __ZoomPageTransitionState extends State<_ZoomPageTransition> {
  AnimationStatus _currentAnimationStatus;
  AnimationStatus _lastAnimationStatus;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener((AnimationStatus animationStatus) {
      _lastAnimationStatus = _currentAnimationStatus;
      _currentAnimationStatus = animationStatus;
    });
  }

  // This check ensures that the animation reverses the original animation if
  // the transition were interruped midway. This prevents a disjointed
  // experience since the reverse animation uses different fade and scaling
  // curves.
  bool get _transitionWasInterrupted {
    bool wasInProgress = false;
    bool isInProgress = false;

    switch (_currentAnimationStatus) {
      case AnimationStatus.completed:
      case AnimationStatus.dismissed:
        isInProgress = false;
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        isInProgress = true;
        break;
    }
    switch (_lastAnimationStatus) {
      case AnimationStatus.completed:
      case AnimationStatus.dismissed:
        wasInProgress = false;
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        wasInProgress = true;
        break;
    }
    return wasInProgress && isInProgress;
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> _forwardScrimOpacityAnimation = widget.animation
        .drive(_ZoomPageTransition._scrimOpacityTween
            .chain(CurveTween(curve: const Interval(0.2075, 0.4175))));

    final Animation<double> _forwardEndScreenScaleTransition = widget.animation
        .drive(Tween<double>(begin: 0.85, end: 1.00)
            .chain(_ZoomPageTransition._scaleCurveSequence));

    final Animation<double> _forwardStartScreenScaleTransition =
        widget.secondaryAnimation.drive(Tween<double>(begin: 1.00, end: 1.05)
            .chain(_ZoomPageTransition._scaleCurveSequence));

    final Animation<double> _forwardEndScreenFadeTransition = widget.animation
        .drive(Tween<double>(begin: 0.0, end: 1.00)
            .chain(CurveTween(curve: const Interval(0.125, 0.250))));

    final Animation<double> _reverseEndScreenScaleTransition =
        widget.secondaryAnimation.drive(Tween<double>(begin: 1.00, end: 1.10)
            .chain(_ZoomPageTransition._flippedScaleCurveSequence));

    final Animation<double> _reverseStartScreenScaleTransition =
        widget.animation.drive(Tween<double>(begin: 0.9, end: 1.0)
            .chain(_ZoomPageTransition._flippedScaleCurveSequence));

    final Animation<double> _reverseStartScreenFadeTransition = widget.animation
        .drive(Tween<double>(begin: 0.0, end: 1.00)
            .chain(CurveTween(curve: const Interval(1 - 0.2075, 1 - 0.0825))));

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (BuildContext context, Widget child) {
        if (widget.animation.status == AnimationStatus.forward ||
            _transitionWasInterrupted) {
          return Container(
            color:
                Colors.black.withOpacity(_forwardScrimOpacityAnimation.value),
            child: FadeTransition(
              opacity: _forwardEndScreenFadeTransition,
              child: ScaleTransition(
                scale: _forwardEndScreenScaleTransition,
                child: child,
              ),
            ),
          );
        } else if (widget.animation.status == AnimationStatus.reverse) {
          return ScaleTransition(
            scale: _reverseStartScreenScaleTransition,
            child: FadeTransition(
              opacity: _reverseStartScreenFadeTransition,
              child: child,
            ),
          );
        }
        return child;
      },
      child: AnimatedBuilder(
        animation: widget.secondaryAnimation,
        builder: (BuildContext context, Widget child) {
          if (widget.secondaryAnimation.status == AnimationStatus.forward ||
              _transitionWasInterrupted) {
            return ScaleTransition(
              scale: _forwardStartScreenScaleTransition,
              child: child,
            );
          } else if (widget.secondaryAnimation.status ==
              AnimationStatus.reverse) {
            return ScaleTransition(
              scale: _reverseEndScreenScaleTransition,
              child: child,
            );
          }
          return child;
        },
        child: widget.child,
      ),
    );
  }
}
