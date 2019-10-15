import 'package:flutter/material.dart';

/// Type for function that returns boolean
typedef BoolFunction = bool Function();

/// Returns `PageRouteBuilder` that performs slide to right animation
PageRouteBuilder<T> createRouteTransition<T extends Widget>({
  @required final T route,

  /// Function that checks whether to play enter animation or not
  ///
  /// E.G disable exit animation for main route
  BoolFunction checkEntAnimationEnabled,

  /// Function that checks whether to play exit animation or not
  ///
  /// E.G disable exit animation for particular route pushes
  BoolFunction checkExitAnimationEnabled,

  /// Begin offset for enter animation
  ///
  /// Defaults to `const Offset(1.0, 0.0)`
  final Offset entBegin: const Offset(1.0, 0.0),

  /// End offset for enter animation
  ///
  /// Defaults to `Offset.zero`
  final Offset entEnd = Offset.zero,

  /// Begin offset for exit animation
  ///
  /// Defaults to `Offset.zero`
  final Offset exitBegin: Offset.zero,

  /// End offset for exit animation
  ///
  /// Defaults to `const Offset(-0.3, 0.0)`
  final Offset exitEnd: const Offset(-0.3, 0.0),

  /// A curve for enter animation
  ///
  /// Defaults to `Curves.linearToEaseOut`
  final Curve entCurve: Curves.linearToEaseOut,

  /// A curve for reverse enter animation
  ///
  /// Defaults to `Curves.easeInToLinear`
  final Curve entReverseCurve: Curves.easeInToLinear,

  /// A curve for exit animation
  ///
  /// Defaults to `Curves.linearToEaseOut`
  final Curve exitCurve: Curves.linearToEaseOut,

  /// A curve for reverse exit animation
  ///
  /// Defaults to `Curves.easeInToLinear`
  final Curve exitReverseCurve: Curves.easeInToLinear,

  /// A duration of transition
  ///
  /// Defaults to `const Duration(milliseconds: 430)`
  final Duration transitionDuration: const Duration(milliseconds: 430),

  /// Field to pass `RouteSettings`
  final RouteSettings settings,

  ///Whether the route obscures previous routes when the transition is complete.
  ///
  /// When an opaque route's entrance transition is complete, the routes behind the opaque route will not be built to save resources.
  ///
  /// Copied from `TransitionRoute`.
  ///
  /// Defaults to true
  final bool opaque: true,

  /// Whether the route should remain in memory when it is inactive.
  ///
  /// If this is true, then the route is maintained, so that any futures it is holding from the next route will properly resolve when the next route pops. If this is not necessary, this can be set to false to allow the framework to entirely discard the route's widget hierarchy when it is not visible.
  ///
  /// The value of this getter should not change during the lifetime of the object. It is used by [createOverlayEntries], which is called by [install] near the beginning of the route lifecycle.
  ///
  /// Copied from `ModalRoute`.
  ///
  /// Defaults to false
  final bool maintainState: false,

  /// Whether to ignore touch events while enter animation
  ///
  /// Defaults to false
  final bool entIgnoreEvents: false,
}) {
  checkEntAnimationEnabled ??= () => true;
  checkExitAnimationEnabled ??= () => true;
  return PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: 500),
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
        bool entEnabled = checkEntAnimationEnabled();
        bool exitEnabled = checkExitAnimationEnabled();

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
                    Colors.black.withOpacity(
                        exitEnabled ? secondaryAnimation.value / 1.1 : 0),
              ),
              child: IgnorePointer(
                // Disable any touch events on fake exit route only while transitioning
                ignoring: entIgnoreEvents &&
                    (animation.status == AnimationStatus.forward ||
                        animation.status == AnimationStatus.reverse),
                child: child,
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
