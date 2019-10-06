import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final Text text;
  final Axis direction;
  Duration animationDuration, backDuration, pauseDuration;

  MarqueeWidget({
    Key key,
    @required this.text,
    this.direction = Axis.horizontal,
    Duration animationDuration = const Duration(milliseconds: 6000),
    Duration backDuration = const Duration(milliseconds: 3500),
    this.pauseDuration = const Duration(milliseconds: 2000),
  }) : super(key: key) {
    if (text.data.length > (text.style.fontSize == 14 ? 75 : 50)) {
      // And respect font
      // Increase duration for when large string is provided
      this.animationDuration =
          animationDuration + Duration(milliseconds: 100 * text.data.length);
      this.backDuration =
          animationDuration + Duration(milliseconds: 50 * text.data.length);
    } else {
      this.animationDuration = animationDuration;
      this.backDuration = backDuration;
    }
  }

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    scroll();
    super.initState();
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
