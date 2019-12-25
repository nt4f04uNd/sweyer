/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Type for function that returns `SystemUiOverlayStyle`
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

/// Returns `PageRouteBuilder` that performs slide to right animation
PageRouteBuilder<T> createRouteTransition<T extends Widget>({
  @required final T route,

  /// Function that checks whether to play enter animation or not
  ///
  /// E.G disable enter animation for main route
  BoolFunction checkEntAnimationEnabled,

  /// Function that checks whether to play exit animation or not
  ///
  /// E.G disable exit animation for particular route pushes
  BoolFunction checkExitAnimationEnabled,

  /// Begin offset for enter animation
  ///
  /// Defaults to `const Offset(1.0, 0.0)`
  final Offset entBegin = const Offset(1.0, 0.0),

  /// End offset for enter animation
  ///
  /// Defaults to `Offset.zero`
  final Offset entEnd = Offset.zero,

  /// Begin offset for exit animation
  ///
  /// Defaults to `Offset.zero`
  final Offset exitBegin = Offset.zero,

  /// End offset for exit animation
  ///
  /// Defaults to `const Offset(-0.3, 0.0)`
  final Offset exitEnd = const Offset(-0.2, 0.0),

  /// A curve for enter animation
  ///
  /// Defaults to `Curves.linearToEaseOut`
  final Curve entCurve = Curves.linearToEaseOut,

  /// A curve for reverse enter animation
  ///
  /// Defaults to `Curves.easeInToLinear`
  final Curve entReverseCurve = Curves.easeInToLinear,

  /// A curve for exit animation
  ///
  /// Defaults to `Curves.linearToEaseOut`
  final Curve exitCurve = Curves.linearToEaseOut,

  /// A curve for reverse exit animation
  ///
  /// Defaults to `Curves.easeInToLinear`
  final Curve exitReverseCurve = Curves.easeInToLinear,

  /// `SystemUiOverlayStyle` applied on route enter (when `animation`)
  final UIFunction checkEnterSystemUI,

  /// `SystemUiOverlayStyle` applied on route exit (when `animation`)
  final UIFunction checkExitSystemUI,

  /// Function, that returns `SystemUiOverlayStyle`, that will be applied for a static route
  final UIFunction routeSystemUI,

  /// A duration of transition
  ///
  /// Defaults to `const Duration(milliseconds: 400)`
  // final Duration transitionDuration = const Duration(milliseconds: 400),
  final Duration transitionDuration = const Duration(milliseconds: 700),

  /// Field to pass `RouteSettings`
  final RouteSettings settings,

  ///Whether the route obscures previous routes when the transition is complete.
  ///
  /// When an opaque route's entrance transition is complete, the routes behind the opaque route will not be built to save resources.
  ///
  /// Copied from `TransitionRoute`.
  ///
  /// Defaults to true
  final bool opaque = true,

  /// Whether the route should remain in memory when it is inactive.
  ///
  /// If this is true, then the route is maintained, so that any futures it is holding from the next route will properly resolve when the next route pops. If this is not necessary, this can be set to false to allow the framework to entirely discard the route's widget hierarchy when it is not visible.
  ///
  /// The value of this getter should not change during the lifetime of the object. It is used by [createOverlayEntries], which is called by [install] near the beginning of the route lifecycle.
  ///
  /// Copied from `ModalRoute`.
  ///
  /// Defaults to false
  final bool maintainState = false,

  /// Whether to ignore touch events while enter forward animation
  ///
  /// Defaults to false
  final bool entIgnoreEventsForward = false,

  /// Whether to ignore touch events while exit forward animation
  ///
  /// Defaults to false
  final bool exitIgnoreEventsForward = false,

  /// Whether to ignore touch events while exit reverse animation
  ///
  /// Defaults to false
  final bool exitIgnoreEventsReverse = false,

  /// If true, default material animation will be played
  final bool playMaterial = false,

  /// If true, default material exit animation will be played (only for `expand` variant)
  final bool playMaterialExit = false,

  /// Animation style
  ///
  /// See here https://flutter.dev/docs/resources/platform-adaptations
  final MaterialRouteTransitionStyle materialAnimationStyle =
      MaterialRouteTransitionStyle.fade,
}) {
  checkEntAnimationEnabled ??= () => true;
  checkExitAnimationEnabled ??= () => true;
  return PageRouteBuilder<T>(
      transitionDuration: transitionDuration,
      settings: settings,
      opaque: opaque,
      maintainState: maintainState,
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) =>
          route,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final bool entEnabled = checkEntAnimationEnabled();
        final bool exitEnabled = checkExitAnimationEnabled();

        final bool ignore = entIgnoreEventsForward &&
            animation.status == AnimationStatus.forward;
        final bool secondaryIgnore = exitIgnoreEventsForward &&
                secondaryAnimation.status == AnimationStatus.forward ||
            exitIgnoreEventsReverse &&
                secondaryAnimation.status == AnimationStatus.reverse;

        if (playMaterial) {
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

          if (materialAnimationStyle == MaterialRouteTransitionStyle.fade)
            return TurnableSlideTransition(
              enabled: entEnabled,
              position: Tween(begin: entBegin, end: entEnd).animate(
                  CurvedAnimation(
                      parent: animation,
                      curve: entCurve,
                      reverseCurve: entReverseCurve)),
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
        }

        return TurnableSlideTransition(
          enabled: entEnabled,
          position: Tween(begin: entBegin, end: entEnd).animate(CurvedAnimation(
              parent: animation,
              curve: entCurve,
              reverseCurve: entReverseCurve)),
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
      });
}

/// `SlideTransition` class, but with `enabled` parameter
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
