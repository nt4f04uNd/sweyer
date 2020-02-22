/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*
*  Copyright (c) The Flutter Authors.
*  See ThirdPartyNotices.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// const Duration kSMMRouteTransitionDuration = const Duration(milliseconds: 650);
const Duration kSMMRouteTransitionDuration = const Duration(milliseconds: 550);

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

/// Type for function that returns boolean
typedef BoolFunction = bool Function();

/// Needed to define constant [_defBoolFunc]
bool _trueFunc() {
  return true;
}

/// Used as default bool function in [RouteTransition]
const BoolFunction _defBoolFunc = _trueFunc;

/// Type for function that returns [SystemUiOverlayStyle]
typedef UIFunction = SystemUiOverlayStyle Function();

/// Variants of material default upwards transition builder
///
/// Before P it was with fade
///
/// After P it became sort of expansion
enum MaterialRouteTransitionStyle {
  fade,
  expand,
}

/// [SlideTransition] class, but with `enabled` parameter
class TurnableSlideTransition extends SlideTransition {
  TurnableSlideTransition(
      {Key key,
      @required Animation<Offset> position,
      bool transformHitTests: true,
      TextDirection textDirection,
      Widget child,
      this.enabled: true})
      : super(
          key: key,
          position: position,
          transformHitTests: transformHitTests,
          textDirection: textDirection,
          child: child,
        );

  /// If false, animation won't be played
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      Offset offset = position.value;
      if (textDirection == TextDirection.rtl)
        offset = Offset(-offset.dx, offset.dy);
      return FractionalTranslation(
        translation: offset,
        transformHitTests: transformHitTests,
        child: child,
      );
    }
    return child;
  }
}

/// Abstract class to create various route transitions
abstract class RouteTransition<T extends Widget> extends PageRouteBuilder<T> {
  final T route;

  /// Function that checks whether to play enter animation or not
  ///
  /// E.G disable enter animation for main route
  BoolFunction checkEntAnimationEnabled;

  /// Function that checks whether to play exit animation or not
  ///
  /// E.G disable exit animation for particular route pushes
  BoolFunction checkExitAnimationEnabled;

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

  /// A curve for enter animation
  ///
  /// Defaults to [Curves.linearToEaseOut]
  final Curve entCurve;

  /// A curve for reverse enter animation
  ///
  /// Defaults to [Curves.easeInToLinear]
  final Curve entReverseCurve;

  /// A curve for exit animation
  ///
  /// Defaults to [Curves.linearToEaseOut]
  final Curve exitCurve;

  /// A curve for reverse exit animation
  ///
  /// Defaults to [Curves.easeInToLinear]
  final Curve exitReverseCurve;

  /// [SystemUiOverlayStyle] applied on route enter (when [animation])
  final UIFunction checkEnterSystemUI;

  /// [SystemUiOverlayStyle] applied on route exit (when [animation])
  final UIFunction checkExitSystemUI;

  /// Function, that returns [SystemUiOverlayStyle], that will be applied for a static route
  final UIFunction routeSystemUI;

  @override
  final Duration transitionDuration;

  @override
  final bool opaque;

  @override
  final bool maintainState;

  /// Whether to ignore touch events while enter forward animation
  ///
  /// Defaults to false
  final bool entIgnoreEventsForward;

  /// Whether to ignore touch events while exit forward animation
  ///
  /// Defaults to false
  final bool exitIgnoreEventsForward;

  /// Whether to ignore touch events while exit reverse animation
  ///
  /// Defaults to false
  final bool exitIgnoreEventsReverse;

  RouteTransition({
    this.route,
    this.checkEntAnimationEnabled = _defBoolFunc,
    this.checkExitAnimationEnabled = _defBoolFunc,
    this.entBegin = const Offset(1.0, 0.0),
    this.entEnd = Offset.zero,
    this.exitBegin = Offset.zero,
    this.exitEnd = const Offset(-0.2, 0.0),
    this.entCurve = Curves.linearToEaseOut,
    this.entReverseCurve = Curves.easeInToLinear,
    this.exitCurve = Curves.linearToEaseOut,
    this.exitReverseCurve = Curves.easeInToLinear,
    this.checkEnterSystemUI,
    this.checkExitSystemUI,
    this.routeSystemUI,
    this.transitionDuration = kSMMRouteTransitionDuration,
    RouteSettings settings,
    this.opaque = true,
    this.maintainState = false,
    this.entIgnoreEventsForward = false,
    this.exitIgnoreEventsForward = false,
    this.exitIgnoreEventsReverse = false,
  }) : super(
          settings: settings,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              route,
        );
}

