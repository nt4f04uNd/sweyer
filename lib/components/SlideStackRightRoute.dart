import 'package:flutter/material.dart';

/// Creates cupertino-like route transition, where new route pushes old from right to left
class SlideStackRightRoute extends PageRouteBuilder {
  final Widget enterPage;
  final Widget exitPage;
  static var exBegin = Offset(0.0, 0.0);
  static var exEnd = Offset(-0.3, 0.0);
  static var entBegin = Offset(1.0, 0.0);
  static var entEnd = Offset.zero;
  // static var curveIn = Curves.linearToEaseOut;
  // static var curveOut = Curves.easeInToLinear;
  // static var curveIn = Curves.linear;
  // static var curveOut = Curves.linear;
  static var curveIn = Curves.easeInToLinear;
  static var curveOut = Curves.linearToEaseOut;

  SlideStackRightRoute({@required this.exitPage, @required this.enterPage})
      : super(
          transitionDuration: Duration(milliseconds: 400),
          maintainState: true,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              enterPage,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              Stack(
            children: <Widget>[
              // SlideTransition(
              //   position: Tween(begin: exBegin, end: exEnd)
              //       .chain(CurveTween(curve: curveIn))
              //       .chain(CurveTween(curve: curveOut))
              //       .animate(animation),
              //   child: Container(
              //     foregroundDecoration: BoxDecoration(
              //       color: Colors.black.withOpacity(animation.value / 1.1),
              //     ),
              //     child: IgnorePointer(
              //       // Disable any touch events on fake exit route
              //       ignoring: true,
              //       child: exitPage,
              //     ),
              //   ),
              // ),
              SlideTransition(
                position: Tween(begin: entBegin, end: entEnd)
                    .chain(CurveTween(curve: curveIn))
                    .chain(CurveTween(curve: curveOut))
                    .animate(animation),
                child: IgnorePointer(
                  // Disable any touch events on fake exit route only while transitioning
                  ignoring: animation.status != AnimationStatus.completed,
                  child: enterPage,
                ),
              )
            ],
          ),
        );
}
