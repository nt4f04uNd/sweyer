import 'dart:async';

import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  final Axis scrollAxis;

  final double ratioOfBlankToScreen;

  MarqueeWidget({
    @required this.text,
    this.textStyle,
    this.scrollAxis: Axis.horizontal,
    this.ratioOfBlankToScreen: 0.25,
  }) : assert(
          text != null,
        );

  @override
  State<StatefulWidget> createState() {
    return new MarqueeWidgetState();
  }
}

class MarqueeWidgetState extends State<MarqueeWidget>
    with SingleTickerProviderStateMixin {
  ScrollController scroController;
  double screenWidth;
  double screenHeight;
  double position = 0.0;
  Timer timer;
  final double _moveDistance = 3.0;
  final int _timerRest = 100;
  GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    scroController = new ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      startTimer();
    });
  }

  void startTimer() {
    var widgetWidth = _key.currentContext.findRenderObject().paintBounds.center;
    double widgetHeight =
        _key.currentContext.findRenderObject().paintBounds.size.height;

    timer = Timer.periodic(new Duration(milliseconds: _timerRest), (timer) {
      double maxScrollExtent = scroController.position.maxScrollExtent;
      double pixels = scroController.position.pixels;
      // debugPrint(
      //     '${pixels + _moveDistance}, ${maxScrollExtent + screenWidth / (widget.ratioOfBlankToScreen * 2)}');
      var textWidth = (maxScrollExtent - 100) / 3 * 2;
      // debugPrint(
      //     '${pixels.toString()},$textWidth, $widgetWidth, $maxScrollExtent');

      if (pixels >= textWidth) {
        position = 0;
        scroController.jumpTo(position);
      }
      position += _moveDistance;
      scroController.animateTo(position,
          duration: new Duration(milliseconds: _timerRest),
          curve: Curves.linear);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  Widget getBothEndsChild() {
    return Text(
      widget.text,
      style: widget.textStyle,
    );
  }

  Widget getCenterChild() {
    return SizedBox(width: 50);
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new SingleChildScrollView(
      scrollDirection: widget.scrollAxis,
      controller: scroController,
      physics: new NeverScrollableScrollPhysics(),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(
          widget.text,
          key: _key,
          style: widget.textStyle,
        ),
        getCenterChild(),
        getBothEndsChild(),
        getCenterChild(),
        getBothEndsChild(),
      ]),
    );
  }
}