/// Creates customizable stack route transition (basically, one route slides over another)
///
/// Slides from right to left by default
class RouteStackTransition<T extends Widget> extends RouteTransition<T> {
  @override
  final T route;
  @override
  BoolFunction checkEntAnimationEnabled;
  @override
  BoolFunction checkExitAnimationEnabled;
  @override
  final Offset entBegin;
  @override
  final Offset entEnd;
  @override
  final Offset exitBegin;
  @override
  final Offset exitEnd;
  @override
  final Curve entCurve;
  @override
  final Curve entReverseCurve;
  @override
  final Curve exitCurve;
  @override
  final Curve exitReverseCurve;
  @override
  final UIFunction checkEnterSystemUI;
  @override
  final UIFunction checkExitSystemUI;
  @override
  final UIFunction routeSystemUI;
  @override
  final Duration transitionDuration;
  @override
  final bool opaque;
  @override
  final bool maintainState;
  @override
  final bool entIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsReverse;
  @override
  RouteTransitionsBuilder transitionsBuilder;
  RouteStackTransition({
    this.route,
    this.checkEntAnimationEnabled = _defBoolFunc,
    this.checkExitAnimationEnabled = _defBoolFunc,
    this.entBegin = const Offset(1.0, 0.0),
    this.entEnd = Offset.zero,
    this.exitBegin = Offset.zero,
    this.exitEnd = const Offset(-0.2, 0.0),
    this.entCurve = Curves.linearToEaseOut,
    this.entReverseCurve = Curves.easeInToLinear,
    this.exitCurve = Curves.linearToEaseOut,
    this.exitReverseCurve = Curves.easeInToLinear,
    this.checkEnterSystemUI,
    this.checkExitSystemUI,
    this.routeSystemUI,
    this.transitionDuration = kSMMRouteTransitionDuration,
    RouteSettings settings,
    this.opaque = true,
    this.maintainState = false,
    this.entIgnoreEventsForward = false,
    this.exitIgnoreEventsForward = false,
    this.exitIgnoreEventsReverse = false,
  }) : super(
          route: route,
        ) {
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

      return TurnableSlideTransition(
        enabled: entEnabled,
        position: Tween(begin: entBegin, end: entEnd).animate(CurvedAnimation(
            parent: animation, curve: entCurve, reverseCurve: entReverseCurve)),
        child: TurnableSlideTransition(
          enabled: exitEnabled,
          position: Tween(begin: exitBegin, end: exitEnd).animate(
              CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: exitCurve,
                  reverseCurve: exitReverseCurve)),
          child: Container(
            foregroundDecoration: BoxDecoration(
              color: // Dim exit page from 0 to 0.9
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
                child: checkEnterSystemUI != null &&
                        (animation.status == AnimationStatus.forward)
                    ? AnnotatedRegion<SystemUiOverlayStyle>(
                        value: checkEnterSystemUI(),
                        child: child,
                      )
                    : checkExitSystemUI != null &&
                            (animation.status == AnimationStatus.reverse)
                        ? AnnotatedRegion<SystemUiOverlayStyle>(
                            value: checkExitSystemUI(),
                            child: child,
                          )
                        : routeSystemUI != null
                            ? AnnotatedRegion<SystemUiOverlayStyle>(
                                value: routeSystemUI(),
                                child: child,
                              )
                            : child,
              ),
            ),
          ),
        ),
      );
    };
  }
}

