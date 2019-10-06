import 'package:flutter/material.dart';

/// Creates cupertino-like route transition, where new route pushes old from right to left
class SlideStackRightRoute extends PageRouteBuilder {
  final Widget enterPage;
  final Widget exitPage;
  static var exBegin = Offset(0.0, 0.0);
  static var exEnd = Offset(-0.5, 0.0);
  static var entBegin = Offset(1.0, 0.0);
  static var entEnd = Offset.zero;
  static var curveIn = Curves.easeOutSine;
  static var curveOut = Curves.easeInSine;

  SlideStackRightRoute({@required this.exitPage, @required this.enterPage})
      : super(
          transitionDuration: Duration(milliseconds: 600),
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
              SlideTransition(
                position: Tween(begin: exBegin, end: exEnd)
                    .chain(CurveTween(curve: curveIn))
                    .chain(CurveTween(curve: curveOut))
                    .animate(animation),
                child: Container(
                    foregroundDecoration: BoxDecoration(
                      color: Colors.black.withOpacity(animation.value / 2),
                    ),
                    child: exitPage),
              ),
              SlideTransition(
                position: Tween(begin: entBegin, end: entEnd)
                    .chain(CurveTween(curve: curveIn))
                    .chain(CurveTween(curve: curveOut))
                    .animate(animation),
                child: enterPage,
              )
            ],
          ),
        );
}
