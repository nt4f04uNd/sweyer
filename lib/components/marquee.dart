import 'package:flutter/material.dart';

/// Creates marque widget that scrolls text back and forward to see it all
class MarqueeWidget extends StatefulWidget {
  const MarqueeWidget({
    Key key,
    @required this.text,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 3500),
    this.pauseDuration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  final Text text;

  /// Scroll vertically or horizontally
  ///
  /// @default `Axis.horizontal`
  final Axis direction;

  /// Duration of back slide animation
  ///
  /// @default `const Duration(milliseconds: 6000)`
  final Duration animationDuration;

  /// Duration of back slide animation
  ///
  /// @default `const Duration(milliseconds: 3500)`
  final Duration backDuration;

  /// Duration of pause between changing slide direction
  ///
  /// @default `const Duration(milliseconds: 2000)`
  final Duration pauseDuration;

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  ScrollController _scrollController = ScrollController();
  Duration _animationDuration, _backDuration;

  @override
  void initState() {
    super.initState();

    if (widget.text.data.length >
        (widget.text.style.fontSize <= 14 ? 75 : 50)) {
      // And respect font
      // Increase duration for when large string is provided
      _animationDuration = widget.animationDuration +
          Duration(milliseconds: 100 * widget.text.data.length);
      _backDuration = widget.animationDuration +
          Duration(milliseconds: 50 * widget.text.data.length);
    } else {
      _animationDuration = widget.animationDuration;
      _backDuration = widget.backDuration;
    }

    scroll();
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
      controller: _scrollController,
    );
  }

  void scroll() async {
    while (true) {
      if (!this.mounted) break;
      await Future.delayed(widget.pauseDuration);

      if (!this.mounted) break;
      if (_scrollController.hasClients)
        await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: _animationDuration,
            curve: Curves.easeInOut);

      if (!this.mounted) break;
      await Future.delayed(widget.pauseDuration);

      if (!this.mounted) break;
      if (_scrollController.hasClients)
        await _scrollController.animateTo(0.0,
            duration: _backDuration, curve: Curves.easeInOut);
    }
  }
}