/// Creates customizable expand up route transition
///
/// By default acts pretty same as [OpenUpwardsPageTransitionsBuilder] - creates upwards expand in transition
class RouteExpandUpwardsTransition<T extends Widget>
    extends RouteTransition<T> {
  @override
  final T route;
  @override
  BoolFunction checkEntAnimationEnabled;
  @override
  BoolFunction checkExitAnimationEnabled;
  @override
  final Offset entBegin;
  @override
  final Offset entEnd;
  @override
  final Offset exitBegin;
  @override
  final Offset exitEnd;
  @override
  final Curve entCurve;
  @override
  final Curve entReverseCurve;
  @override
  final Curve exitCurve;
  @override
  final Curve exitReverseCurve;
  @override
  final UIFunction checkEnterSystemUI;
  @override
  final UIFunction checkExitSystemUI;
  @override
  final UIFunction routeSystemUI;
  @override
  final Duration transitionDuration;
  @override
  final bool opaque;
  @override
  final bool maintainState;
  @override
  final bool entIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsReverse;
  @override
  RouteTransitionsBuilder transitionsBuilder;

  /// If true, default material exit animation will be played
  final bool playMaterialExit;
  RouteExpandUpwardsTransition({
    this.route,
    this.checkEntAnimationEnabled = _defBoolFunc,
    this.checkExitAnimationEnabled = _defBoolFunc,
    this.entBegin = const Offset(1.0, 0.0),
    this.entEnd = Offset.zero,
    this.exitBegin = Offset.zero,
    this.exitEnd = const Offset(-0.2, 0.0),
    this.entCurve = Curves.linearToEaseOut,
    this.entReverseCurve = Curves.easeInToLinear,
    this.exitCurve = Curves.linearToEaseOut,
    this.exitReverseCurve = Curves.easeInToLinear,
    this.checkEnterSystemUI,
    this.checkExitSystemUI,
    this.routeSystemUI,
    this.transitionDuration = kSMMRouteTransitionDuration,
    RouteSettings settings,
    this.opaque = true,
    this.maintainState = false,
    this.entIgnoreEventsForward = false,
    this.exitIgnoreEventsForward = false,
    this.exitIgnoreEventsReverse = false,
    this.playMaterialExit = false,
  }) : super(
          route: route,
        ) {
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
            child: checkEnterSystemUI != null &&
                    (animation.status == AnimationStatus.forward ||
                        animation.status == AnimationStatus.completed)
                ? AnnotatedRegion<SystemUiOverlayStyle>(
                    value: checkEnterSystemUI(),
                    child: child,
                  )
                : checkExitSystemUI != null &&
                        (animation.status == AnimationStatus.reverse ||
                            animation.status == AnimationStatus.completed)
                    ? AnnotatedRegion<SystemUiOverlayStyle>(
                        value: checkExitSystemUI(),
                        child: child,
                      )
                    : routeSystemUI != null
                        ? AnnotatedRegion<SystemUiOverlayStyle>(
                            value: routeSystemUI(),
                            child: child,
                          )
                        : child,
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

/// Creates customizable fade in transition
///
/// By default acts pretty same as [FadeUpwardsPageTransitionsBuilder] - creates upwards fade in transition
class RouteFadeInTransition<T extends Widget> extends RouteTransition<T> {
  @override
  final T route;
  @override
  BoolFunction checkEntAnimationEnabled;
  @override
  BoolFunction checkExitAnimationEnabled;
  @override
  final Offset entBegin;
  @override
  final Offset entEnd;
  @override
  final Offset exitBegin;
  @override
  final Offset exitEnd;
  @override
  final Curve entCurve;
  @override
  final Curve entReverseCurve;
  @override
  final Curve exitCurve;
  @override
  final Curve exitReverseCurve;
  @override
  final UIFunction checkEnterSystemUI;
  @override
  final UIFunction checkExitSystemUI;
  @override
  final UIFunction routeSystemUI;
  @override
  final Duration transitionDuration;
  @override
  final bool opaque;
  @override
  final bool maintainState;
  @override
  final bool entIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsReverse;
  @override
  RouteTransitionsBuilder transitionsBuilder;
  RouteFadeInTransition({
    this.route,
    this.checkEntAnimationEnabled = _defBoolFunc,
    this.checkExitAnimationEnabled = _defBoolFunc,
    this.entBegin = const Offset(1.0, 0.0),
    this.entEnd = Offset.zero,
    this.exitBegin = Offset.zero,
    this.exitEnd = const Offset(-0.2, 0.0),
    this.entCurve = Curves.linearToEaseOut,
    this.entReverseCurve = Curves.easeInToLinear,
    this.exitCurve = Curves.linearToEaseOut,
    this.exitReverseCurve = Curves.easeInToLinear,
    this.checkEnterSystemUI,
    this.checkExitSystemUI,
    this.routeSystemUI,
    this.transitionDuration = kSMMRouteTransitionDuration,
    RouteSettings settings,
    this.opaque = true,
    this.maintainState = false,
    this.entIgnoreEventsForward = false,
    this.exitIgnoreEventsForward = false,
    this.exitIgnoreEventsReverse = false,
  }) : super(
          route: route,
        ) {
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
            child: checkEnterSystemUI != null &&
                    (animation.status == AnimationStatus.forward ||
                        animation.status == AnimationStatus.completed)
                ? AnnotatedRegion<SystemUiOverlayStyle>(
                    value: checkEnterSystemUI(),
                    child: child,
                  )
                : checkExitSystemUI != null &&
                        (animation.status == AnimationStatus.reverse ||
                            animation.status == AnimationStatus.completed)
                    ? AnnotatedRegion<SystemUiOverlayStyle>(
                        value: checkExitSystemUI(),
                        child: child,
                      )
                    : routeSystemUI != null
                        ? AnnotatedRegion<SystemUiOverlayStyle>(
                            value: routeSystemUI(),
                            child: child,
                          )
                        : child,
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

/// Creates customizable fade in transition
///
/// By default acts pretty same as [ZoomPageTransitionsBuilder]
class RouteZoomTransition<T extends Widget> extends RouteTransition<T> {
  @override
  final T route;
  @override
  BoolFunction checkEntAnimationEnabled;
  @override
  BoolFunction checkExitAnimationEnabled;
  @override
  final Offset entBegin;
  @override
  final Offset entEnd;
  @override
  final Offset exitBegin;
  @override
  final Offset exitEnd;
  @override
  final Curve entCurve;
  @override
  final Curve entReverseCurve;
  @override
  final Curve exitCurve;
  @override
  final Curve exitReverseCurve;
  @override
  final UIFunction checkEnterSystemUI;
  @override
  final UIFunction checkExitSystemUI;
  @override
  final UIFunction routeSystemUI;
  @override
  final Duration transitionDuration;
  @override
  final bool opaque;
  @override
  final bool maintainState;
  @override
  final bool entIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsForward;
  @override
  final bool exitIgnoreEventsReverse;
  @override
  RouteTransitionsBuilder transitionsBuilder;
  RouteZoomTransition({
    this.route,
    this.checkEntAnimationEnabled = _defBoolFunc,
    this.checkExitAnimationEnabled = _defBoolFunc,
    this.entBegin = const Offset(1.0, 0.0),
    this.entEnd = Offset.zero,
    this.exitBegin = Offset.zero,
    this.exitEnd = const Offset(-0.2, 0.0),
    this.entCurve = Curves.linearToEaseOut,
    this.entReverseCurve = Curves.easeInToLinear,
    this.exitCurve = Curves.linearToEaseOut,
    this.exitReverseCurve = Curves.easeInToLinear,
    this.checkEnterSystemUI,
    this.checkExitSystemUI,
    this.routeSystemUI,
    this.transitionDuration = kSMMRouteTransitionDuration,
    RouteSettings settings,
    this.opaque = true,
    this.maintainState = false,
    this.entIgnoreEventsForward = false,
    this.exitIgnoreEventsForward = false,
    this.exitIgnoreEventsReverse = false,
  }) : super(
          route: route,
        ) {
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
            child: checkEnterSystemUI != null &&
                    (animation.status == AnimationStatus.forward ||
                        animation.status == AnimationStatus.completed)
                ? AnnotatedRegion<SystemUiOverlayStyle>(
                    value: checkEnterSystemUI(),
                    child: child,
                  )
                : checkExitSystemUI != null &&
                        (animation.status == AnimationStatus.reverse ||
                            animation.status == AnimationStatus.completed)
                    ? AnnotatedRegion<SystemUiOverlayStyle>(
                        value: checkExitSystemUI(),
                        child: child,
                      )
                    : routeSystemUI != null
                        ? AnnotatedRegion<SystemUiOverlayStyle>(
                            value: routeSystemUI(),
                            child: child,
                          )
                        : child,
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
