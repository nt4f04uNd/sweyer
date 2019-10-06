import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final Text text;
  final Axis direction;
  final Duration animationDuration, backDuration, pauseDuration;

  MarqueeWidget({
    Key key,
    @required this.text,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 3500),
    this.pauseDuration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  ScrollController scrollController = ScrollController();
  Duration animationDuration, backDuration, pauseDuration;

  @override
  void initState() {
    super.initState();
    scroll();

    if (widget.text.data.length >
        (widget.text.style.fontSize == 14 ? 75 : 50)) {
      // And respect font
      // Increase duration for when large string is provided
      animationDuration = widget.animationDuration +
          Duration(milliseconds: 100 * widget.text.data.length);
      backDuration = widget.animationDuration +
          Duration(milliseconds: 50 * widget.text.data.length);
    } else {
      animationDuration = widget.animationDuration;
      backDuration = widget.backDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: widget.text,
      ),
      scrollDirection: widget.direction,
      physics: const NeverScrollableScrollPhysics(),
      controller: scrollController,
    );
  }

  void scroll() async {
    while (true) {
      if (!this.mounted) break;
      await Future.delayed(widget.pauseDuration);

      if (!this.mounted) break;
      if (scrollController.hasClients)
        await scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: widget.animationDuration,
            curve: Curves.easeInOut);

      if (!this.mounted) break;
      await Future.delayed(widget.pauseDuration);

      if (!this.mounted) break;
      if (scrollController.hasClients)
        await scrollController.animateTo(0.0,
            duration: widget.backDuration, curve: Curves.easeInOut);
    }
  }
}
