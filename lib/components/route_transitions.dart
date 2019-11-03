import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Type for function that returns boolean
typedef BoolFunction = bool Function();

/// Type for function that returns `SystemUiOverlayStyle`
typedef UIFunction = SystemUiOverlayStyle Function();

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

  /// `SystemUiOverlayStyle` applied on route enter (when `animation`)
  final SystemUiOverlayStyle enterSystemUI,

  /// `SystemUiOverlayStyle` applied on route exit (when `animation`)
  final UIFunction exitSystemUI,

  /// Function, that returns `SystemUiOverlayStyle`, that will be applied for a static route
  final UIFunction routeSystemUI,

  /// A duration of transition
  ///
  /// Defaults to `const Duration(milliseconds: 430)`
  final Duration transitionDuration: const Duration(milliseconds: 500),

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

  /// Whether to ignore touch events while enter forward animation
  ///
  /// Defaults to false
  final bool entIgnoreEventsForward: false,

  /// Whether to ignore touch events while exit forward animation
  ///
  /// Defaults to false
  final bool exitIgnoreEventsForward: false,

  /// Whether to ignore touch events while exit reverse animation
  ///
  /// Defaults to false
  final bool exitIgnoreEventsReverse: false,

  /// If true, default material animation will be played
  final bool playMaterial: false,
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
                
        if (playMaterial)
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
                        reverseCurve: exitReverseCurve)),
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    color: // Dim exit page from 0 to 0.9
                        Colors.black.withOpacity(
                            exitEnabled ? secondaryAnimation.value / 1.1 : 0),
                  ),
                  child: IgnorePointer(
                    // Disable any touch events on enter while in transition
                    ignoring: ignore,
                    child: IgnorePointer(
                      // Disable any touch events on exit while in transition
                      ignoring: secondaryIgnore,
                      child: enterSystemUI != null &&
                              (animation.status == AnimationStatus.forward ||
                                  animation.status == AnimationStatus.completed)
                          ? AnnotatedRegion<SystemUiOverlayStyle>(
                              value: enterSystemUI, child: child)
                          : exitSystemUI != null &&
                                  (animation.status ==
                                          AnimationStatus.reverse ||
                                      animation.status ==
                                          AnimationStatus.completed)
                              ? AnnotatedRegion<SystemUiOverlayStyle>(
                                  value: exitSystemUI(), child: child)
                              : routeSystemUI != null
                                  ? AnnotatedRegion<SystemUiOverlayStyle>(
                                      value: routeSystemUI(), child: child)
                                  : child,
                    ),
                  ),
                ),
              ),
            ),
          );

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
                // Disable any touch events on enter while in transition
                ignoring: ignore,
                child: IgnorePointer(
                  // Disable any touch events on exit while in transition
                  ignoring: secondaryIgnore,
                  child: enterSystemUI != null &&
                          (animation.status == AnimationStatus.forward)
                      ? AnnotatedRegion<SystemUiOverlayStyle>(
                          value: enterSystemUI, child: child)
                      : exitSystemUI != null &&
                              (animation.status == AnimationStatus.reverse)
                          ? AnnotatedRegion<SystemUiOverlayStyle>(
                              value: exitSystemUI(), child: child)
                          : routeSystemUI != null
                              ? AnnotatedRegion<SystemUiOverlayStyle>(
                                  value: routeSystemUI(), child: child)
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

// // Slides the page upwards and fades it in, starting from 1/4 screen
// // below the top.
// class _FadeUpwardsPageTransition extends StatelessWidget {
//   _FadeUpwardsPageTransition({
//     Key key,
//     @required
//         Animation<double>
//             routeAnimation, // The route's linear 0.0 - 1.0 animation.
//     @required this.child,
//   })  : _positionAnimation =
//             routeAnimation.drive(_bottomUpTween.chain(_fastOutSlowInTween)),
//         _opacityAnimation = routeAnimation.drive(_easeInTween),
//         super(key: key);

//   // Fractional offset from 1/4 screen below the top to fully on screen.
//   static final Tween<Offset> _bottomUpTween = Tween<Offset>(
//     begin: const Offset(0.0, 0.25),
//     end: Offset.zero,
//   );
//   static final Animatable<double> _fastOutSlowInTween =
//       CurveTween(curve: Curves.fastOutSlowIn);
//   static final Animatable<double> _easeInTween =
//       CurveTween(curve: Curves.easeIn);

//   final Animation<Offset> _positionAnimation;
//   final Animation<double> _opacityAnimation;
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return SlideTransition(
//       position: _positionAnimation,
//       // TODO(ianh): tell the transform to be un-transformed for hit testing
//       child: FadeTransition(
//         opacity: _opacityAnimation,
//         child: child,
//       ),
//     );
//   }
// }

/// A modal route that replaces the entire screen with a platform-adaptive
/// transition.
///
/// For Android, the entrance transition for the page slides the page upwards
/// and fades it in. The exit transition is the same, but in reverse.
///
/// The transition is adaptive to the platform and on iOS, the page slides in
/// from the right and exits in reverse. The page also shifts to the left in
/// parallax when another page enters to cover it. (These directions are flipped
/// in environments with a right-to-left reading direction.)
///
/// By default, when a modal route is replaced by another, the previous route
/// remains in memory. To free all the resources when this is not necessary, set
/// [maintainState] to false.
///
/// The `fullscreenDialog` property specifies whether the incoming page is a
/// fullscreen modal dialog. On iOS, those pages animate from the bottom to the
/// top rather than horizontally.
///
/// The type `T` specifies the return type of the route which can be supplied as
/// the route is popped from the stack via [Navigator.pop] by providing the
/// optional `result` argument.
///
/// See also:
///
///  * [PageTransitionsTheme], which defines the default page transitions used
///    by [MaterialPageRoute.buildTransitions].
class CustomMaterialPageRoute<T> extends PageRoute<T> {
  /// Construct a MaterialPageRoute whose contents are defined by [builder].
  ///
  /// The values of [builder], [maintainState], and [fullScreenDialog] must not
  /// be null.
  CustomMaterialPageRoute({
    @required this.builder,
    RouteSettings settings,
    this.maintainState = true,
    bool fullscreenDialog = false,
  })  : assert(builder != null),
        assert(maintainState != null),
        assert(fullscreenDialog != null),
        assert(opaque),
        super(settings: settings, fullscreenDialog: fullscreenDialog);

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is MaterialPageRoute ||
        previousRoute is CupertinoPageRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialPageRoute && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoPageRoute && !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = builder(context);
    assert(() {
      if (result == null) {
        throw FlutterError(
            'The builder for route "${settings.name}" returned null.\n'
            'Route builders must never return null.');
      }
      return true;
    }());
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;
    return theme.buildTransitions<T>(
        this, context, animation, secondaryAnimation, child);
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
